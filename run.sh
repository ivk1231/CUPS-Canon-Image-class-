#!/usr/bin/with-contenv bashio

# ==============================================================================
# Canon CUPS Driver Add-on Startup Script
# ==============================================================================

bashio::log.info "Starting Canon CUPS Driver Add-on..."

# 1. Verify the Canon driver is installed
if dpkg -l | grep -q cnrdrvcups; then
    bashio::log.info "Canon UFR II driver detected."
else
    bashio::log.error "Canon UFR II driver NOT detected! Exiting."
    exit 1
fi

# 2. Set up persistent spool directory
bashio::log.info "Setting up persistent spool directory..."
if [ ! -d /config/cups/spool ]; then
    mkdir -p /config/cups/spool
    chmod 755 /config/cups/spool
    chown root:lp /config/cups/spool
fi

if [ -d /var/spool/cups ] && [ ! -L /var/spool/cups ]; then
    # Copy existing spool files if any
    cp -rp /var/spool/cups/* /config/cups/spool/ 2>/dev/null || true
    rm -rf /var/spool/cups
    ln -s /config/cups/spool /var/spool/cups
    bashio::log.info "Symlinked /var/spool/cups to persistent /config/cups/spool"
fi

# 3. Auto-configure the Canon-MF3010 printer if it does not exist
# Prepare the /config/cups directory first (mirroring the base image's prep)
if [ ! -d /config/cups ]; then 
    bashio::log.info "Initializing /config/cups with default CUPS configuration..."
    mkdir -p /config/cups
    cp -R /etc/cups/* /config/cups/
fi

if [ -d /etc/cups ] && [ ! -L /etc/cups ]; then
    rm -rf /etc/cups
    ln -s /config/cups /etc/cups
fi

# Start a temporary cupsd instance to allow lpadmin configuration
bashio::log.info "Starting temporary CUPS instance for printer check/registration..."
cupsd

# Wait for cupsd to become responsive
for i in {1..10}; do
    if lpstat -r | grep -q "ready"; then
        break
    fi
    sleep 1
done

if lpstat -p Canon-MF3010 >/dev/null 2>&1; then
    bashio::log.info "Printer 'Canon-MF3010' already exists. Skipping auto-registration."
else
    bashio::log.info "Printer 'Canon-MF3010' not found. Performing auto-registration..."
    
    # Locate the PPD file for MF3010
    # The Canon UFR II driver installs PPDs under /usr/share/cups/model/
    PPD=$(lpinfo -m | grep -i "MF3010" | head -n 1 | awk '{print $1}')
    if [ -z "$PPD" ]; then
        # Fallback to general UFR II printer driver PPD if specific MF3010 is not found
        PPD=$(lpinfo -m | grep -i "UFRII" | grep -i "3010" | head -n 1 | awk '{print $1}')
    fi
    
    if [ -z "$PPD" ]; then
        bashio::log.error "Could not locate Canon MF3010 PPD file! Printer registration might fail."
    else
        bashio::log.info "Found PPD: $PPD"
    fi

    # Locate the USB URI
    USB_URI=$(lpinfo -v | grep -i "usb://" | grep -i "Canon" | head -n 1 | awk '{print $2}')
    if [ -z "$USB_URI" ]; then
        # Fallback to a standard USB URI if not plugged in
        USB_URI="usb://Canon/MF3010?serial=000000000000"
        bashio::log.warn "Canon MF3010 is not currently plugged in. Registering with fallback URI: $USB_URI"
    else
        bashio::log.info "Found connected Canon printer URI: $USB_URI"
    fi

    # Register the printer
    if [ -n "$PPD" ]; then
        if lpadmin -p Canon-MF3010 -E -v "$USB_URI" -m "$PPD"; then
            bashio::log.info "Successfully registered Canon-MF3010 with PPD $PPD."
        else
            bashio::log.error "Failed to register Canon-MF3010 with lpadmin!"
        fi
    else
        if lpadmin -p Canon-MF3010 -E -v "$USB_URI"; then
            bashio::log.info "Registered Canon-MF3010 without specific PPD (using raw/default)."
        else
            bashio::log.error "Failed to register Canon-MF3010 with lpadmin!"
        fi
    fi
    
    # Enable the printer and set it to accept jobs
    cupsenable Canon-MF3010
    cupsaccept Canon-MF3010
    lpadmin -d Canon-MF3010
    bashio::log.info "Printer 'Canon-MF3010' is now enabled and accepting jobs."
fi

# Stop the temporary cupsd
if [ -f /var/run/cups/cupsd.pid ]; then
    kill $(cat /var/run/cups/cupsd.pid)
    sleep 2
fi

# 4. Hand over execution to the original run script in the foreground
bashio::log.info "Handing over to the main CUPS service..."
exec /run-original.sh
