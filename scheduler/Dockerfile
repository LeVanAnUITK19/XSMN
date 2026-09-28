# ============================================================
# Dockerfile — XSMN Scheduler (Render Cron Job)
#
# Build context phải là REPO ROOT để truy cập crawl/ nếu cần.
# Ví dụ từ repo root:
#   docker build -f scheduler/Dockerfile -t xsmn-scheduler .
#
# Scheduler không dùng code từ crawl/ trực tiếp (tránh import side-effect),
# nhưng logic crawl được viết lại trong crawlerAdapter.js theo cùng pattern.
# ============================================================

FROM node:20-slim

# Cài Chromium và runtime libs cho Puppeteer
RUN apt-get update && apt-get install -y \
    chromium \
    fonts-liberation \
    libappindicator3-1 \
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

# Copy package files trước để tận dụng Docker layer cache
COPY scheduler/package*.json ./

RUN npm ci --omit=dev

# Copy source scheduler
COPY scheduler/src ./src

# Không copy .env — inject qua Render environment variables

# Entry point
CMD ["node", "src/index.js"]
