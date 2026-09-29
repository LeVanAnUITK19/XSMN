# ============================================================
# Dockerfile — XSMN Scheduler (Render Cron Job)
#
# Render cấu hình:
#   Root Directory: scheduler
#   Dockerfile Path: Dockerfile   (hoặc scheduler/Dockerfile nếu root trống)
#
# Docker build context = thư mục scheduler/ (Render tự set)
# Nên tất cả COPY path là relative bên trong scheduler/
# ============================================================

FROM node:20-slim

# Cài Chromium và runtime libs cho Puppeteer
RUN apt-get update && apt-get install -y \
    chromium \
    fonts-liberation \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libcups2 \
    libdbus-1-3 \
    libgdk-pixbuf2.0-0 \
    libnspr4 \
    libnss3 \
    libx11-xcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    xdg-utils \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Dùng Chromium hệ thống — tránh download thêm
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

# Timezone Việt Nam
ENV TZ=Asia/Ho_Chi_Minh

# Copy package files (context = scheduler/, nên không cần prefix)
COPY package*.json ./

RUN npm ci --omit=dev

# Copy source code
COPY src ./src

# Không copy .env — inject qua Render environment variables

CMD ["node", "src/index.js"]
