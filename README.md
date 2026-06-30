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
- **Important:** Ensure your printer is directly plugged into the Home Assistant host via USB before starting the add-on.

<details>
<summary><strong>View Supported Printers List</strong></summary>

This driver supports a vast array of Canon models (Linux 32-bit, 64-bit, and ARM), including but not limited to:
- **imageCLASS**: MF3010, MF4150, MF4270, MF4350d, MF4450, MF4570dn/dw, MF4750, MF4890dw, MF5870dn, MF6550, MF8050Cn, MF8280Cw, MF8580Cdw, LBP214dw, LBP226dw, LBP6030, LBP6230dw, LBP622Cdw, LBP228x, D520, and many more.
- **imageRUNNER / imageRUNNER ADVANCE**: 1435/iF, 1643i/F, 1730/i, 2002/N, 2204F/N, 2520/W, 2525/i/W, 2530/i/W, 4025, 4045, 4225, 4245, 6055, 6075, 8095, C2020, C2220, C3320, C3520, C5030, C5045, C5235, C5250, C5535i, C5560i, C7580i, DX series, and more.
- **imagePRESS**: C1, C1+, C165, C170, C265, C270, C600, C650, C700, C710, C750, C800, C810, C850, C910, V700, V800, V900.
- **LASER SHOT**: LBP5960, LBP5970, LBP6650dn, LBP6750dn, LBP7750Cdn.
- **imageFORCE**: 710/610/520, 1643/F, 4025-4145 series, 6155-6170 series, 8105-8195 series, C3026, C3122-C3135 series, C5140-C5170 series, C7165.
- **FAX**: L160, L170, L3000.

*(If your model is in the Canon UFR II/UFRII LT Printer Driver for Linux supported list, it should work.)*
</details>

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
