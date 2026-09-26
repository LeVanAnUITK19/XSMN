// ================================================================
// XSMN Load Test - k6
// ================================================================
// Cài k6: https://k6.io/docs/get-started/installation/
//   Windows: winget install k6 --source winget
//   Hoặc: choco install k6
//
// Chạy:
//   k6 run test/test.js
//
// Chạy với output Prometheus remote write (xem Grafana realtime):
//   k6 run --out experimental-prometheus-rw test/test.js
//
// Đổi BASE_URL để test local:
//   k6 run -e BASE_URL=http://localhost:3000 test/test.js
// ================================================================

import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Counter, Rate, Trend } from 'k6/metrics';

// ── Custom metrics ────────────────────────────────────────────────
const cacheHitRate  = new Rate('cache_hit_rate');   // tỉ lệ response nhanh (cache)
const errorCount    = new Counter('error_count');   // tổng lỗi
const latencyTrend  = new Trend('latency_ms', true); // latency tùy chỉnh

// ── Config ────────────────────────────────────────────────────────
const BASE_URL = __ENV.BASE_URL || 'https://xsmn-1.onrender.com';

// ── Kịch bản load test ────────────────────────────────────────────
// Phù hợp với Render Free Tier (0.1 CPU shared)
// Gồm 4 giai đoạn:
//   1. Warm up:   0 → 5 VUs trong 30s   (làm nóng Redis cache)
//   2. Normal:    5 → 15 VUs trong 1m   (tải bình thường)
//   3. Peak:     15 → 30 VUs trong 30s  (giới hạn free tier)
//   4. Cool down: 30 → 0 VUs trong 30s
//
// Muốn test stress mạnh hơn (paid tier hoặc local):
//   k6 run -e STRESS=true test/test.js
const isStress = __ENV.STRESS === 'true';

export const options = {
  stages: isStress
    ? [
        { duration: '30s', target: 10  },
        { duration: '30s', target: 50  },
        { duration: '1m',  target: 100 },
        { duration: '30s', target: 200 },
        { duration: '30s', target: 0   },
      ]
    : [
        { duration: '30s', target: 5  }, // 1. Warm up cache
        { duration: '1m',  target: 15 }, // 2. Normal load
        { duration: '30s', target: 30 }, // 3. Peak
        { duration: '30s', target: 0  }, // 4. Cool down
      ],

  thresholds: {
    // 95% requests phải dưới 2 giây
    http_req_duration: ['p(95)<2000'],
    // 99% requests phải dưới 5 giây
    'http_req_duration{type:critical}': ['p(99)<5000'],
    // Tỉ lệ lỗi dưới 5%
    http_req_failed: ['rate<0.05'],
    // Error counter không quá 50
    error_count: ['count<50'],
  },
};

// ── Helper: kiểm tra response ─────────────────────────────────────
function checkResponse(res, name) {
  const ok = check(res, {
    [`${name} - status 2xx`]: (r) => r.status >= 200 && r.status < 300,
    [`${name} - response time < 3s`]: (r) => r.timings.duration < 3000,
    [`${name} - has body`]: (r) => r.body && r.body.length > 0,
  });

  latencyTrend.add(res.timings.duration);

  if (!ok || res.status >= 400) {
    errorCount.add(1);
  }

  // Cache hit heuristic: server waiting time < 50ms
  // (loại bỏ network/TLS overhead, chỉ đo thời gian server xử lý)
  // Cache hit  → Redis trả về ngay → waiting < 50ms
  // Cache miss → MongoDB query    → waiting > 100ms thường
  if (res.timings.waiting < 50) {
    cacheHitRate.add(1);
  } else {
    cacheHitRate.add(0);
  }

  return ok;
}

// ── Main test function ────────────────────────────────────────────
export default function () {

  // ── Group 1: Health check (luôn phải nhanh) ──────────────────
  group('health', () => {
    const res = http.get(`${BASE_URL}/api/results/health`, {
      tags: { type: 'health' },
    });
    check(res, {
      'health - status 200': (r) => r.status === 200,
      'health - response < 500ms': (r) => r.timings.duration < 500,
    });
  });

  sleep(0.2);

  // ── Group 2: GET /api/results (endpoint chính, có Redis cache) ─
  group('get_all_results', () => {
    const res = http.get(`${BASE_URL}/api/results`, {
      tags: { type: 'critical' },
    });
    checkResponse(res, 'GET /api/results');
  });

  sleep(0.3);

  // ── Group 3: Filter theo region ──────────────────────────────
  group('filter_by_region', () => {
    const regions = ['mien-nam', 'mien-trung', 'mien-bac'];
    const region  = regions[Math.floor(Math.random() * regions.length)];

    const res = http.get(`${BASE_URL}/api/results/filter?region=${region}`, {
      tags: { type: 'filter' },
    });
    checkResponse(res, `GET /filter?region=${region}`);
  });

  sleep(0.2);

  // ── Group 4: Filter theo ngày (tạo ngày ngẫu nhiên gần đây) ──
  group('filter_by_date', () => {
    // Random trong 7 ngày gần nhất
    const daysAgo = Math.floor(Math.random() * 7);
    const d = new Date();
    d.setDate(d.getDate() - daysAgo);
    const dateStr = d.toISOString().split('T')[0]; // YYYY-MM-DD

    const res = http.get(
      `${BASE_URL}/api/results/filter?region=mien-nam&date=${dateStr}`,
      { tags: { type: 'filter' } }
    );
    checkResponse(res, 'GET /filter?region&date');
  });

  sleep(0.2);

  // ── Group 5: 404 endpoint (kiểm tra error handling) ──────────
  group('not_found', () => {
    const res = http.get(`${BASE_URL}/api/nonexistent`, {
      tags: { type: 'error' },
    });
    check(res, {
      'not_found - status 404': (r) => r.status === 404,
    });
    // 404 là expected, không count là error
  });

  sleep(0.3);
}

// ── Summary in-console ────────────────────────────────────────────
export function handleSummary(data) {
  const duration = data.metrics.http_req_duration;
  const failed   = data.metrics.http_req_failed;
  const reqs     = data.metrics.http_reqs;

  console.log('\n============================================');
  console.log('           XSMN LOAD TEST SUMMARY          ');
  console.log('============================================');
  console.log(`Total Requests  : ${reqs?.values?.count ?? 'N/A'}`);
  console.log(`Req/sec (avg)   : ${reqs?.values?.rate?.toFixed(2) ?? 'N/A'}`);
  console.log(`Avg Latency     : ${duration?.values?.avg?.toFixed(2) ?? 'N/A'} ms`);
  console.log(`P50 Latency     : ${duration?.values['p(50)']?.toFixed(2) ?? 'N/A'} ms`);
  console.log(`P90 Latency     : ${duration?.values['p(90)']?.toFixed(2) ?? 'N/A'} ms`);
  console.log(`P95 Latency     : ${duration?.values['p(95)']?.toFixed(2) ?? 'N/A'} ms`);
  console.log(`P99 Latency     : ${duration?.values['p(99)']?.toFixed(2) ?? 'N/A'} ms`);
  console.log(`Error Rate      : ${((failed?.values?.rate ?? 0) * 100).toFixed(2)}%`);
  console.log('============================================\n');

  // Trả về JSON để lưu nếu muốn
  return {
    'stdout': JSON.stringify(data, null, 2),
  };
}
