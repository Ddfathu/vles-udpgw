# Stage 1: Build BadVPN UDPGW dari Source Resmi di Alpine
FROM alpine:3.20 AS builder
RUN apk update && apk add --no-cache cmake make gcc g++ musl-dev linux-headers curl
WORKDIR /src
RUN curl -fsSL https://github.com/ambrop72/badvpn/archive/refs/tags/1.999.130.tar.gz | tar -xz \
    && cd badvpn-1.999.130 \
    && mkdir build && cd build \
    && cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 \
    && make badvpn-udpgw \
    && mkdir -p /app && cp udpgw/badvpn-udpgw /app/badvpn-udpgw

# Stage 2: Runner Utama Node.js Bawaan Kamu (Versi Ringan)
FROM node:18-alpine
WORKDIR /app

# Install bash agar script start.sh kamu bisa jalan mulus
RUN apk update && apk add --no-cache bash

# Salin binary udpgw yang udah aman di folder /app milik Stage 1
COPY --from=builder /app/badvpn-udpgw /usr/local/bin/badvpn-udpgw

# Salin dependencies & file script Vless bawaan kamu
COPY package*.json ./
RUN npm install
COPY . .

# Pastikan script start.sh diberi izin eksekusi
RUN chmod +x start.sh

EXPOSE 8080
ENV PORT=8080

# Jalankan udpgw di background (Port 7300) baru kemudian start script Node.js kamu
CMD ["/bin/bash", "-c", "/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 500 --max-connections-for-client 20 & node server.js"]