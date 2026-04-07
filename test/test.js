import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: 40,
  duration: '1m',
  thresholds: {
    http_req_duration: ['p(95)<1000'],
    http_req_failed: ['rate<0.01'],
  },
};


export default function () {
  const res = http.get('https://xsmn.onrender.com/api/results');

  check(res, {
    'status 200': (r) => r.status === 200,
    'response not empty': (r) => r.body && r.body.length > 0,
  });

  sleep(1);
}