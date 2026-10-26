// MathMind Practice — Google Apps Script (paste into Extensions → Apps Script of your Google Sheet).
// 1) Change TEACHER_KEY below to your own secret word (only you should know it).
// 2) Deploy → New deployment → Web app → Execute as: Me, Who has access: Anyone → Deploy.
// 3) Copy the Web app URL (ends with /exec) and send it to Claude.

const TEACHER_KEY = 'CHANGE-ME';

const HEAD = ['time','kid','type','day','item','section','question','answer','correct','first_try','tries','seconds','score','total'];

function sheet_(name, head) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let sh = ss.getSheetByName(name);
  if (!sh) sh = ss.insertSheet(name);
  if (sh.getLastRow() === 0) sh.appendRow(head);
  return sh;
}

function doPost(e) {
  const d = JSON.parse(e.postData.contents);
  if (!d || !/^[a-z0-9]{3,20}$/i.test(String(d.kid || ''))) return ContentService.createTextOutput('bad');
  const lock = LockService.getScriptLock();
  lock.waitLock(10000);
  try {
    const cut = v => String(v == null ? '' : v).slice(0, 300);
    sheet_('Results', HEAD).appendRow([new Date(), cut(d.kid), cut(d.type), cut(d.day), cut(d.item), cut(d.section), cut(d.q),
      cut(d.answer), d.correct === true, d.firstTry === true, cut(d.tries), cut(d.seconds), cut(d.score), cut(d.total)]);
  } finally { lock.releaseLock(); }
  return ContentService.createTextOutput('ok');
}

function doGet(e) {
  if (TEACHER_KEY === 'CHANGE-ME' || !e.parameter || e.parameter.key !== TEACHER_KEY) return json_({ error: 'wrong key' });
  const res = sheet_('Results', HEAD).getDataRange().getValues();
  const head = res.shift();
  const rows = res.map(r => { const o = {}; head.forEach((h, i) => o[h] = r[i] instanceof Date ? r[i].toISOString() : r[i]); return o; });
  const kidsSh = sheet_('Kids', ['code', 'name']);
  const kv = kidsSh.getDataRange().getValues(); kv.shift();
  const kids = kv.map(r => ({ code: String(r[0]), name: String(r[1]) }));
  return json_({ rows, kids });
}

function json_(o) {
  return ContentService.createTextOutput(JSON.stringify(o)).setMimeType(ContentService.MimeType.JSON);
}
