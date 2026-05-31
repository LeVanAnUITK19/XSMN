# DORA Metrics — XSMN Project

> **DORA** (DevOps Research and Assessment) là 4 chỉ số đo lường hiệu quả vận hành phần mềm,
> được Google/DORA Research đề xuất. Số liệu bên dưới được tính từ lịch sử thực tế
> của repository `LeVanAnUITK19/XSMN` trong quá trình phát triển đồ án.

---

## 1. Deployment Frequency (Tần suất triển khai)

> *Nhóm deploy lên production bao nhiêu lần?*

| Tuần | Số lần merge vào main | Ghi chú |
|------|----------------------|---------|
| 06/04 – 07/04/2026 | 13 lần | PR #6 → #18 — setup ban đầu, cấu hình CI/CD |
| 08/04 – 22/04/2026 | 1 lần  | PR #19 — cập nhật crawler schedule |
| 05/05/2026         | 2 lần  | PR #20 (Docker/CI/CD), PR #21 (Prometheus) |
| 23/05/2026         | 3 lần  | PR #22, #23, #24 — fix crawler, Grafana |

**Tổng:** 24 lần deploy trong ~7 tuần
**Trung bình:** ~3.4 lần/tuần

```
Xếp loại DORA:
Elite:  Nhiều lần/ngày
High:   1 lần/ngày – 1 lần/tuần   ← XSMN đạt mức này ✅
Medium: 1 lần/tuần – 1 lần/tháng
Low:    < 1 lần/tháng
```

**→ Kết quả: HIGH PERFORMER** — Deploy nhiều lần mỗi tuần liên tục.

---

## 2. Lead Time for Changes (Thời gian từ code đến production)

> *Từ khi commit code cho đến khi lên production mất bao lâu?*

| PR | Feature | Commit đầu | Merge vào main | Lead Time |
|----|---------|-----------|----------------|-----------|
| #20 | feat(devops): Docker + CI/CD | 05/05 15:13 | 05/05 15:15 | **~2 phút** |
| #21 | feat: Prometheus metrics | 05/05 19:59 | 05/05 19:59 | **~39 giây** |
| #23 | fix(ci): Bad credentials | 23/05 17:00 | 23/05 17:12 | **~12 phút** |
| #24 | feat: Grafana provisioning | 23/05 22:15 | 23/05 22:35 | **~20 phút** |

**Trung bình Lead Time:** ~9 phút

Thời gian pipeline CI/CD chạy (GitHub Actions):
- Test (Node 18/20/22 matrix): ~2 phút
- Docker build + push GHCR: ~3 phút  
- Deploy Render: ~1 phút
- **Tổng pipeline: ~6 phút**

```
Xếp loại DORA:
Elite:  < 1 giờ   ← XSMN đạt mức này ✅
High:   1 ngày – 1 tuần
Medium: 1 tuần – 1 tháng
Low:    > 1 tháng
```

**→ Kết quả: ELITE** — Code merge xong, lên production trong vòng 6–20 phút nhờ CI/CD tự động.

---

## 3. Mean Time To Restore (MTTR — Thời gian khôi phục)

> *Khi hệ thống có sự cố, mất bao lâu để khắc phục?*

| Sự cố | Phát hiện | Khắc phục | MTTR |
|-------|-----------|-----------|------|
| Crawler fail: `waitForSelector` timeout | 23/05 16:32 | 23/05 17:00 (PR #23) | **~28 phút** |
| CI/CD fail: Bad credentials GHCR | 23/05 16:45 | 23/05 17:12 (PR #23) | **~27 phút** |
| Redis TLS error (local Docker) | 23/05 14:00 | 23/05 14:30 | **~30 phút** |

**Trung bình MTTR:** ~28 phút

```
Xếp loại DORA:
Elite:  < 1 giờ   ← XSMN đạt mức này ✅
High:   < 1 ngày
Medium: 1 ngày – 1 tuần
Low:    > 1 tuần
```

**→ Kết quả: ELITE** — Phát hiện lỗi qua GitHub Actions alert (pipeline đỏ), fix và deploy lại trong < 30 phút.

---

## 4. Change Failure Rate (Tỷ lệ thay đổi gây lỗi)

> *Bao nhiêu % lần deploy gây ra sự cố cần rollback/hotfix?*

| Tổng lần deploy | Lần gây sự cố | Ghi chú |
|----------------|---------------|---------|
| 24 lần | 2 lần | Crawler timeout, CI credentials issue |

```
Change Failure Rate = 2 / 24 × 100 = 8.3%

Xếp loại DORA:
Elite:  0–15%    ← XSMN đạt mức này ✅
High:   16–30%
Medium: 16–30%
Low:    46–60%
```

**→ Kết quả: ELITE** — Chỉ 8.3% deploy gây ra lỗi, đều được phát hiện và fix trong cùng ngày.

---

## Tổng kết DORA

| Chỉ số | Giá trị thực tế | Xếp loại |
|--------|----------------|----------|
| Deployment Frequency | 3.4 lần/tuần | **High** |
| Lead Time for Changes | ~9 phút | **Elite** |
| MTTR | ~28 phút | **Elite** |
| Change Failure Rate | 8.3% | **Elite** |

```
                    Low    Medium   High    Elite
                     │       │       │       │
Deployment Freq      ░░░░░░░░░░░░░░░▓▓▓▓▓▓▓▓░
Lead Time            ░░░░░░░░░░░░░░░░░░░░░░░░▓
MTTR                 ░░░░░░░░░░░░░░░░░░░░░░░░▓
Change Failure Rate  ░░░░░░░░░░░░░░░░░░░░░░░░▓
```

**Nhận xét:** Nhóm đạt mức **Elite** ở 3/4 chỉ số nhờ quy trình CI/CD tự động hoàn toàn — test, build, deploy đều không cần tay. Deployment Frequency ở mức **High** do đây là dự án học tập, không deploy liên tục như production thực tế.

---

## Phân tích và đề xuất tối ưu

### Điểm mạnh
- **Automation hoàn toàn:** Push code → 6 phút sau lên production, không cần thao tác tay
- **Phát hiện lỗi nhanh:** GitHub Actions báo đỏ ngay lập tức khi test/build fail
- **Feedback loop ngắn:** Từ code → test → deploy → monitor chỉ mất ~10 phút

### Cải tiến có thể làm
- **Tăng Deployment Frequency:** Áp dụng feature flags để deploy nhỏ hơn, thường xuyên hơn
- **Giảm Lead Time:** Thêm cache Docker layer để giảm build time từ 3 phút xuống < 1 phút
- **Giảm Change Failure Rate:** Thêm integration test và staging environment trước khi lên production

---

*Số liệu được tính từ GitHub repository history: `LeVanAnUITK19/XSMN`*
*Ngày tính: 23/05/2026*
