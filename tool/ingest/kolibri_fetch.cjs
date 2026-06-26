const https = require('https');
const http = require('http');

async function fetchJson(url, timeoutMs = 30000) {
  const proto = url.startsWith('https') ? https : http;
  return new Promise((resolve, reject) => {
    const req = proto.get(url, { timeout: timeoutMs, headers: { 'Accept': 'application/json' } }, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        if (res.statusCode !== 200) {
          reject(new Error(`HTTP ${res.statusCode}: ${data.slice(0, 200)}`));
        } else {
          resolve(JSON.parse(data));
        }
      });
    });
    req.on('error', reject);
    req.on('timeout', () => { req.destroy(); reject(new Error('Timeout')); });
  });
}

async function searchKolibri(query, kind, baseUrl, maxResults = 5) {
  const params = new URLSearchParams({
    search: query,
    language: 'en',
    max_results: String(maxResults),
  });
  if (kind) params.set('kind', kind);
  const url = `${baseUrl}/contentnode/?${params}`;
  const body = await fetchJson(url);
  return body.results || [];
}

async function searchAllKinds(query, baseUrl) {
  const kinds = ['video', 'exercise', 'document', 'topic', 'html5'];
  const all = [];
  for (const kind of kinds) {
    try {
      const results = await searchKolibri(query, kind, baseUrl, 5);
      all.push(...results);
    } catch (e) {
      console.warn(`  [warn] Kolibri search kind=${kind} failed: ${e.message}`);
    }
  }
  return all;
}

function bestVideoUrl(files) {
  const mp4 = files.find((f) => f.extension === '.mp4' && f.download_url);
  if (mp4) return mp4.download_url;
  const anyVideo = files.find((f) => f.download_url && f.preset && f.preset.includes('video'));
  if (anyVideo) return anyVideo.download_url;
  const first = files.find((f) => f.download_url);
  return first ? first.download_url : '';
}

function sanitizeId(input) {
  return input
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/_+/g, '_')
    .replace(/^_|_$/g, '');
}

function formatDuration(totalSeconds) {
  if (!totalSeconds) return '';
  const m = Math.floor(totalSeconds / 60);
  const s = totalSeconds % 60;
  return `${m}:${String(s).padStart(2, '0')}`;
}

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

module.exports = {
  fetchJson,
  searchKolibri,
  searchAllKinds,
  bestVideoUrl,
  sanitizeId,
  formatDuration,
  sleep,
};
