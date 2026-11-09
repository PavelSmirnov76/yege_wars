'use strict';

// Интерактивный сетевой драйвер TC-19. UI проверяется вручную по кейсу;
// этот процесс подменяет ответы Supabase и ведёт безопасный журнал запросов.
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const readline = require('node:readline');
const playwrightPackage = process.env.TC19_PLAYWRIGHT_MODULE || 'playwright';
const { chromium } = require(playwrightPackage);

const root = __dirname;
const fixture = JSON.parse(fs.readFileSync(path.join(root, 'fixtures.json'), 'utf8'));
const appUrl = process.env.TC19_APP_URL;
const viewportText = process.env.TC19_VIEWPORT || '1440x900';
const viewportMatch = /^(\d+)x(\d+)$/.exec(viewportText);
if (!appUrl || !viewportMatch) {
  throw new Error('Укажите TC19_APP_URL и TC19_VIEWPORT=1440x900 или 360x800.');
}
const viewport = { width: Number(viewportMatch[1]), height: Number(viewportMatch[2]) };
const screenshotsDir = path.resolve(process.env.TC19_SCREENSHOTS_DIR || path.join(os.tmpdir(), 'yege-tc19-captures'));
const scenarioNames = new Set(['normal', 'progress-error', 'attempts-error', 'no-tasks', 'delay-a']);
let scenario = process.env.TC19_SCENARIO || 'normal';
if (!scenarioNames.has(scenario)) throw new Error(`Неизвестный TC19_SCENARIO: ${scenario}`);
const attempts = fixture.attempts.map((x) => ({ ...x }));
const eventLog = [];
const pending = new Map();
let currentAccount = 'tc19_a';
let closed = false;

const taskBySlug = new Map(fixture.tasks.map((task) => [task.slug, task]));
const isoSort = (a, b) => b.created_at.localeCompare(a.created_at) || b.id.localeCompare(a.id);
function writeEvent(kind, details = {}) {
  eventLog.push({ at: new Date().toISOString(), kind, ...details });
  process.stdout.write(`${JSON.stringify(eventLog.at(-1))}\n`);
}
function taskRows() {
  return scenario === 'no-tasks' ? [] : fixture.tasks.filter((task) => task.status === 'published');
}
function profileRows(userId) {
  const user = Object.values(fixture.users).find((x) => x.id === userId);
  return user ? [{ id: user.id, username: user.username, role: user.role }] : [];
}
function progressRows(userId) {
  const userKey = Object.keys(fixture.users).find((key) => fixture.users[key].id === userId);
  if (scenario === 'no-tasks') return [];
  const tasks = taskRows();
  return [...new Set(tasks.map((task) => task.ege_number))]
    .sort((a, b) => a == null ? (b == null ? 0 : 1) : (b == null ? -1 : a - b))
    .map((number) => {
      const group = tasks.filter((task) => task.ege_number === number);
      const solved = group.filter((task) => attempts.some((attempt) =>
        attempt.user === userKey && attempt.task_slug === task.slug && attempt.is_correct,
      )).length;
      return { ege_number: number, solved, total: group.length };
    });
}
function recentRows(userId) {
  if (scenario === 'no-tasks') return [];
  const userKey = Object.keys(fixture.users).find((key) => fixture.users[key].id === userId);
  if (userKey !== 'tc19_a') return [];
  return attempts
    .filter((attempt) => attempt.user === userKey && taskBySlug.get(attempt.task_slug)?.status === 'published')
    .sort(isoSort)
    .slice(0, 10)
    .map((attempt) => {
      const task = taskBySlug.get(attempt.task_slug);
      return {
        id: attempt.id,
        task_id: task.id,
        user_id: fixture.users[userKey].id,
        answer: attempt.answer || 'tc19-synthetic',
        code: '',
        is_correct: attempt.is_correct,
        is_published: false,
        created_at: attempt.created_at,
        task: { id: task.id, slug: task.slug, title: task.title, ege_number: task.ege_number },
      };
    });
}
function jsonResponse(route, status, body, extra = {}) {
  return route.fulfill({ status, contentType: 'application/json; charset=utf-8', headers: extra, body: JSON.stringify(body) });
}
function waitForRelease(key) {
  return new Promise((resolve) => {
    const waiters = pending.get(key) || [];
    waiters.push(resolve);
    pending.set(key, waiters);
  });
}
async function maybeDelay(key, account) {
  if (scenario !== 'delay-a' || account !== 'tc19_a') return;
  writeEvent('request-delayed', { kind: key, account });
  await waitForRelease(key);
  writeEvent('request-released', { kind: key, account });
}
function authBody(username) {
  const user = fixture.users[username] || fixture.users['tc19_a'];
  currentAccount = username in fixture.users ? username : 'tc19_a';
  const now = Math.floor(Date.now() / 1000);
  return {
    access_token: 'tc19-synthetic-access-token',
    token_type: 'bearer',
    expires_in: 3600,
    expires_at: now + 3600,
    refresh_token: 'tc19-synthetic-refresh-token',
    user: { id: user.id, aud: 'authenticated', role: 'authenticated', email: `${user.username}@ege.local`, app_metadata: { provider: 'email', providers: ['email'] }, user_metadata: { username: user.username }, created_at: '2026-11-08T00:00:00.000Z' },
  };
}

