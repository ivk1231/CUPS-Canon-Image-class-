FROM 127.0.0.1:5000/cupsik:1.7

# ── 1. Install the Canon UFR II ARM64 driver ───────────────────────────────
COPY cnrdrvcups-ufr2-uk_6.30-1.10_arm64.deb /tmp/canon.deb
RUN apt-get update && \
    apt-get install -y /tmp/canon.deb && \
    rm -rf /tmp/canon.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# ── 2. Permanent lpadmin authorization ────────────────────────────────────
RUN usermod -aG lpadmin root

# ── 3. Build-time driver verification ─────────────────────────────────────
RUN cupsd && sleep 2 && \
    lpinfo -m | grep -i "Canon" || { echo "ERROR: Canon driver not found!"; exit 1; } && \
    echo "BUILD VERIFIED: Canon UFR II driver is present." && \
    kill $(cat /var/run/cups/cupsd.pid) 2>/dev/null || true

# ── 4. Copy startup script ─────────────────────────────────────────────────
COPY run.sh /usr/local/bin/run-cups.sh
RUN chmod +x /usr/local/bin/run-cups.sh

# ── 5. Override entrypoint — bypass S6-overlay entirely ───────────────────
# S6-overlay's /init requires being PID 1, which the HA Supervisor breaks
# by forcing --init=true (Docker tini shim). A plain bash entrypoint works
# correctly whether it runs as PID 1 or PID 2 under tini.
ENTRYPOINT ["/bin/bash", "/usr/local/bin/run-cups.sh"]
CMD []
