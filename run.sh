#!/bin/bash
# =============================================================================
# run-cups.sh: Custom entrypoint bypassing s6-overlay
# Handles persistent config directory setup, dbus/avahi startup,
# and Canon printer registration.
# =============================================================================

log()  { echo "[canon-setup] INFO : $*"; }
warn() { echo "[canon-setup] WARN : $*"; }
fail() { echo "[canon-setup] ERROR: $*" >&2; exit 1; }

# ── 1. Verify driver is baked in ──────────────────────────────────────────
if dpkg -l | grep -q cnrdrvcups; then
    log "Canon UFR II driver detected."
else
    fail "Canon UFR II driver NOT detected! Image may be corrupt."
fi

# ── 2. Ensure /config/cups exists (persistent volume) ────────────────────
if [ ! -d /config/cups ]; then
    log "First boot: initializing /config/cups from /etc/cups defaults..."
    mkdir -p /config/cups
    cp -rp /etc/cups/. /config/cups/
fi

# ── 3. Symlink /etc/cups → /config/cups (idempotent) ─────────────────────
if [ -d /etc/cups ] && [ ! -L /etc/cups ]; then
    rm -rf /etc/cups
    ln -s /config/cups /etc/cups
    log "Symlinked /etc/cups → /config/cups"
fi

# ── 4. Persistent spool directory ─────────────────────────────────────────
if [ ! -d /config/cups/spool ]; then
    mkdir -p /config/cups/spool
    chmod 710 /config/cups/spool
    chown root:lp /config/cups/spool
fi
if [ -d /var/spool/cups ] && [ ! -L /var/spool/cups ]; then
    cp -rp /var/spool/cups/. /config/cups/spool/ 2>/dev/null || true
    rm -rf /var/spool/cups
    ln -s /config/cups/spool /var/spool/cups
    log "Symlinked /var/spool/cups → /config/cups/spool"
fi

# ── 5. Start required background services ────────────────────────────────
log "Starting dbus-daemon..."
mkdir -p /var/run/dbus
rm -f /var/run/dbus/pid
dbus-daemon --system --fork 2>/dev/null || warn "Failed to start dbus-daemon (might be already running or missing)"

log "Starting avahi-daemon..."
avahi-daemon -D 2>/dev/null || warn "Failed to start avahi-daemon"

# ── 6. Start CUPS in the background temporarily for registration ─────────
log "Starting CUPS scheduler..."
cupsd -f &
CUPSD_PID=$!

# Wait for CUPS to become responsive
for i in $(seq 1 15); do
    lpstat -r >/dev/null 2>&1 && break
    sleep 1
done
sleep 2

# ── 7. First-boot printer registration and PPD patching ──────────────────
PRINTERS_CONF="/config/cups/printers.conf"
if grep -q "Canon-MF3010" "$PRINTERS_CONF" 2>/dev/null; then
    log "Printer 'Canon-MF3010' already registered in printers.conf."
    
    # Ensure PPD is patched for A4 margins on every boot just in case
    if [ -f /config/cups/ppd/Canon-MF3010.ppd ]; then
        if ! grep -q '"0 0 595.3 841.9"' /config/cups/ppd/Canon-MF3010.ppd; then
            log "Patching A4 margins in existing PPD..."
            sed -i 's/*ImageableArea A4: .*/\*ImageableArea A4: "0 0 595.3 841.9"/' /config/cups/ppd/Canon-MF3010.ppd
            kill -HUP $CUPSD_PID
        fi
    fi
else
    log "Printer 'Canon-MF3010' not found. Registering..."

    PPD="CNRCUPSMF3010ZK.ppd"
    USB_URI="usb://Canon/MF3010?serial=0165U0000303&interface=1"
    
    log "Registering with URI: $USB_URI and PPD: $PPD"
    lpadmin -p Canon-MF3010 -E -v "$USB_URI" -m "$PPD"
    
    log "Setting default options (no scaling, A4)..."
    lpadmin -p Canon-MF3010 \
        -o media=iso_a4_210x297mm \
        -o PageSize=A4 \
        -o MediaType=PlainPaper \
        -o fit-to-page=false \
        -o print-scaling=none \
        -o fitplot=false \
        -o scaling=100

    cupsenable Canon-MF3010   2>/dev/null || true
    cupsaccept Canon-MF3010   2>/dev/null || true
    lpadmin -d Canon-MF3010   2>/dev/null || true
    
    # Patch the newly created PPD for A4 margins
    if [ -f /config/cups/ppd/Canon-MF3010.ppd ]; then
        log "Patching A4 margins in new PPD..."
        sed -i 's/*ImageableArea A4: .*/\*ImageableArea A4: "0 0 595.3 841.9"/' /config/cups/ppd/Canon-MF3010.ppd
        kill -HUP $CUPSD_PID
    fi

    log "Printer 'Canon-MF3010' registration complete."
fi

# ── 8. Keep container running ─────────────────────────────────────────────
log "Startup complete. CUPS is running."
wait $CUPSD_PID
