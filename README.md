# 🎰 Lottery App - Xổ Số Miền Nam

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

---

## Ghi chú

- Cache Redis TTL: 2 phút cho endpoint `GET /api/results`
- Khi PUT thành công, cache `results:all` bị xóa để đảm bảo dữ liệu mới nhất
- Index MongoDB: `{ date, region }` unique
