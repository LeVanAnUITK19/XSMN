# 🎰 Lottery App - Xổ Số Miền Nam

Hiiiiiii

Ứng dụng tra cứu kết quả xổ số miền Nam theo thời gian thực, gồm 3 thành phần: **Backend API**, **Crawl Service** và **Frontend Flutter**.

---

## Kiến trúc

```
lottery-app/
├── backend/        # REST API (Node.js + Express + MongoDB + Redis)
├── crawl/          # Script crawl kết quả từ web (Puppeteer)
└── frontend/       # Ứng dụng Flutter (mobile/web)
```

---

## Backend

### Công nghệ
- Node.js (ESM), Express 5
- MongoDB (Mongoose) — lưu trữ kết quả
- Redis (Upstash/ioredis) — cache API
- Puppeteer — crawl dữ liệu nội bộ
- node-cron — lên lịch tự động

### Cài đặt & chạy

```bash
cd backend
npm install
npm run dev      # development (nodemon)
npm start        # production
```

### Biến môi trường (`backend/.env`)

```env
PORT=3000
MONGODB_CONNECTIONSTRING=mongodb+srv://...
REDIS_URL=rediss://...
```

### API Endpoints

| Method | Endpoint                        | Mô tả                              |
|--------|---------------------------------|------------------------------------|
| GET    | `/api/results`                  | Lấy tất cả kết quả (có cache)      |
| GET    | `/api/results/filter`           | Lọc theo `region` và/hoặc `date`   |
| GET    | `/api/results/filter-province`  | Lọc theo `province` và/hoặc `date` |
| POST   | `/api/results`                  | Tạo mới kết quả                    |
| PUT    | `/api/results`                  | Upsert kết quả (crawl cập nhật)    |
| GET    | `/api/results/health`           | Health check                       |

**Query params ví dụ:**
```
GET /api/results/filter?region=mien-nam&date=2026-04-22
GET /api/results/filter-province?province=TP.HCM&date=2026-04-22
```

### Cấu trúc dữ liệu

```json
{
  "date": "2026-04-22T00:00:00.000Z",
  "region": "mien-nam",
  "provinces": [
    {
      "province": "TP.HCM",
      "full": {
        "DB": ["123456"],
        "G1": ["12345"],
        "G2": ["12345"],
        "G3": ["12345", "67890"],
        "G4": ["..."],
        "G5": ["..."],
        "G6": ["..."],
        "G7": ["..."],
        "G8": ["..."]
      }
    }
  ]
}
```

---

## Crawl Service

