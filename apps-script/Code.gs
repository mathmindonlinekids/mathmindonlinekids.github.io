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
    // Plain numbers stay numbers; everything else ("+", "5 4", "5/2", "= x") is stored as text, so the sheet does not turn it into a formula (#ERROR!) or a date.
    const txt = v => { const s = cut(v); return (s === '' || /^-?\d+(\.\d+)?$/.test(s)) ? s : "'" + s; };
    sheet_('Results', HEAD).appendRow([new Date(), cut(d.kid), cut(d.type), cut(d.day), txt(d.item), txt(d.section), txt(d.q),
      txt(d.answer), d.correct === true, d.firstTry === true, cut(d.tries), cut(d.seconds), cut(d.score), cut(d.total)]);
  } finally { lock.releaseLock(); }
  return ContentService.createTextOutput('ok');
}

function doGet(e) {
  // Student page: brings back this student's saved answers for one homework (answers only, never the correct ones).
  if (e.parameter && e.parameter.kid && e.parameter.hw) {
    const answers = {};
    sheet_('Results', HEAD).getDataRange().getValues().slice(1).forEach(r => {
      if (String(r[1]) === String(e.parameter.kid) && r[2] === 'hw' && String(r[3]) === String(e.parameter.hw) && !(r[7] instanceof Date)) answers[String(r[4])] = r[7];
    });
    return json_({ answers });
  }
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
