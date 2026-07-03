/**
 * GitHub Pull Request Review Agent - Web Server
 *
 * A zero-dependency Node.js server that hosts a web UI on localhost.
 * Analyzes GitHub PRs for: summary, bugs, improvements, release notes,
 * TODOs, large methods, and duplicate code.
 */

const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = process.env.PORT || 3000;

// ---------------------------------------------------------------------------
// PR Review Logic
// ---------------------------------------------------------------------------

function parsePrUrl(prUrl) {
  const match = prUrl.match(/github\.com\/([^/]+)\/([^/]+)\/pull\/(\d+)/);
  if (!match) throw new Error('Invalid GitHub PR URL format');
  return { owner: match[1], repo: match[2], number: parseInt(match[3], 10) };
}

async function ghFetch(url, token) {
  const headers = {
    Accept: 'application/vnd.github.v3+json',
    'User-Agent': 'PR-Review-Agent',
  };
  if (token) headers.Authorization = `token ${token}`;

  const res = await fetch(url, { headers });
  if (!res.ok) {
    if (res.status === 401) throw new Error('Authentication failed. Provide a valid GitHub token for private repos.');
    if (res.status === 404) throw new Error('PR not found. Check the URL.');
    if (res.status === 403) throw new Error('Rate limit exceeded. Provide a GitHub token to increase your limit.');
    throw new Error(`GitHub API error ${res.status}: ${res.statusText}`);
  }
  return res.json();
}

function analyzeFileChanges(files) {
  const analysis = {
    total_files: files.length,
    additions: files.reduce((s, f) => s + (f.additions || 0), 0),
    deletions: files.reduce((s, f) => s + (f.deletions || 0), 0),
    file_types: {},
    large_changes: [],
  };

  for (const file of files) {
    const filename = file.filename || '';
    const ext = filename.includes('.') ? filename.split('.').pop() : 'no_extension';
    analysis.file_types[ext] = (analysis.file_types[ext] || 0) + 1;

    if ((file.changes || 0) > 200) {
      analysis.large_changes.push({ filename, changes: file.changes });
    }
  }
  return analysis;
}

function addedLines(patch) {
  return patch
    .split('\n')
    .filter((l) => l.startsWith('+') && !l.startsWith('+++'));
}

function detectBugs(files) {
  const bugs = [];
  const patterns = [
    [/console\.log\(/, 'Debug console.log found', 'info'],
    [/debugger;/, 'Debugger statement found', 'warning'],
    [/==\s*null/, 'Use === instead of ==', 'warning'],
    [/\bvar\s+\w+/, 'Use let/const instead of var', 'info'],
    [/catch\s*\([^)]*\)\s*\{\s*\}/, 'Empty catch block', 'warning'],
    [/if\s*\([^)=]*=[^=]/, 'Possible assignment in if condition', 'critical'],
    [/return\s+await\s+/, 'Unnecessary return await', 'info'],
    [/password\s*=\s*["'].*["']/i, 'Hardcoded password detected', 'critical'],
    [/api[_-]?key\s*=\s*["'].*["']/i, 'Hardcoded API key detected', 'critical'],
    [/(TODO|FIXME|XXX)/, 'TODO/FIXME comment found', 'info'],
  ];

  for (const file of files) {
    const patch = file.patch || '';
    if (!patch) continue;
    const lines = addedLines(patch);
    lines.forEach((line, idx) => {
      for (const [re, message, severity] of patterns) {
        if (re.test(line)) {
          bugs.push({ file: file.filename, line: idx + 1, severity, message, code: line.slice(0, 120).trim() });
        }
      }
    });
  }
  return bugs;
}

function suggestImprovements(files) {
  const suggestions = [];
  const patterns = [
    [/function\s+\w+\s*\([^)]*\)\s*\{[^}]{500,}/s, 'Consider breaking down large function', 'Large function'],
    [/if\s*\([^)]*&&[^)]*&&[^)]*\)/, 'Complex condition - consider extracting to a variable', 'Complex logic'],
    [/\.then\([^)]*\)[\s\S]*?\.then\([^)]*\)[\s\S]*?\.then\(/, 'Chain of promises - consider async/await', 'Code style'],
    [/for\s*\([^)]*\.length/, 'Consider using forEach, map, or for...of', 'Modern syntax'],
  ];

  for (const file of files) {
    const patch = file.patch || '';
    if (!patch) continue;
    for (const [re, suggestion, category] of patterns) {
      if (re.test(patch)) {
        suggestions.push({ file: file.filename, category, suggestion });
      }
    }
  }
  return suggestions;
}

function checkTodos(files) {
  const todos = [];
  const re = /(TODO|FIXME|XXX|HACK|NOTE):\s*(.+)/i;
  for (const file of files) {
    const patch = file.patch || '';
    if (!patch) continue;
    addedLines(patch).forEach((line, idx) => {
      const m = line.match(re);
      if (m) todos.push({ file: file.filename, line: idx + 1, type: m[1].toUpperCase(), message: m[2].trim() });
    });
  }
  return todos;
}