Script chạy độc lập, crawl kết quả từ [minhngoc.net.vn](https://www.minhngoc.net.vn) và gửi lên API.

```bash
cd crawl
npm install

# Tạo mới kết quả ngày hôm nay (POST)
node crawlXSMN_POST.js

# Cập nhật kết quả ngày hôm nay (PUT/upsert)
node crawlXSMN_PUT.js
```

> Thường được chạy tự động qua **GitHub Actions** theo lịch hàng ngày.

---

## Frontend

Ứng dụng Flutter hiển thị kết quả xổ số và tính năng **dò vé số tự động**.

### Tính năng
- Xem kết quả xổ số miền Nam theo ngày
- Lọc theo tỉnh thành
- Dò vé số 6 chữ số — tự động kiểm tra tất cả các giải (G8 → ĐB, giải phụ, giải khuyến khích)

### Chạy frontend

```bash
cd frontend
flutter pub get
flutter run
```

---

## Triển khai

- **Backend** deploy trên [Render](https://render.com) tại `https://xsmn.onrender.com`
- **Crawl** chạy qua GitHub Actions (`.github/workflows/`)
- **Frontend** build Flutter web hoặc Android/iOS

### CI/CD (GitHub Actions)

Hai workflow tach biet:

| File | Vai tro | Trigger |
|------|---------|---------|
| `.github/workflows/ci.yml` | **CI** — test backend (matrix Node 18 / 20 / 22) | PR vao `main`, push len `main` |
| `.github/workflows/cd.yml` | **CD** — build Docker, push GHCR, deploy Render | Sau khi CI pass tren `main` (push), hoac `workflow_dispatch` |

**Luong khi mo Pull Request:**

```
PR -> CI (test x3 Node) -> xong (khong co CD)
```

**Luong khi push / merge len main:**

```
push main -> CI (test) -> pass -> CD (build image -> push ghcr.io -> Render hook)
```




Chi tiet CD:

1. **build-and-push** — build tu `backend/Dockerfile`, dang len `ghcr.io/<owner>/<repo>` (tag `latest` + short SHA).
2. **deploy** (tuy chon) — neu da dat secret `RENDER_DEPLOY_HOOK_URL`, goi hook de Render khoi dong lai dich vu.

Cau hinh Render: Dashboard service → **Deploy** → **Deploy Hook** → copy URL → GitHub repo → **Settings** → **Secrets and variables** → **Actions** → them `RENDER_DEPLOY_HOOK_URL`.

Keo image ve may (sau khi da push len `main`):

```bash
docker pull ghcr.io/<owner>/<repo>:latest
```

### DORA Metrics (Prometheus + Grafana)

Theo doi 4 chi so DORA tu dong:

| Thanh phan | File / URL |
|------------|------------|
| Push metrics tu CI/CD | `scripts/push-dora-metrics.sh`, secret `DORA_PUSHGATEWAY_URL` |
| Pushgateway | `backend/docker-compose.monitoring.yml` — port **9091** |
| Alert rules | `backend/prometheus/dora-alerts.yml` |
| Dashboard DORA | `backend/grafana/dashboards/dora.json` |
| Dashboard app | `backend/grafana/dashboards/xsmn.json` |
| Bao cao phan tich | [DORA.md](./DORA.md) |

**Demo local — dữ liệu THẬT từ GitHub (không seed):**

```powershell
cd backend
docker compose -f docker-compose.monitoring.yml up -d
cd ..
# Can GITHUB_TOKEN (PAT scope repo) hoac da chay: gh auth login
$env:GITHUB_TOKEN = "ghp_..."
powershell -ExecutionPolicy Bypass -File .\scripts\sync-dora-from-github.ps1 -ReplaceAll
```

Tren Grafana, series hien `pr-6`, `pr-20`... — merge PR that tu repo.

**Chi dung seed khi khong co token GitHub:** `scripts/seed-dora-demo.ps1`

Mo trinh duyet:

| Dich vu | URL | Dang nhap |
|---------|-----|-----------|
| Grafana | http://localhost:3001 | admin / admin |
| Prometheus | http://localhost:9090 | — |
| Alerts | http://localhost:9090/alerts | — |
| Pushgateway | http://localhost:9091 | — |

Trong Grafana: **Dashboards → XSMN → XSMN DORA Metrics** (4 panel chinh + charts).

**Noi dung demo truoc giám khao (5–7 phut):**

1. Giai thich 4 metric DORA tren dashboard (Frequency, Lead Time, MTTR, CFR).
2. Mo Prometheus → **Alerts** — chi 4 rule DORA.
3. Chay `scripts/sync-dora-from-github.ps1 -ReplaceAll` — du lieu that tu GitHub (merged PR + failed CI/PR). CFR/MTTR hien tren Grafana; chi dung `seed-dora-demo` khi khong co token.
4. (Tu chon) Merge PR vao `main` — CD push metric moi len Pushgateway (can expose Pushgateway qua ngrok + secret GitHub).

**Ket noi CI/CD voi Pushgateway (production demo):**

1. Chay Pushgateway tren may co IP public (hoac [ngrok](https://ngrok.com) port 9091).
2. GitHub repo → Settings → Secrets → `DORA_PUSHGATEWAY_URL` = `https://<host>:9091`.
3. Moi lan CD thanh cong / CI fail tren `main` → metric tu dong cap nhat Grafana.

---

## Docker (nang cao)

Du an da ho tro multi-container qua `docker-compose.yml`:

- `backend`: REST API
- `mongodb`: luu tru du lieu
- `redis`: cache API
- `crawl-put` / `crawl-post`: worker crawl (chay theo profile)

### 1) Chay stack chinh (backend + mongo + redis)

```bash
docker compose up -d --build
```

Kiem tra:

```bash
docker compose ps
curl http://localhost:3000/api/results/health
```

### 2) Chay crawler thu cong trong cung network Docker

```bash
# Upsert ket qua (PUT)
docker compose --profile crawler run --rm crawl-put

# Tao moi ket qua (POST)
docker compose --profile crawler run --rm crawl-post
```

### 3) Dung va xoa stack

```bash
docker compose down
```

Neu muon xoa ca volume data:

```bash
docker compose down -v
```

### Ghi chu

- Crawler dung bien moi truong `API_URL` (mac dinh van la endpoint Render neu khong set).
- Trong Compose, `API_URL` duoc tro den `http://backend:3000/api/results` de goi noi bo qua service name.
- `backend` co healthcheck va chi start sau khi `mongodb` + `redis` healthy.

---

## Ghi chú

- Cache Redis TTL: 2 phút cho endpoint `GET /api/results`
- Khi PUT thành công, cache `results:all` bị xóa để đảm bảo dữ liệu mới nhất
- Index MongoDB: `{ date, region }` unique
