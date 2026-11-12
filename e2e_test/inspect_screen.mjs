import { execSync } from 'child_process';

function dump() {
  const out = execSync('adb exec-out uiautomator dump /dev/tty', { encoding: 'utf-8' });
  const match = out.match(/<hierarchy[\s\S]*<\/hierarchy>/);
  if (!match) return [];
  const xml = match[0];
  const nodes = [...xml.matchAll(/<node ([^>]+)>/g)].map(m => m[1]);
  const results = [];
  for (const n of nodes) {
    const desc = n.match(/content-desc="([^"]*)"/)?.[1] || '';
    const text = n.match(/text="([^"]*)"/)?.[1] || '';
    const bounds = n.match(/bounds="([^"]*)"/)?.[1] || '';
    const cls = n.match(/class="([^"]*)"/)?.[1] || '';
    if (desc || text || cls.includes('Edit')) {
      results.push({ cls, text, desc, bounds });
    }
  }
  return results;
}

console.log(JSON.stringify(dump(), null, 2));
