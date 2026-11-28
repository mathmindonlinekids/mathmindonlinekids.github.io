// MathMind data layer. One API for every page:
//   - LIVE mode: Supabase (when config.js has the URL and key). Access rules live in the database.
//   - DEMO mode: fictional students kept in memory, so the pages can be tried before Supabase exists.
(function () {
  const cfg = window.MATHMIND_APP || {};
  const LIVE = !!(cfg.SUPABASE_URL && cfg.SUPABASE_ANON_KEY && window.supabase);
  let sb = null;
  if (LIVE) sb = window.supabase.createClient(cfg.SUPABASE_URL, cfg.SUPABASE_ANON_KEY);

  // ---------- colour rule (same as the skill_map view in schema.sql) ----------
  function colour(tries, pct, days) {
    if (!tries) return 'not_started';
    if (tries >= 4 && pct >= 80 && days >= 2) return 'green';
    if (tries >= 2 && pct < 50) return 'red';
    return 'yellow';
  }

  // ---------- DEMO data: fictional children only ----------
  const demo = (function () {
    const skills = window.MM_SKILLS || [];
    const kids = [
      { id: 'demo-1', first_name: 'Маша (демо)', grade: 3, state: 'NC', zoom_url: 'https://zoom.us/' },
      { id: 'demo-2', first_name: 'Лёва (демо)', grade: 3, state: 'NC', zoom_url: 'https://zoom.us/' },
      { id: 'demo-3', first_name: 'Ника (демо)', grade: 4, state: 'FL', zoom_url: 'https://zoom.us/' }
    ];
    // Small deterministic random generator, so the demo looks the same on every load.
    let seed = 7;
    const rnd = () => (seed = (seed * 16807) % 2147483647) / 2147483647;
    const program = {}, overrides = {};
    const now = Date.now();
    kids.forEach((k, ki) => {
      const fw = k.state === 'FL' ? 'FL' : 'NC';
      const list = skills.filter(s => s.framework === fw || s.framework === 'CORE' || s.framework === 'OLY');
      const reach = [0.55, 0.4, 0.65][ki]; // how far into the program each child is
      program[k.id] = list.map((s, i) => {
        const p = i / list.length;
        let tries = 0, pct = 0, days = 0, last = null;
        if (p < reach || rnd() < 0.12) {
          tries = 3 + Math.floor(rnd() * 8);
          const r = rnd();
          pct = r < 0.55 ? 80 + Math.floor(rnd() * 21) : r < 0.82 ? 50 + Math.floor(rnd() * 30) : Math.floor(rnd() * 50);
          days = 1 + Math.floor(rnd() * 4);
          last = new Date(now - Math.floor(rnd() * 20) * 864e5).toISOString();
        }
        return Object.assign({}, s, { student_id: k.id, skill_id: s.id, position: i, tries, pct, days, last_at: last });
      });
    });
    function rows(id) {
      return (program[id] || []).map(r => {
        const o = overrides[id + '|' + r.skill_id] || null;
        return Object.assign({}, r, { override_status: o, status: o || colour(r.tries, r.pct, r.days) });
      });
    }
    return { kids, rows, overrides };
  })();

  // ---------- public API ----------
  const MM = {
    live: LIVE,
    colour,

    async session() {
      if (!LIVE) return { demo: true };
      const { data } = await sb.auth.getSession();
      if (!data.session) return null;
      const { data: prof } = await sb.from('profiles').select('role, display_name, locale').eq('id', data.session.user.id).maybeSingle();
      return { user: data.session.user, profile: prof };
    },

    async signIn(email) {
      const redirect = location.href.replace(/[^/]*$/, '') + 'index.html';
      const { error } = await sb.auth.signInWithOtp({ email, options: { emailRedirectTo: redirect, shouldCreateUser: true } });
      if (error) throw error;
    },

    async signOut() { if (LIVE) await sb.auth.signOut(); },

    async students() {
      if (!LIVE) return demo.kids.map(k => Object.assign({}, k));
      const { data, error } = await sb.from('students').select('id, first_name, grade, state, zoom_url, active').eq('active', true).order('first_name');
      if (error) throw error;
      return data;
    },

    // Full coloured map (admin, teacher, parent).
    async skillMap(studentId) {
      if (!LIVE) return demo.rows(studentId);
      const { data, error } = await sb.from('skill_map').select('*').eq('student_id', studentId).order('position').order('sort');
      if (error) throw error;
      return data;
    },

    // All maps at once for the admin overview.
    async allMaps(ids) {
      if (!LIVE) { const o = {}; ids.forEach(id => (o[id] = demo.rows(id))); return o; }
      const { data, error } = await sb.from('skill_map').select('*').in('student_id', ids);
      if (error) throw error;
      const o = {}; ids.forEach(id => (o[id] = []));
      data.forEach(r => o[r.student_id] && o[r.student_id].push(r));
      return o;
    },

    // Manual colour by admin or teacher (null = back to automatic).
    async setOverride(studentId, skillId, status) {
      if (!LIVE) { const k = studentId + '|' + skillId; if (status) demo.overrides[k] = status; else delete demo.overrides[k]; return; }
      const { error } = await sb.from('student_skills')
        .update({ override_status: status, override_at: status ? new Date().toISOString() : null })
        .eq('student_id', studentId).eq('skill_id', skillId);
      if (error) throw error;
    },

    // What the child sees: unlocked / in_progress / locked (red is never shown as red).
    async kidMap(studentId) {
      if (!LIVE) return demo.rows(studentId).map(r => ({
        skill_id: r.skill_id, title_en: r.title_en, title_ru: r.title_ru, domain: r.domain, pos: r.position,
        status: r.status === 'green' ? 'unlocked' : r.status === 'yellow' ? 'in_progress' : 'locked' }));
      const { data, error } = await sb.rpc('my_skill_map', { sid: studentId });
      if (error) throw error;
      return data;
    }
  };

  window.MM = MM;
})();