function flagLargeMethods(files, threshold = 50) {
  const large = [];
  const fnPatterns = [
    /function\s+\w+\s*\([^)]*\)\s*\{/g,
    /const\s+\w+\s*=\s*(?:async\s+)?\([^)]*\)\s*=>/g,
    /def\s+\w+\([^)]*\):/g,
    /(?:public|private|protected)?\s*\w+\s+\w+\([^)]*\)\s*\{/g,
  ];
  for (const file of files) {
    const patch = file.patch || '';
    if (!patch) continue;
    for (const re of fnPatterns) {
      let m;
      const rex = new RegExp(re.source, 'g');
      while ((m = rex.exec(patch)) !== null) {
        const remaining = patch.slice(m.index + m[0].length);
        const lines = remaining.split('\n').slice(0, threshold + 10).filter((l) => l.trim()).length;
        if (lines > threshold) {
          large.push({ file: file.filename, method: m[0].slice(0, 50), estimated_lines: lines });
        }
      }
    }
  }
  return large;
}

function detectDuplicatedCode(files, minLines = 5) {
  const duplicates = [];
  const blocks = {};
  for (const file of files) {
    const patch = file.patch || '';
    if (!patch) continue;
    const lines = patch
      .split('\n')
      .filter((l) => l.startsWith('+') && !l.startsWith('+++') && l.trim())
      .map((l) => l.slice(1).trim());

    for (let i = 0; i <= lines.length - minLines; i++) {
      const block = lines.slice(i, i + minLines).join('\n');
      if (block.length < 50 || (block.match(/\{/g) || []).length > 3) continue;
      if (blocks[block]) {
        duplicates.push({ block: block.slice(0, 120) + '...', locations: [blocks[block], file.filename] });
      } else {
        blocks[block] = file.filename;
      }
    }
  }
  return duplicates;
}

function generateReleaseNotes(prInfo, analysis, files) {
  const title = prInfo.title || 'No title';
  const labels = (prInfo.labels || []).map((l) => l.name);
  const categories = { features: [], fixes: [], refactors: [], docs: [] };

  if (labels.some((l) => ['feature', 'enhancement'].includes(l))) categories.features.push(title);
  else if (labels.some((l) => ['bug', 'fix'].includes(l))) categories.fixes.push(title);
  else if (labels.some((l) => ['refactor', 'improvement'].includes(l))) categories.refactors.push(title);
  else if (labels.some((l) => ['documentation', 'docs'].includes(l))) categories.docs.push(title);
  else if (files.some((f) => (f.filename || '').endsWith('.md'))) categories.docs.push(title);
  else categories.features.push(title);

  return { title, ...categories, stats: analysis };
}

async function reviewPr(prUrl, token) {
  const { owner, repo, number } = parsePrUrl(prUrl);
  const base = `https://api.github.com/repos/${owner}/${repo}/pulls/${number}`;

  const prInfo = await ghFetch(base, token);
  const files = await ghFetch(`${base}/files?per_page=100`, token);

  const analysis = analyzeFileChanges(files);

  return {
    meta: {
      owner,
      repo,
      number,
      title: prInfo.title,
      author: prInfo.user?.login,
      state: prInfo.state,
      url: prInfo.html_url,
      created_at: prInfo.created_at,
      body: prInfo.body,
    },
    analysis,
    files: files.map((f) => ({ filename: f.filename, status: f.status, additions: f.additions, deletions: f.deletions, changes: f.changes })),
    bugs: detectBugs(files),
    suggestions: suggestImprovements(files),
    todos: checkTodos(files),
    largeMethods: flagLargeMethods(files),
    duplicates: detectDuplicatedCode(files),
    releaseNotes: generateReleaseNotes(prInfo, analysis, files),
  };
}

// ---------------------------------------------------------------------------
// HTTP Server
// ---------------------------------------------------------------------------

const server = http.createServer(async (req, res) => {
  // API endpoint
  if (req.method === 'POST' && req.url === '/api/review') {
    let body = '';
    req.on('data', (chunk) => (body += chunk));
    req.on('end', async () => {
      try {
        const { prUrl, token } = JSON.parse(body || '{}');
        if (!prUrl) throw new Error('Missing PR URL');
        const result = await reviewPr(prUrl, token);
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(result));
      } catch (err) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: err.message }));
      }
    });
    return;
  }

  // Serve the UI
  if (req.method === 'GET' && (req.url === '/' || req.url === '/index.html')) {
    const htmlPath = path.join(__dirname, 'public', 'index.html');
    fs.readFile(htmlPath, (err, data) => {
      if (err) {
        res.writeHead(500, { 'Content-Type': 'text/plain' });
        res.end('Error loading UI');
        return;
      }
      res.writeHead(200, { 'Content-Type': 'text/html' });
      res.end(data);
    });
    return;
  }

  res.writeHead(404, { 'Content-Type': 'text/plain' });
  res.end('Not found');
});

server.listen(PORT, () => {
  console.log('');
  console.log('  ┌────────────────────────────────────────────────┐');
  console.log('  │   🔍  GitHub PR Review Agent - Web UI            │');
  console.log('  ├────────────────────────────────────────────────┤');
  console.log(`  │   ➜  Running at:  http://localhost:${PORT}          │`);
  console.log('  │                                                  │');
  console.log('  │   Open the URL above in your browser.            │');
  console.log('  │   Press Ctrl+C to stop the server.               │');
  console.log('  └────────────────────────────────────────────────┘');
  console.log('');
});
