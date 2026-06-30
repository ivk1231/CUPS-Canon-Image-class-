# Home Assistant Local Add-on: Canon CUPS Driver

A robust, permanent Home Assistant local add-on that provides CUPS with Canon UFR II driver support (specifically tested with the Canon MF3010).

This add-on bypasses Home Assistant Supervisor's `s6-overlay` limitations (which typically crash when forced to run as PID 2 via the `--init=true` flag) by using a lightweight `bash` entrypoint. This guarantees the add-on starts reliably across all host reboots.

## Features

- **Persistent Configuration:** Stores CUPS configuration and printers in `/config/cups` (survives reboots and rebuilds).
- **Auto-Registration:** Automatically detects and registers the Canon MF3010 on the first boot.
- **Scaling Fix:** Automatically patches the PPD files to correct the physical hardware margins (A4), eliminating double-scaling issues when printing PDFs.
- **Reboot Resilient:** Uses a custom Bash entrypoint, completely avoiding `s6-overlay` PID 1 crashes.

## Requirements

- Home Assistant OS (tested on Raspberry Pi 4 / ARM64).
- The Linux UFR II printer driver package for your architecture (e.g., `cnrdrvcups-ufr2-uk_6.30-1.10_arm64.deb`).

## Installation Instructions

1. **Enable Local Add-ons in Home Assistant:**
   - Create an `addons` folder in your Home Assistant root directory (usually `/addons` if using the SSH Add-on).

2. **Clone this repository:**
   ```bash
   cd /addons
   git clone https://github.com/ivk1231/CUPS-Canon-Image-class-.git canon_cups
   cd canon_cups
   ```

3. **Provide the Driver:**
   - Download the official Canon UFR II driver for your system architecture.
   - Place the `.deb` file inside the `canon_cups` directory.
   - Ensure the filename matches the `COPY` command in the `Dockerfile`. If it differs, update the `Dockerfile` to match your `.deb` file name.

4. **Install the Add-on:**
   - Go to Home Assistant > Settings > Add-ons > Add-on Store.
   - Click the three dots in the top right and click "Check for updates" to reload local add-ons.
   - Locate **Canon CUPS Driver** under "Local add-ons" and click **Install**.
   - Check the **Start on boot** and **Show in sidebar** toggles, then click **Start**.

5. **Access CUPS:**
   - Once running, you can access the CUPS web interface at `http://<your-home-assistant-ip>:631`.

## Customizing for other Printers

While this add-on is tailored for the Canon MF3010, you can adapt it for other models:
1. Update the `.deb` file and the `Dockerfile` copy commands.
2. In `run.sh`, modify the `USB_URI` and `PPD` variables inside the printer registration block to match your exact printer model.
3. If your printer does not require margin patches, you can remove the `sed` commands in `run.sh` that modify the `ImageableArea`.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
