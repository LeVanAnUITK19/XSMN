# XSMN Scheduler

Render Cron Job để crawl và cập nhật kết quả xổ số miền Nam hàng ngày.

---

## Kiến trúc

```
Render Cron Job (UTC schedule)
        │
        ▼
scheduler/src/index.js        ← entry point, quản lý cửa sổ thời gian
        │
        ▼
jobs/updateDailyResults.js    ← logic chính: crawl → validate → POST/PUT
        │
        ├── services/crawlerAdapter.js    ← Puppeteer crawl từ minhngoc.net.vn
        ├── services/resultValidator.js   ← kiểm tra COMPLETE/INCOMPLETE
        └── services/backendClient.js     ← HTTP POST/PUT đến backend API
```

### Scheduler khác backend như thế nào

| Điểm | Backend | Scheduler |
|------|---------|-----------|
| Render service type | Web Service | Cron Job |
| Luôn chạy | ✅ | ❌ (chỉ chạy theo lịch) |
| Có HTTP server | ✅ Express | ❌ |
| Truy cập DB | Trực tiếp | Qua Backend API |
| Mục đích | Phục vụ frontend | Cập nhật dữ liệu |

---

## Tái sử dụng crawler

Crawler được tái sử dụng qua `crawlerAdapter.js`. Logic parse HTML giữ nguyên 100% so với `crawl/crawlXSMN_PUT.js` — cùng URL, cùng selector, cùng cách lấy giá trị từ `.bkqmiennam`.

Lý do không import trực tiếp từ `crawl/`: file gốc tự gọi `run()` ngay khi được import (side effect), sẽ khởi động một lần crawl không mong muốn.

---

## Luồng POST/PUT

```
Crawl kết quả ngày hôm nay
        │
        ▼
Kiểm tra DB (GET /api/results/filter?region=&date=)
        │
        ├── Chưa tồn tại ──→ POST /api/results
        │                          │
        │                          ├── 201 OK ──────────────→ CREATED ✅
        │                          └── 409/duplicate ──────→ PUT (race condition)
        │
        └── Đã tồn tại
                │
                ├── Existing COMPLETE + New INCOMPLETE ──→ SKIP (bảo vệ data)
                ├── Data giống hệt ───────────────────────→ SKIP (không ghi thừa)
                └── Cần cập nhật ────────────────────────→ PUT /api/results
```

---

## Cơ chế kiểm tra COMPLETE

Kết quả XSMN được coi là **COMPLETE** khi **tất cả tỉnh** trong ngày đó có đủ 18 giải:

| Giải | Số lượng |
|------|----------|
| G8   | 1        |
| G7   | 1        |
| G6   | 3        |
| G5   | 1        |
| G4   | 7        |
| G3   | 2        |
| G2   | 1        |
| G1   | 1        |
| DB   | 1        |
| **Tổng** | **18** |

Số 0 ở đầu được **giữ nguyên** (`"012345"` không bị chuyển thành `12345`).

---

## Environment Variables

Xem `.env.example` để biết đầy đủ. Các biến **bắt buộc**:

| Biến | Mô tả |
|------|-------|
| `BACKEND_BASE_URL` | URL gốc của backend (không trailing slash) |
| `SCHEDULER_API_TOKEN` | Token Bearer để gọi API ghi. Phải khớp với backend |

Biến tùy chọn:

| Biến | Mặc định | Mô tả |
|------|----------|-------|
| `TZ` | `Asia/Ho_Chi_Minh` | Timezone |
| `HTTP_TIMEOUT_MS` | `60000` | Timeout HTTP request |
| `CRAWL_RETRY_LIMIT` | `3` | Số lần retry crawl |
| `JOB_WINDOW_START` | `16:05` | Bắt đầu cửa sổ làm việc (giờ VN) |
| `JOB_WINDOW_END` | `17:30` | Kết thúc cửa sổ làm việc (giờ VN) |
| `CHECK_INTERVAL_SECONDS` | `300` | Khoảng cách giữa các lượt (giây) |

---

## Chạy local

```bash
cd scheduler

# Copy và điền env vars
cp .env.example .env
# Chỉnh sửa .env: set BACKEND_BASE_URL và SCHEDULER_API_TOKEN

npm install

# Chạy một lượt và thoát (mode test)
node src/index.js --once

# Chạy với ngày cụ thể
node src/index.js --date=2026-09-28 --once

# Chạy theo cửa sổ thời gian cấu hình (mode production)
npm start
```

---

## Test bằng dữ liệu giả

```bash
cd scheduler
npm install

# Chạy unit tests (không gọi crawler thật, không gọi backend thật)
node --test tests/

# Test file cụ thể
node --test tests/resultValidator.test.js
node --test tests/updateDailyResults.test.js
```

---

## Deploy lên Render Cron Job

### Bước 1: Tạo token dùng chung

```bash
openssl rand -hex 32
# Lưu output — đây là SCHEDULER_API_TOKEN
```

### Bước 2: Cấu hình Backend

Trên Render → Backend Web Service → Environment:
```
SCHEDULER_API_TOKEN=<token vừa tạo>
```

### Bước 3: Tạo Render Cron Job