async function main() {
  fs.mkdirSync(screenshotsDir, { recursive: true });
  const browser = await chromium.launch({ headless: false });
  writeEvent('browser', { playwright: require(`${playwrightPackage}/package.json`).version, chromium: browser.version() });
  const context = await browser.newContext({ viewport, deviceScaleFactor: 1, isMobile: viewport.width <= 400, hasTouch: viewport.width <= 400 });
  const page = await context.newPage();
  page.on('pageerror', (error) => writeEvent('page-error', { message: error.message }));

  await page.route('**/auth/v1/**', async (route) => {
    const url = new URL(route.request().url());
    if (url.pathname.endsWith('/token')) {
      const posted = route.request().postDataJSON() || {};
      const email = String(posted.email || '').toLowerCase();
      const username = email.startsWith('tc19_b@') ? 'tc19_b' : 'tc19_a';
      writeEvent('auth-login', { account: username });
      return jsonResponse(route, 200, authBody(username));
    }
    if (url.pathname.endsWith('/user')) {
      const user = fixture.users[currentAccount];
      return jsonResponse(route, 200, { id: user.id, aud: 'authenticated', role: 'authenticated', email: `${user.username}@ege.local`, user_metadata: { username: user.username } });
    }
    if (url.pathname.endsWith('/logout')) return jsonResponse(route, 200, {});
    writeEvent('unhandled-auth', { method: route.request().method(), path: url.pathname });
    return jsonResponse(route, 404, { message: 'Unimplemented TC-19 auth endpoint' });
  });

  await page.route('**/rest/v1/**', async (route) => {
    const request = route.request();
    const url = new URL(request.url());
    const endpoint = url.pathname.split('/').pop();
    const user = fixture.users[currentAccount];
    const params = Object.fromEntries(url.searchParams.entries());
    const account = currentAccount;
    writeEvent('api-request', { method: request.method(), endpoint, params, account });

    if (endpoint === 'get_user_progress' && request.method() === 'POST') {
      const body = request.postDataJSON() || {};
      const requestUserId = body.p_user_id;
      const matched = Object.values(fixture.users).find((x) => x.id === requestUserId);
      writeEvent('progress-query-contract', { account, p_user_id: requestUserId, passed: requestUserId === user.id });
      await maybeDelay('progress', matched?.username || account);
      if (scenario === 'progress-error') return jsonResponse(route, 500, { code: 'TC19_PROGRESS_ERROR', message: 'TC-19 synthetic progress failure' });
      if (requestUserId !== user.id) return jsonResponse(route, 403, { code: 'TC19_WRONG_USER', message: 'Unexpected progress user id' });
      return jsonResponse(route, 200, progressRows(requestUserId));
    }
    if (endpoint === 'submissions' && request.method() === 'GET' && params.select?.includes('task:tasks!inner')) {
      const queryUserId = params.user_id?.replace(/^eq\./, '');
      const contract = {
        user_id: queryUserId === user.id,
        published: params['task.status'] === 'eq.published',
        order: params.order === 'created_at.desc.nullslast,id.desc.nullslast',
        limit: params.limit === '10',
      };
      writeEvent('attempt-query-contract', { account, contract });
      await maybeDelay('attempts', account);
      if (scenario === 'attempts-error') return jsonResponse(route, 500, { code: 'TC19_ATTEMPTS_ERROR', message: 'TC-19 synthetic attempts failure' });
      if (Object.values(contract).some((passed) => !passed)) return jsonResponse(route, 400, { code: 'TC19_QUERY_CONTRACT', message: 'Unexpected TC-19 submissions query' });
      return jsonResponse(route, 200, recentRows(user.id));
    }
    if (endpoint === 'submissions' && request.method() === 'GET') {
      const taskId = params.task_id?.replace(/^eq\./, '');
      const selectedTask = fixture.tasks.find((task) => task.id === taskId);
      const ownQuery = params.user_id?.replace(/^eq\./, '') === user.id;
      const rows = attempts
        .filter((attempt) => attempt.task_slug === selectedTask?.slug && attempt.user === currentAccount)
        .map((attempt) => ({ id: attempt.id, answer: attempt.answer || 'tc19-synthetic', code: '', is_correct: attempt.is_correct, is_published: false, created_at: attempt.created_at }));
      return jsonResponse(route, 200, ownQuery ? rows : []);
    }
    if (endpoint === 'profiles') {
      const id = params.id?.replace(/^eq\./, '') || user.id;
      return jsonResponse(route, 200, profileRows(id));
    }
    if (endpoint === 'tasks_public') {
      const slug = params.slug?.replace(/^eq\./, '');
      const rows = taskRows().filter((task) => !slug || task.slug === slug);
      return jsonResponse(route, 200, slug ? (rows[0] || null) : rows);
    }
    if (endpoint === 'get_task_stats' && request.method() === 'POST') {
      return jsonResponse(route, 200, []);
    }
    if (endpoint === 'task_files' || endpoint === 'task_references' || endpoint === 'task_articles' || endpoint === 'reference_articles' || endpoint === 'drafts') {
      return jsonResponse(route, 200, []);
    }
    if (endpoint === 'submit_solution' && request.method() === 'POST') {
      const body = request.postDataJSON() || {};
      const task = fixture.tasks.find((item) => item.id === body.p_task_id);
      if (!task || task.status !== 'published') return jsonResponse(route, 400, { code: 'TC19_UNKNOWN_TASK', message: 'Unknown synthetic task' });
      const correct = body.p_answer === 'tc19-synthetic';
      const submission = {
        id: `a3000000-0000-4000-8000-${String(attempts.length + 1).padStart(12, '0')}`,
        task_slug: task.slug,
        user: currentAccount,
        is_correct: correct,
        answer: String(body.p_answer || ''),
        created_at: new Date(Date.now() + attempts.length).toISOString(),
      };
      attempts.push(submission);
      writeEvent('submit-fixture-update', { account, task_slug: task.slug, correct, id: submission.id });
      return jsonResponse(route, 200, { submission_id: submission.id, is_correct: correct });
    }
    if (endpoint === 'set_solution_published') return jsonResponse(route, 200, null);
    writeEvent('unhandled-rest', { method: request.method(), endpoint, params });
    return jsonResponse(route, 404, { message: `Unimplemented TC-19 endpoint: ${endpoint}` });
  });

  const prompt = `TC-19 ${viewportText}; сценарий=${scenario}. Войдите как tc19_a с паролем tc19-pass; tc19_b переключит аккаунт. Управление — stdin.`;
  await page.goto(appUrl, { waitUntil: 'domcontentloaded' });
  writeEvent('driver-ready', { appUrl: new URL(appUrl).origin, viewport, scenario, fixture: path.basename(root) });
  process.stdout.write(`${prompt}\nКоманды: help | mode normal|progress-error|attempts-error|no-tasks|delay-a | release progress|attempts|all | shot NAME | report | quit\n`);

  const rl = readline.createInterface({ input: process.stdin, output: process.stdout, terminal: false });
  rl.on('line', async (line) => {
    const [command, arg] = line.trim().split(/\s+/, 2);
    if (command === 'help') process.stdout.write('mode меняет режим ответа; release снимает задержку; shot сохраняет кадр; report сохраняет безопасный журнал; quit закрывает browser.\n');
    else if (command === 'mode' && scenarioNames.has(arg)) { scenario = arg; writeEvent('scenario', { value: scenario }); }
    else if (command === 'release') {
      const keys = arg === 'all' ? ['progress', 'attempts'] : [arg];
      for (const key of keys) { for (const resolve of pending.get(key) || []) resolve(); pending.delete(key); }
    }
    else if (command === 'shot' && arg) {
      const name = arg.replace(/[^a-zA-Z0-9_-]/g, '-');
      const filename = path.join(screenshotsDir, `${Date.now()}-${viewportText}-${name}.png`);
      await page.screenshot({ path: filename, fullPage: true });
      writeEvent('screenshot', { path: filename });
    }
    else if (command === 'report') {
      const report = {
        driver: 'TC-19 Playwright route fixture', viewport, appOrigin: new URL(appUrl).origin,
        fixture: path.join(root, 'fixtures.json'), scenario,
        fixtureIds: { users: Object.fromEntries(Object.entries(fixture.users).map(([k, v]) => [k, v.id])), baseExpectedRecentIds: fixture.attempts.filter((attempt) => attempt.user === 'tc19_a' && taskBySlug.get(attempt.task_slug)?.status === 'published').sort(isoSort).slice(0, 10).map((attempt) => attempt.id), currentExpectedRecentIds: recentRows(fixture.users['tc19_a'].id).map((attempt) => attempt.id) },
        events: eventLog,
      };
      const filename = path.join(screenshotsDir, `tc19-${viewportText}-safe-log.json`);
      fs.writeFileSync(filename, `${JSON.stringify(report, null, 2)}\n`);
      writeEvent('report-saved', { path: filename });
    }
    else if (command === 'quit') { closed = true; rl.close(); await context.close(); await browser.close(); }
    else process.stdout.write('Неизвестная команда. Введите help.\n');
  });
  await new Promise((resolve) => rl.on('close', resolve));
  if (!closed) { await context.close(); await browser.close(); }
}

main().catch((error) => { console.error(error); process.exitCode = 1; });
