# XSMN Observability Stack

Hướng dẫn này viết dành cho người đang học DevOps. Mọi khái niệm sẽ được giải thích từ đầu.

---

## Mục lục

1. [Prometheus là gì](#1-prometheus-là-gì)
2. [Grafana là gì](#2-grafana-là-gì)
3. [prom-client là gì](#3-prom-client-là-gì)
4. [Metrics hoạt động thế nào](#4-metrics-hoạt-động-thế-nào)
5. [Kiến trúc tổng thể](#5-kiến-trúc-tổng-thể)
6. [Cấu trúc folder](#6-cấu-trúc-folder)
7. [Chạy local](#7-chạy-local)
8. [Xem /metrics](#8-xem-metrics)
9. [Mở Prometheus](#9-mở-prometheus)
10. [Kiểm tra Targets](#10-kiểm-tra-targets)
11. [Mở Grafana](#11-mở-grafana)
12. [Dashboard có gì](#12-dashboard-có-gì)
13. [Deploy lên Render](#13-deploy-lên-render)
14. [Environment variables](#14-environment-variables)
15. [Security](#15-security)
16. [PromQL cheat sheet](#16-promql-cheat-sheet)
17. [CPU vs RAM khác nhau thế nào](#17-cpu-vs-ram-khác-nhau-thế-nào)
18. [Traffic được tính thế nào](#18-traffic-được-tính-thế-nào)
19. [High cardinality là gì](#19-high-cardinality-là-gì)
20. [Render limitations](#20-render-limitations)
21. [Debug khi dashboard không có data](#21-debug-khi-dashboard-không-có-data)

---

## 1. Prometheus là gì

Prometheus là một **time-series database** chuyên lưu dữ liệu số theo thời gian.

Nó hoạt động theo mô hình **pull**: Prometheus chủ động gọi đến các service để lấy metrics, không phải service đẩy data đi.

```
Prometheus ---(GET /metrics)---> Backend
          <---(metric data)-----
```

Prometheus lưu data trên disk và cho phép query bằng ngôn ngữ PromQL.

---

## 2. Grafana là gì

Grafana là công cụ **visualization**: lấy data từ Prometheus (hoặc các nguồn khác) và vẽ thành biểu đồ đẹp.

Grafana không lưu metric data — nó chỉ query từ Prometheus và hiển thị.

```
Grafana ---(PromQL query)---> Prometheus ---> chart
```

---

## 3. prom-client là gì

`prom-client` là thư viện Node.js để expose metrics theo **Prometheus format**.

Khi bạn gọi `GET /metrics`, backend trả về text như thế này:

```
# HELP http_requests_total Total number of HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="GET",route="/api/results",status_code="200"} 42
http_requests_total{method="POST",route="/api/results",status_code="201"} 5
```

Prometheus đọc format này, Grafana đọc từ Prometheus.

---

## 4. Metrics hoạt động thế nào

### Các loại metric:

| Type | Mô tả | Ví dụ |
|------|-------|-------|
| **Counter** | Chỉ tăng, không giảm | Tổng số requests |
| **Gauge** | Tăng hoặc giảm | RAM hiện tại, active connections |
| **Histogram** | Đo phân phối giá trị, tính percentile | Latency P95, P99 |
| **Summary** | Tương tự Histogram nhưng tính phía client | Ít dùng hơn |

### Labels:

Labels là key-value gắn vào metric để phân loại:

```
http_requests_total{method="GET", route="/api/results", status_code="200"}
```

Bạn có thể query theo label: "chỉ lấy GET requests", "chỉ lấy 5xx", v.v.

---

## 5. Kiến trúc tổng thể

```
┌─────────────────────────────────────────────────────────┐
│                     Local Machine                        │
│                                                          │
│  ┌──────────────┐    scrape      ┌───────────────────┐  │
│  │  Prometheus  │ ─────────────► │  Backend (Node.js) │  │
│  │  :9090       │ ◄── metrics ── │  :3000/metrics     │  │
│  └──────┬───────┘                └───────────────────┘  │
│         │ query                                          │
│  ┌──────▼───────┐                                        │
│  │   Grafana    │                                        │
│  │   :3000      │                                        │
│  └──────────────┘                                        │
└─────────────────────────────────────────────────────────┘
```

**Hoặc trên Render:**

```
Backend (Render) ──── /metrics ────► Prometheus (Render)
                                           │
                                     Grafana (Render)
                                           │
                                      Your Browser
```

---

## 6. Cấu trúc folder

```
observability/
├── prometheus/
│   ├── prometheus.yml      # Config: scrape targets, intervals
│   ├── Dockerfile          # Build prometheus image
│   └── entrypoint.sh       # Script inject env vars vào config
│
├── grafana/
│   ├── Dockerfile          # Build grafana image
│   ├── provisioning/
│   │   ├── datasources/
│   │   │   └── prometheus.yml   # Auto-add Prometheus datasource
│   │   └── dashboards/
│   │       └── dashboard.yml    # Khai báo folder chứa dashboard JSON
│   └── dashboards/
│       └── xsmn-system-dashboard.json   # Dashboard JSON
│
├── docker-compose.yml      # Chạy Prometheus + Grafana local
├── .env.example            # Template env vars
└── README.md               # File này
```

**Trong backend** (chỉ 2 file):

```
backend/src/monitoring/
├── metrics.js              # Registry + metric definitions
└── metricsMiddleware.js    # Express middleware đo HTTP
```

---

## 7. Chạy local

### Bước 1: Tạo file .env

```bash
cd observability
copy .env.example .env
```

Sửa `.env`:

```env
BACKEND_TARGET=host.docker.internal:3000   # Mac/Windows
# BACKEND_TARGET=172.17.0.1:3000           # Linux (xem note bên dưới)

METRICS_TOKEN=                             # Để trống khi dev local
GF_SECURITY_ADMIN_USER=admin
GF_SECURITY_ADMIN_PASSWORD=mypassword123
```

### Bước 2: Start backend

```bash
cd backend
npm run dev
```

Kiểm tra backend đang chạy: `http://localhost:3000/api/results/health`

### Bước 3: Start Prometheus + Grafana

```bash
cd observability
docker compose --env-file .env up -d
```

### Trên Linux:

Docker không có `host.docker.internal` trên Linux. Dùng IP của Docker bridge:

```bash
ip route | grep docker
# → thường là 172.17.0.1
```

Set trong `.env`:
```env
BACKEND_TARGET=172.17.0.1:3000
```

Hoặc thêm vào `docker-compose.yml` của backend:
```yaml
extra_hosts:
  - "host.docker.internal:host-gateway"
```

---

## 8. Xem /metrics

Khi backend đang chạy:

```bash
curl http://localhost:3000/metrics
```

Bạn sẽ thấy output dạng:

```
# HELP process_cpu_user_seconds_total Total user CPU time
# TYPE process_cpu_user_seconds_total counter
process_cpu_user_seconds_total 0.234

# HELP http_requests_total Total number of HTTP requests
# TYPE http_requests_total counter
http_requests_total{app="xsmn-backend",method="GET",route="/api/results",status_code="200"} 5
```

Nếu set `METRICS_TOKEN`, phải thêm header:

```bash
curl -H "Authorization: Bearer your-token-here" http://localhost:3000/metrics
```

---

## 9. Mở Prometheus

Mở trình duyệt: **http://localhost:9090**

Thử query:

```promql
http_requests_total
```

---

## 10. Kiểm tra Targets

Vào: **http://localhost:9090/targets**

Bạn sẽ thấy job `xsmn-backend`.

- **State: UP** → Prometheus đang scrape thành công
- **State: DOWN** → Có vấn đề. Kiểm tra:
  1. Backend có đang chạy không?
  2. `BACKEND_TARGET` trong `.env` có đúng không?
  3. `/metrics` có trả về data không?
  4. Nếu có `METRICS_TOKEN`, entrypoint.sh có config đúng không?

---

## 11. Mở Grafana

Mở trình duyệt: **http://localhost:3000**

- Username: giá trị `GF_SECURITY_ADMIN_USER` (mặc định: `admin`)
- Password: giá trị `GF_SECURITY_ADMIN_PASSWORD`

Vào: **Dashboards → XSMN → XSMN Backend - Monitoring**

---

## 12. Dashboard có gì

Dashboard chia thành 6 sections:

| Section | Nội dung |
|---------|----------|
| **OVERVIEW** | Stat panels tóm tắt: status, uptime, CPU, memory, RPS, error rate, P95 |
| **SYSTEM** | CPU theo thời gian, RAM/Heap, Event Loop Lag, Active Handles |
| **HTTP TRAFFIC** | RPS, requests by method, requests by status, inbound/outbound traffic |
| **LATENCY** | P50, P90, P95, P99, average, latency by route |
| **ERRORS** | 5xx error rate %, 4xx vs 5xx count |
| **ENDPOINTS** | Top requested endpoints, slowest endpoints, endpoints with most 5xx |

**Dashboard variables** (filter ở trên cùng):
- `Method`: lọc theo GET/POST/PUT/...
- `Route`: lọc theo route cụ thể
- `Interval`: khoảng thời gian tính rate

---

## 13. Deploy lên Render

### Tổng quan luồng:

```
Backend (Render Web Service)
  └── GET /metrics ──► Prometheus (Render Web Service)
                              └──► Grafana (Render Web Service)
```

### Bước 1: Cấu hình backend trên Render

Thêm environment variable vào Render backend service:

```
METRICS_TOKEN=<random-strong-token>
```

Tạo token: `openssl rand -hex 32`

### Bước 2: Deploy Prometheus lên Render

1. Tạo Render Web Service mới
2. Root directory: `observability/prometheus`
3. Build command: (để trống, dùng Dockerfile)
4. Dockerfile path: `Dockerfile`
5. Environment variables:
   ```
   BACKEND_TARGET=your-backend.onrender.com
   METRICS_TOKEN=<same-token-as-backend>
   PROMETHEUS_RETENTION=7d
   ```
6. **Lưu ý**: Render free tier không có persistent disk → data mất khi redeploy.
   Nâng lên paid tier và add Disk nếu cần lưu lâu dài.

### Bước 3: Deploy Grafana lên Render

1. Tạo Render Web Service mới
2. Root directory: `observability/grafana`
3. Environment variables:
   ```
   GF_SECURITY_ADMIN_USER=admin
   GF_SECURITY_ADMIN_PASSWORD=<strong-password>
   ```
4. Sau khi deploy, Grafana tự nhận Prometheus datasource vì đã provision.
5. Dashboard tự xuất hiện vì đã baked vào image.

### Bước 4: Cập nhật Prometheus datasource URL

Sau khi Prometheus deploy xong trên Render, Grafana cần biết URL của Prometheus.

Sửa file `grafana/provisioning/datasources/prometheus.yml`:

```yaml
url: https://your-prometheus.onrender.com
```

Hoặc dùng Render internal network nếu cùng project:

```yaml
url: http://xsmn-prometheus:9090
```

---

## 14. Environment variables

### Backend (`backend/.env`):

| Biến | Mô tả | Bắt buộc |
|------|-------|----------|
| `PORT` | Port backend lắng nghe | Không (default: 3000) |
| `METRICS_TOKEN` | Token bảo vệ /metrics | Không (bỏ trống = không auth) |

### Observability (`observability/.env`):

| Biến | Mô tả | Default |
|------|-------|---------|
| `BACKEND_TARGET` | Host:port của backend | `host.docker.internal:3000` |
| `METRICS_TOKEN` | Token để Prometheus scrape | (trống) |
| `GF_SECURITY_ADMIN_USER` | Grafana admin username | `admin` |
| `GF_SECURITY_ADMIN_PASSWORD` | Grafana admin password | `admin` |
| `PROMETHEUS_RETENTION` | Thời gian giữ data | `7d` |

---

## 15. Security

### METRICS_TOKEN hoạt động thế nào:

1. Bạn tạo một random string (token)
2. Set vào `METRICS_TOKEN` ở cả backend lẫn Prometheus config
3. Khi Prometheus scrape, nó gửi: `Authorization: Bearer <token>`
4. Backend kiểm tra header, nếu sai → 401

### Quy tắc bảo mật:

- **KHÔNG** commit file `.env`
- **KHÔNG** hard-code token trong code
- Dùng `openssl rand -hex 32` để tạo token mạnh
- Đổi Grafana password mặc định `admin`
- Tắt anonymous access Grafana ở production

---

## 16. PromQL cheat sheet

```promql
# Requests per second (1 phút)
sum(rate(http_requests_total[1m]))

# 2xx per second
sum(rate(http_requests_total{status_code=~"2.."}[1m]))

# 5xx error rate %
(sum(rate(http_requests_total{status_code=~"5.."}[5m])) or vector(0))
/ (sum(rate(http_requests_total[5m])) or vector(1)) * 100

# P50 latency
histogram_quantile(0.50, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))

# P95 latency
histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))

# P99 latency
histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))

# Average latency
sum(rate(http_request_duration_seconds_sum[5m]))
/ sum(rate(http_request_duration_seconds_count[5m]))

# CPU usage (Node.js process)
rate(process_cpu_user_seconds_total[1m]) + rate(process_cpu_system_seconds_total[1m])

# Process RSS memory
process_resident_memory_bytes

# Heap used
nodejs_heap_size_used_bytes

# Heap %
(nodejs_heap_size_used_bytes / nodejs_heap_size_total_bytes) * 100

# Inbound traffic (bytes/sec)
sum(rate(http_request_bytes_total[1m]))

# Outbound traffic (bytes/sec)
sum(rate(http_response_bytes_total[1m]))

# Uptime
time() - process_start_time_seconds

# Active in-progress requests
sum(http_requests_in_progress)
```

---

## 17. CPU vs RAM khác nhau thế nào

### CPU metrics từ prom-client:

```
process_cpu_user_seconds_total   → CPU time trong user space (JavaScript code)
process_cpu_system_seconds_total → CPU time trong kernel space (I/O, system calls)
```

Đây là **cumulative counters** (chỉ tăng). Để tính % CPU, dùng `rate()`:

```promql
rate(process_cpu_user_seconds_total[1m])
```

Kết quả là: số giây CPU dùng mỗi giây thực → 0.5 = 50% của 1 CPU core.

**⚠️ Lưu ý**: Đây là CPU của **Node.js process**, không phải toàn bộ CPU của máy Render.

### Memory metrics:

| Metric | Ý nghĩa |
|--------|---------|
| `process_resident_memory_bytes` | **RSS** - tổng RAM mà OS cấp cho process, bao gồm heap, stack, code, shared libs |
| `nodejs_heap_size_total_bytes` | V8 đã cấp phát bao nhiêu heap |
| `nodejs_heap_size_used_bytes` | Heap đang thực sự được dùng (objects, strings...) |
| `nodejs_external_memory_bytes` | Memory ngoài V8 heap (Buffer, native addons) |

RSS > Heap Total vì RSS bao gồm cả stack, code, và external memory.

---

## 18. Traffic được tính thế nào

Middleware đọc headers:

- **Inbound**: `Content-Length` của request (body size)
- **Outbound**: `Content-Length` của response

Lưu vào Counter:
- `http_request_bytes_total`
- `http_response_bytes_total`

Dashboard dùng `rate()` để tính bytes/sec:

```promql
sum(rate(http_request_bytes_total[1m]))   → Inbound bytes/sec
sum(rate(http_response_bytes_total[1m]))  → Outbound bytes/sec
```

**Lưu ý**: Nếu response không set `Content-Length` (streaming, chunked transfer), size sẽ không đo được. GET requests thường không có request body nên inbound traffic sẽ thấp.

---

## 19. High cardinality là gì

**Cardinality** = số lượng unique values của một label.

Ví dụ **BAD** (high cardinality):

```
http_requests_total{route="/api/results/123"}
http_requests_total{route="/api/results/456"}
http_requests_total{route="/api/results/789"}
...
```

Nếu có 1 triệu user ID → 1 triệu time series → Prometheus crash.

Ví dụ **GOOD** (normalized route):

```
http_requests_total{route="/api/results/:id"}
```

Tất cả requests vào cùng 1 time series.

### Cách middleware này tránh high cardinality:

1. Dùng `req.route.path` thay vì `req.url` (lấy route pattern, không phải URL thực)
2. Kết hợp `req.baseUrl` để có full path
3. Không đưa query string vào label
4. Không đưa request body vào label
5. Không đưa user ID, IP, JWT vào label

---

## 20. Render limitations

### 1. CPU/RAM là của Node.js process, không phải host

`process_cpu_user_seconds_total` chỉ đo CPU của Node.js. Nếu Render host có nhiều service khác chạy, dashboard không thấy.

### 2. Prometheus lưu data trên disk

Render free tier dùng **ephemeral storage**: data mất khi restart hoặc redeploy. Để giữ data lâu dài:
- Dùng Render paid tier + add Disk
- Hoặc dùng Prometheus cloud (Grafana Cloud free tier)

### 3. Grafana dashboard tự provision

Dashboard được baked vào Docker image → không mất khi restart. Nếu bạn chỉnh dashboard qua UI, changes sẽ mất khi container rebuild (vì image không thay đổi). Luôn edit file JSON và rebuild.

### 4. Free Render service có thể sleep

Free tier spin down sau 15 phút không activity. Khi sleep, Prometheus sẽ thấy target DOWN và có gap trong graph. Đây là behavior bình thường của Render free.

### 5. Prometheus scrape interval

Prometheus scrape mỗi 15 giây. Nếu request rất ít, graph có thể trông như flat line — không phải lỗi.

---

## 21. Debug khi dashboard không có data

### Bước 1: Kiểm tra backend

```bash
curl http://localhost:3000/metrics
```

→ Phải thấy output Prometheus format. Nếu 404: server chưa chạy hoặc route chưa mount.

### Bước 2: Kiểm tra Prometheus Target

Vào http://localhost:9090/targets

→ Nếu DOWN: xem error message. Thường là connection refused (backend chưa chạy) hoặc wrong host/port.

### Bước 3: Query thẳng trong Prometheus

Vào http://localhost:9090/graph, thử:

```promql
up{job="xsmn-backend"}
```

→ Phải trả về 1. Nếu không có data: job chưa scrape được.

### Bước 4: Kiểm tra datasource trong Grafana

Vào: **Connections → Data sources → Prometheus → Test**

→ Phải hiện "Data source is working".

### Bước 5: Kiểm tra time range

Grafana mặc định hiện "Last 1 hour". Nếu backend mới start, không có data cũ → switch sang "Last 5 minutes".

### Bước 6: Tạo data bằng cách gọi API

```bash
curl http://localhost:3000/api/results
curl http://localhost:3000/api/results/health
curl http://localhost:3000/nonexistent
```

Rồi refresh dashboard sau 30 giây.

### Bước 7: Xem logs Prometheus

```bash
docker compose logs prometheus
```

Tìm dòng `level=error` hoặc `scrape failed`.