1. Vào [Render Dashboard](https://dashboard.render.com) → **New** → **Cron Job**
2. Kết nối repo GitHub

**Cấu hình:**

| Trường | Giá trị |
|--------|---------|
| **Name** | `xsmn-scheduler` |
| **Root Directory** | *(để trống — build từ repo root)* |
| **Runtime** | Docker |
| **Dockerfile Path** | `scheduler/Dockerfile` |
| **Schedule** | Xem bảng bên dưới |

**Environment Variables:**
```
BACKEND_BASE_URL=https://xsmn-1.onrender.com
SCHEDULER_API_TOKEN=<token đã tạo>
NODE_ENV=production
TZ=Asia/Ho_Chi_Minh
HTTP_TIMEOUT_MS=60000
CRAWL_RETRY_LIMIT=3
JOB_WINDOW_START=16:05
JOB_WINDOW_END=17:30
CHECK_INTERVAL_SECONDS=300
REGION=mien-nam
```

### Bước 4: Lịch Cron (UTC)

Việt Nam = UTC+7. Đổi giờ VN → UTC: **trừ 7 giờ**.

| Lượt | Giờ VN | Giờ UTC | Cron Expression |
|------|--------|---------|-----------------|
| Khởi chạy chính | 16:05 | 09:05 | `5 9 * * *` |
| Backup (nếu lần đầu thất bại) | 16:35 | 09:35 | `35 9 * * *` |

**Khuyến nghị:** Dùng 1 cron expression `5 9 * * *`. Scheduler sẽ tự chạy vòng lặp kiểm tra trong cửa sổ 16:05–17:30 VN.

Nếu cần backup, thêm cron job thứ hai với `35 9 * * *`.

> ⚠️ Render Cron Job Free tier có giới hạn thời gian thực thi. Nếu scheduler chạy vòng lặp dài hơn 30 phút, hãy chia thành nhiều cron jobs độc lập với `--once` flag.

### Bước 5: Start Command

```
node src/index.js
```

Hoặc để chạy một lượt duy nhất mỗi khi Render kích hoạt (nếu Render tự chạy theo lịch đủ dày):

```
node src/index.js --once
```

---

## Xem log

Trên Render Dashboard → Cron Job → **Logs**.

Mỗi lượt chạy in:
```
[2026-09-28T09:05:01Z] [INFO ] [SCHEDULER] XSMN Scheduler khởi động
[2026-09-28T09:05:32Z] [INFO ] [JOB] Bắt đầu updateDailyResults {"date":"2026-09-28","region":"mien-nam"}
[2026-09-28T09:05:33Z] [INFO ] [CRAWLER] Launching Puppeteer
[2026-09-28T09:06:15Z] [INFO ] [CRAWLER] Crawl hoàn thành {"provincesCount":3}
[2026-09-28T09:06:16Z] [INFO ] [JOB] Kết quả hiện có: NOT_FOUND → POST
[2026-09-28T09:06:17Z] [INFO ] [BACKEND] POST thành công
[2026-09-28T09:06:17Z] [INFO ] [SCHEDULER] FINAL SUMMARY {"created":1,"updated":0,"skipped":0,"failed":0}
```

---

## Xử lý job thất bại

1. **Crawler timeout**: Render thử lại theo lịch cron tiếp theo. Hoặc trigger thủ công qua Render Dashboard.
2. **Backend 401**: Kiểm tra `SCHEDULER_API_TOKEN` trùng giữa scheduler và backend.
3. **Backend sleep (cold start)**: `warmUpBackend()` xử lý tự động — chờ 30s.
4. **Kết quả chưa công bố**: Scheduler sẽ SKIP nếu crawler trả về rỗng. Cron lần sau sẽ thử lại.

---

## Tránh chạy trùng với GitHub Actions

Hiện có 2 workflows crawl trong `.github/workflows/`:
- `cron_job_post.yml` — chạy POST lúc 7:00–7:45 UTC (= 14:00–14:45 VN — **KHÔNG ĐÚNG giờ quay XSMN**)
- `cron_job_put.yml` — chạy PUT lúc 8:00–9:55 UTC (= 15:00–16:55 VN)

**Sau khi Render Cron Job hoạt động ổn định:**

1. Vô hiệu hóa cả hai workflows bằng cách thêm `branches-ignore` hoặc điều kiện `if: false`:

```yaml
# Thêm vào đầu on: block để tạm tắt
on:
  workflow_dispatch:  # chỉ chạy khi trigger thủ công
```

2. **Chưa xóa** cho đến khi Render Cron Job được kiểm thử đầy đủ ít nhất 3–5 ngày.

**Lý do cần tắt workflows cũ:** cả hai có thể cùng cập nhật một bản ghi. Backend có upsert nên không tạo duplicate, nhưng có thể ghi đè dữ liệu tốt hơn bằng dữ liệu xấu hơn.

---

## Giới hạn và chi phí Render

| Tier | Giới hạn | Ghi chú |
|------|----------|---------|
| Free Cron Job | 100 job runs/tháng | ~3 runs/ngày trong 30 ngày |
| Free Cron Job | Thời gian thực thi giới hạn | Nếu >30 phút, dùng `--once` |
| Paid | Không giới hạn runs | Khuyến nghị khi production |

Docker build trên Render mất ~5–10 phút lần đầu do cài Chromium. Các lần sau dùng cache.
