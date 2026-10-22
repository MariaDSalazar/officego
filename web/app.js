const APPS = [
  ['Word', 'W', 'var(--word)'], ['Excel', 'X', 'var(--excel)'], ['PowerPoint', 'P', 'var(--app-powerpoint)'], ['Outlook', 'O', 'var(--outlook)'],
  ['Access', 'A', 'var(--app-access)'], ['Publisher', 'Pb', 'var(--publisher)'], ['OneNote', 'N', 'var(--app-onenote)'],
];
const EDITIONS = {
  ProPlus: { name: 'Professional Plus', apps: ['Word', 'Excel', 'PowerPoint', 'Outlook', 'Access', 'Publisher', 'OneNote'] },
  Standard: { name: 'Standard', apps: ['Word', 'Excel', 'PowerPoint', 'Outlook', 'Publisher', 'OneNote'] },
  Professional: { name: 'Professional', apps: ['Word', 'Excel', 'PowerPoint', 'Outlook', 'Access', 'Publisher', 'OneNote'] },
  HomeBusiness: { name: 'Home & Business', apps: ['Word', 'Excel', 'PowerPoint', 'Outlook', 'OneNote'] },
  HomeStudent: { name: 'Home & Student', apps: ['Word', 'Excel', 'PowerPoint', 'OneNote'] },
  Business: { name: 'Business', apps: ['Word', 'Excel', 'PowerPoint', 'Outlook', 'OneNote'] },
};
const PRODUCTS = {
  365: { name: 'Microsoft 365', note: 'Suscripción, siempre al día', channel: 'Current', weight: 1.9, minimumBuild: 10240, editions: { ProPlus: 'O365ProPlusRetail', Business: 'O365BusinessRetail' } },
  2024: { name: 'Office 2024', note: 'La más nueva de compra única', requires: 'Windows 10 22H2', channel: 'PerpetualVL2024', weight: 2.1, minimumBuild: 19045, editions: { ProPlus: 'ProPlus2024Volume', Standard: 'Standard2024Volume' } },
  2021: { name: 'Office 2021', note: 'Estable y probada', requires: 'Windows 10 1809', channel: 'PerpetualVL2021', weight: 1.9, minimumBuild: 17763, editions: { ProPlus: 'ProPlus2021Volume', Standard: 'Standard2021Volume' } },
  2019: { name: 'Office 2019', note: 'Para Windows 10 antiguos', channel: 'PerpetualVL2019', weight: 1.8, minimumBuild: 10240, editions: { ProPlus: 'ProPlus2019Volume', Standard: 'Standard2019Volume' } },
  2016: {
    name: 'Office 2016', note: 'Clásica, se instala completa', c2r: 'O16GA', weight: 2.5, minimumBuild: 7601,
    editions: { ProPlus: 'ProPlusRetail', Standard: 'StandardRetail', Professional: 'ProfessionalRetail', HomeBusiness: 'HomeBusinessRetail', HomeStudent: 'HomeStudentRetail' },
  },
  2013: {
    name: 'Office 2013', note: 'La más ligera', c2r: 'O15GA', weight: 1.5, minimumBuild: 7601,
    editions: { ProPlus: 'ProPlusRetail', Standard: 'StandardRetail', Professional: 'ProfessionalRetail', HomeBusiness: 'HomeBusinessRetail' },
  },
};
const ADD_ONS = [
  { key: 'VisioPro', name: 'Visio Professional', abbreviation: 'V', color: 'var(--visio-pro)', ids: { 2024: 'VisioPro2024Volume', 2021: 'VisioPro2021Volume', 2019: 'VisioPro2019Volume', 365: 'VisioProRetail' } },
  { key: 'VisioStd', name: 'Visio Standard', abbreviation: 'Vs', color: 'var(--visio-std)', ids: { 2024: 'VisioStd2024Volume', 2021: 'VisioStd2021Volume', 2019: 'VisioStd2019Volume' } },
  { key: 'ProjectPro', name: 'Project Professional', abbreviation: 'Pj', color: 'var(--project-pro)', ids: { 2024: 'ProjectPro2024Volume', 2021: 'ProjectPro2021Volume', 2019: 'ProjectPro2019Volume', 365: 'ProjectProRetail' } },
  { key: 'ProjectStd', name: 'Project Standard', abbreviation: 'Ps', color: 'var(--project-std)', ids: { 2024: 'ProjectStd2024Volume', 2021: 'ProjectStd2021Volume', 2019: 'ProjectStd2019Volume' } },
];
const ALWAYS_LEFT_OUT = ['Groove', 'Lync', 'OneDrive', 'OutlookForWindows', 'Teams'];
const RECOMMENDATION_ORDER = ['2024', '2021', '2019', '2016'];
const ADD_ON_WEIGHT_GB = 0.6;
const C2R_URL = 'https://c2rsetup.officeapps.live.com/c2r/download.aspx';
const RELEASE_API = 'https://api.github.com/repos/MariaDSalazar/officego/releases/latest';
const DEFAULT_APPS = 3;
const WINDOWS_11 = 22631;
const WINDOWS_10 = 19045;
const WINDOWS_11_PLATFORM = 13;
const OLD_WINDOWS = { '6.1': 'Windows 7', '6.2': 'Windows 8', '6.3': 'Windows 8.1' };
const OTHER_SYSTEMS = [[/Android/, 'Android'], [/iPhone|iPad/, 'iOS'], [/CrOS/, 'ChromeOS'], [/Mac OS X/, 'macOS'], [/Linux/, 'Linux']];
const WINDOWS_NOTES = {
  22631: 'Con Windows 11 le caben todas. Te marcamos la más nueva de compra única.',
  19045: 'Con Windows 10 22H2 también le caben todas: es lo mínimo que pide Office 2024.',
  17763: 'Ese Windows 10 no llega a la versión 22H2, que pide Office 2024. Te marcamos 2021.',
  10240: 'Las primeras versiones de Windows 10 no admiten 2021 ni 2024. Te marcamos 2019.',
};
const OUTPUT_LEADS = {
  carpeta: 'Crear instalador sin conexión deja Office entero en la carpeta que elijas. La llevas a otro equipo, sin internet, y abres instalar.cmd.',
  cmd: 'Tres líneas: entra en su propia carpeta y le pasa a setup.exe el configuration.xml que tiene al lado.',
  informe: 'Copiar informe pone en texto todo lo que OfficeGo mira de tu equipo, para pegarlo donde pidas ayuda.',
  quitar: 'Desinstalar arma este archivo y se lo pasa a la misma herramienta de Microsoft. Tus documentos no se tocan.',
};
const XML_TOKENS = /(<\/?|\/?>)|("[^"]*")|([\w.-]+)(?==)|((?<=<\/?)[\w.-]+)/g;
const FLAP_SETS = ['0123456789', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'];
const FLAP_MS = 70;
const FLAP_TURNS = 4;
const TYPE_MS = 14;
const TYPE_STEP = 2;
const RING_START = 0.3;
const RING_END = 0.78;
const RING_SPAN = 0.6;
const RING_EASE = 0.1;
const STRIPE_BARS = 96;
const DEMO_MOVE_MS = 950;
const DEMO_PRESS_MS = 160;
const DEMO_REST_MS = 1500;
const DEMO_ENTRY = [90, 120];
const DEMO_STEPS = ['#apps [data-key="Outlook"]', '#addons [data-key="VisioPro"]', '#bits [data-bits="32"]', '#apps [data-key="Outlook"]', '#addons [data-key="VisioPro"]', '#bits [data-bits="64"]'];
const SETTLE_MS = 2500;
const THEME_ICONS = '<svg class="icon-sun" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="4.2"/><path d="M12 2.5v2.2M12 19.3v2.2M2.5 12h2.2M19.3 12h2.2M5.3 5.3l1.6 1.6M17.1 17.1l1.6 1.6M5.3 18.7l1.6-1.6M17.1 6.9l1.6-1.6"/></svg><svg class="icon-moon" viewBox="0 0 24 24" aria-hidden="true"><path d="M20.5 14.2A8.5 8.5 0 1 1 9.8 3.5a6.8 6.8 0 0 0 10.7 10.7z"/></svg>';
const FIT_HINT = 'La app lo lee sola al abrir. Aquí lo eliges tú para ver qué le cabe a cada uno.';

const $ = (selector, root = document) => root.querySelector(selector);
const $$ = (selector, root = document) => [...root.querySelectorAll(selector)];
const reduced = matchMedia('(prefers-reduced-motion: reduce)').matches;
const wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
const clamp = (value) => Math.min(1, Math.max(0, value));
const numberEs = new Intl.NumberFormat('es', { maximumFractionDigits: 1 });
const listEs = new Intl.ListFormat('es', { type: 'conjunction' });
const dateEs = new Intl.DateTimeFormat('es', { day: 'numeric', month: 'long', year: 'numeric' });
const formatSize = (bytes) => (bytes >= 1e6 ? `${numberEs.format(bytes / 1e6)} MB` : `${Math.round(bytes / 1e3)} KB`);

const copyText = async (text, label, rest = 'Copiar') => {
  try {
    await navigator.clipboard.writeText(text);
    label.textContent = 'Copiado';
  } catch {
    label.textContent = 'No se pudo copiar';
  }
  setTimeout(() => (label.textContent = rest), SETTLE_MS);
};

$$('.stripe').forEach((stripe) => stripe.append(...Array.from({ length: STRIPE_BARS }, (_, index) => {
  const bar = document.createElement('i');
  bar.style.setProperty('--n', index);
  return bar;
})));

(() => {
  const targets = $$('[data-reveal], [data-tilt-in]');
  if (!('IntersectionObserver' in window)) return targets.forEach((el) => el.classList.add('is-in'));
  const io = new IntersectionObserver((entries) => {
    for (const entry of entries) if (entry.isIntersecting) { entry.target.classList.add('is-in'); io.unobserve(entry.target); }
  }, { rootMargin: '0px 0px -12% 0px', threshold: 0.1 });
  targets.forEach((el) => io.observe(el));
  addEventListener('load', () => setTimeout(() => targets.forEach((el) => {
    const box = el.getBoundingClientRect();
    if (box.top < innerHeight && box.bottom > 0) el.classList.add('is-in');
  }), SETTLE_MS));
})();

(() => {
  const root = document.documentElement;
  const buttons = $$('[data-theme-toggle]');
  buttons.forEach((button) => (button.innerHTML = THEME_ICONS));
  const label = () => buttons.forEach((button) => {
    const next = root.dataset.theme === 'light' ? 'Cambiar a tema oscuro' : 'Cambiar a tema claro';
    button.setAttribute('aria-label', next);
    button.title = next;
  });
  buttons.forEach((button) => button.addEventListener('click', () => {
    root.dataset.theme = root.dataset.theme === 'light' ? 'dark' : 'light';
    localStorage.setItem('officego-tema', root.dataset.theme);
    label();
  }));
  label();
})();

(() => {
  const hero = $('.hero');
  const disc = $('.disc');
  const value = $('#ring-value');
  const how = $('.how');
  const frame = $('.stage-frame');
  let shown = 0;
  let target = RING_START;
  let painting = false;
  const paint = () => {
    shown += (target - shown) * RING_EASE;
    if (Math.abs(target - shown) < 0.001) shown = target;
    disc.style.setProperty('--fill', shown.toFixed(4));
    value.textContent = `${Math.round(shown * 100)} %`;
    painting = shown !== target;
    if (painting) requestAnimationFrame(paint);
  };
  let queued = false;
  const measure = () => {
    queued = false;
    const heroBox = hero.getBoundingClientRect();
    target = RING_START + (RING_END - RING_START) * clamp(-heroBox.top / (heroBox.height * RING_SPAN));
    if (!painting) { painting = true; requestAnimationFrame(paint); }
    if (!reduced) frame.style.setProperty('--tilt', clamp(how.getBoundingClientRect().top / innerHeight).toFixed(4));
  };
  addEventListener('scroll', () => { if (!queued) { queued = true; requestAnimationFrame(measure); } }, { passive: true });
  addEventListener('resize', measure);
  measure();
})();

(() => {
  const shots = $$('.stage .shot');
  const statements = $$('.statement');
  if (!('IntersectionObserver' in window)) return;
  const io = new IntersectionObserver((entries) => {
    for (const entry of entries) {
      if (!entry.isIntersecting) continue;
      statements.forEach((statement) => statement.classList.toggle('is-active', statement === entry.target));
      shots.forEach((shot) => shot.classList.toggle('is-on', shot.dataset.shot === entry.target.dataset.shot));
    }
  }, { rootMargin: '-45% 0px -45% 0px' });
  statements.forEach((statement) => io.observe(statement));
})();

(() => {
  const tabs = $$('.outputs [role="tab"]');
  const papers = $$('.outputs .paper');
  const select = (tab) => {
    tabs.forEach((other) => other.setAttribute('aria-selected', String(other === tab)));
    papers.forEach((paper) => paper.classList.toggle('is-on', paper.dataset.out === tab.dataset.out));
    $('#out-lead').textContent = OUTPUT_LEADS[tab.dataset.out];
  };
  tabs.forEach((tab, index) => {
    tab.addEventListener('click', () => select(tab));
    tab.addEventListener('keydown', (event) => {
      const step = { ArrowDown: 1, ArrowRight: 1, ArrowUp: -1, ArrowLeft: -1 }[event.key];
      if (!step) return;
      event.preventDefault();
      const next = tabs[(index + step + tabs.length) % tabs.length];
      next.focus();
      select(next);
    });
  });
})();

const detectSystem = async () => {
  const agent = navigator.userAgent;
  const nt = agent.match(/Windows NT (\d+\.\d+)/);
  if (!nt) return { windows: false, name: OTHER_SYSTEMS.find(([pattern]) => pattern.test(agent))?.[1] };
  if (OLD_WINDOWS[nt[1]]) return { windows: true, old: true, name: OLD_WINDOWS[nt[1]] };
  try {
    const { platformVersion, bitness } = await navigator.userAgentData.getHighEntropyValues(['platformVersion', 'bitness']);
    const eleven = Number(platformVersion.split('.')[0]) >= WINDOWS_11_PLATFORM;
    return { windows: true, name: eleven ? 'Windows 11' : 'Windows 10', build: eleven ? WINDOWS_11 : WINDOWS_10, bitness };
  } catch {
    return { windows: true, name: 'Windows' };
  }
};

const builder = (() => {
  const state = { build: WINDOWS_11, version: '2024', edition: 'ProPlus', apps: ['Word', 'Excel', 'PowerPoint'], language: 'es-es', bits: '64', addOns: [] };
  const fits = (key) => state.build >= PRODUCTS[key].minimumBuild;
  const recommended = () => RECOMMENDATION_ORDER.find(fits) ?? '2016';
  const addOnIds = () => ADD_ONS.filter((addOn) => state.addOns.includes(addOn.key) && addOn.ids[state.version]);
  let boardBuild = state.build;
  let detected = null;

  const adjust = () => {
    if (!fits(state.version)) state.version = recommended();
    const product = PRODUCTS[state.version];
    if (!product.editions[state.edition]) state.edition = Object.keys(product.editions)[0];
    const pickable = EDITIONS[state.edition].apps;
    const kept = state.apps.filter((app) => pickable.includes(app));
    state.apps = kept.length ? kept : pickable.slice(0, DEFAULT_APPS);
    state.addOns = state.addOns.filter((key) => ADD_ONS.find((addOn) => addOn.key === key).ids[state.version]);
  };

  const xml = () => {
    const product = PRODUCTS[state.version];
    const left = [...EDITIONS[state.edition].apps.filter((app) => !state.apps.includes(app)), ...ALWAYS_LEFT_OUT];
    const lines = ['<Configuration>', `  <Add OfficeClientEdition="${state.bits}" Channel="${product.channel}">`, `    <Product ID="${product.editions[state.edition]}">`, `      <Language ID="${state.language}" />`];
    [...new Set(left)].forEach((app) => lines.push(`      <ExcludeApp ID="${app}" />`));
    lines.push('    </Product>');
    addOnIds().forEach((addOn) => lines.push(`    <Product ID="${addOn.ids[state.version]}">`, `      <Language ID="${state.language}" />`, '    </Product>'));
    lines.push('  </Add>', '  <Property Name="AUTOACTIVATE" Value="0" />', '  <Property Name="FORCEAPPSHUTDOWN" Value="TRUE" />', '  <Display Level="Full" AcceptEULA="TRUE" />', '</Configuration>');
    return lines.join('\n');
  };

  const c2rUrl = () => {
    const product = PRODUCTS[state.version];
    const platform = state.bits === '32' ? 'x86' : 'x64';
    return `${C2R_URL}?ProductreleaseID=${product.editions[state.edition]}&platform=${platform}&language=${state.language}&version=${product.c2r}`;
  };

  const highlight = (line) => {
    const fragment = document.createDocumentFragment();
    let last = 0;
    for (const match of line.matchAll(XML_TOKENS)) {
      const [piece, punct, value, attr] = match;
      if (match.index > last) fragment.append(line.slice(last, match.index));
      const span = document.createElement('span');
      span.className = punct ? 'p' : value ? 'v' : attr ? 'a' : 't';
      span.textContent = piece;
      fragment.append(span);
      last = match.index + piece.length;
    }
    fragment.append(line.slice(last));
    return fragment;
  };

  const keptLines = (before, after) => {
    const table = Array.from({ length: before.length + 1 }, () => new Array(after.length + 1).fill(0));
    for (let i = before.length - 1; i >= 0; i--) {
      for (let j = after.length - 1; j >= 0; j--) {
        table[i][j] = before[i] === after[j] ? table[i + 1][j + 1] + 1 : Math.max(table[i + 1][j], table[i][j + 1]);
      }
    }
    const kept = new Set();
    for (let i = 0, j = 0; i < before.length && j < after.length;) {
      if (before[i] === after[j]) { kept.add(j); i++; j++; } else if (table[i + 1][j] >= table[i][j + 1]) i++; else j++;
    }
    return kept;
  };

  let shownLines = $('#xml-code').textContent.split('\n');
  let typing = 0;
  const write = async (text, plain) => {
    const lines = text.split('\n');
    const kept = keptLines(shownLines, lines);
    const run = ++typing;
    shownLines = lines;
    const paint = (row, line) => row.replaceChildren(plain ? line : highlight(line));
    const rows = lines.map((line, index) => {
      const row = document.createElement('span');
      if (kept.has(index)) paint(row, line);
      return row;
    });
    const code = document.createElement('code');
    rows.forEach((row, index) => code.append(...(index ? ['\n', row] : [row])));
    $('#xml-code').replaceChildren(code);
    for (const [index, row] of rows.entries()) {
      if (kept.has(index)) continue;
      const line = lines[index];
      row.classList.add('is-typing');
      for (let end = line.match(/^\s*/)[0].length; end < line.length; end += TYPE_STEP) {
        if (run !== typing) return;
        row.textContent = line.slice(0, end);
        await wait(TYPE_MS);
      }
      if (run !== typing) return;
      row.classList.remove('is-typing');
      paint(row, line);
    }
  };

  const flap = (el, text) => {
    const cells = [...text].map((char) => Object.assign(document.createElement('span'), { className: 'flap', textContent: char }));
    el.replaceChildren(...cells);
    cells.forEach((cell, index) => {
      const final = cell.textContent;
      const set = FLAP_SETS.find((chars) => chars.includes(final));
      if (!set) return;
      let turns = FLAP_TURNS + index;
      const turn = () => {
        cell.textContent = turns ? set[Math.floor(Math.random() * set.length)] : final;
        if (!reduced) cell.animate([{ transform: 'rotateX(-90deg)' }, { transform: 'none' }], { duration: FLAP_MS, easing: 'ease-out' });
        if (turns-- > 0) setTimeout(turn, FLAP_MS);
      };
      turn();
    });
  };

  const radio = (container, attribute, value, label) => {
    const button = document.createElement('button');
    button.type = 'button';
    button.setAttribute('role', 'radio');
    button.dataset[attribute] = value;
    button.textContent = label;
    container.append(button);
    return button;
  };

  const toggle = (container, key, abbreviation, color, name) => {
    const button = document.createElement('button');
    button.type = 'button';
    button.dataset.key = key;
    const badge = document.createElement('i');
    badge.textContent = abbreviation;
    badge.style.setProperty('--app', color);
    button.append(badge, name);
    container.append(button);
    return button;
  };

  const render = () => {
    adjust();
    const product = PRODUCTS[state.version];
    const suite = Boolean(product.c2r);
    const pick = recommended();
    const boardMoved = boardBuild !== state.build;
    boardBuild = state.build;

    $$('#windows [role="radio"]').forEach((button) => button.setAttribute('aria-checked', String(Number(button.dataset.build) === state.build)));
    $('#fit-note').textContent = WINDOWS_NOTES[state.build];
    $('#fit-detected').textContent = detected?.build === state.build ? detected.note : FIT_HINT;
    const pickName = PRODUCTS[pick].name;
    $('#fit-word-text').textContent = pickName;
    if (boardMoved) flap($('#fit-word'), pickName); else $('#fit-word').textContent = pickName;
    $$('#versions [role="radio"]').forEach((button) => {
      const key = button.dataset.version;
      const item = PRODUCTS[key];
      button.disabled = !fits(key);
      button.setAttribute('aria-checked', String(key === state.version));
      $('.year-note', button).textContent = !fits(key) ? `Pide ${item.requires}` : key === pick ? 'La que te marcamos' : item.note;
      if (boardMoved) flap($('b', button), key);
    });
    $('#builder-version').textContent = product.name;

    const editions = $('#editions');
    editions.replaceChildren();
    Object.keys(product.editions).forEach((key) => {
      radio(editions, 'edition', key, EDITIONS[key].name).setAttribute('aria-checked', String(key === state.edition));
    });

    const apps = $('#apps');
    apps.replaceChildren();
    APPS.forEach(([key, abbreviation, color]) => {
      const inEdition = EDITIONS[state.edition].apps.includes(key);
      const button = toggle(apps, key, abbreviation, color, key);
      button.disabled = !inEdition || suite;
      button.setAttribute('aria-pressed', String(inEdition && (suite || state.apps.includes(key))));
    });
    $('#apps-note').textContent = suite
      ? `${product.name} se instala entero: Microsoft no deja elegir aplicaciones por esa vía.`
      : `Lo que no marques se excluye.${state.edition === 'Standard' ? ' Con Standard, Access no viene.' : ''}`;

    $('#language').value = state.language;
    $$('#bits [role="radio"]').forEach((button) => button.setAttribute('aria-checked', String(button.dataset.bits === state.bits)));

    const addOns = $('#addons');
    addOns.replaceChildren();
    ADD_ONS.forEach((addOn) => {
      const button = toggle(addOns, addOn.key, addOn.abbreviation, addOn.color, addOn.name);
      button.disabled = !addOn.ids[state.version];
      button.setAttribute('aria-pressed', String(state.addOns.includes(addOn.key)));
    });
    $('#addons-note').textContent = suite
      ? `${product.name} no admite complementos por esta vía.`
      : `Van en el mismo archivo y suman unos ${numberEs.format(ADD_ON_WEIGHT_GB)} GB cada uno.`;

    const text = suite ? c2rUrl() : xml();
    $('#sheet-name').textContent = suite ? 'c2rsetup' : 'configuration.xml';
    $('#sheet-hint').textContent = suite ? 'lo que OfficeGo le pide a Microsoft' : 'lo que recibirá Microsoft';
    $('#xml-code').classList.toggle('is-url', suite);
    $('#xml-code').dataset.copy = text;
    write(text, suite);
    const names = [...state.apps, ...addOnIds().map((addOn) => addOn.name)];
    const size = numberEs.format(product.weight + addOnIds().length * ADD_ON_WEIGHT_GB);
    $('#sheet-foot').textContent = suite
      ? `${product.name} ${EDITIONS[state.edition].name} completo. Unos ${size} GB desde Microsoft.`
      : `${product.name} ${EDITIONS[state.edition].name} con ${listEs.format(names)}. Unos ${size} GB desde Microsoft.`;
  };

  $('#windows').addEventListener('click', (event) => {
    const button = event.target.closest('[data-build]');
    if (!button) return;
    state.build = Number(button.dataset.build);
    state.version = recommended();
    render();
  });
  $('#versions').addEventListener('click', (event) => {
    const button = event.target.closest('[data-version]');
    if (!button || button.disabled) return;
    state.version = button.dataset.version;
    render();
  });
  $('#editions').addEventListener('click', (event) => {
    const button = event.target.closest('[data-edition]');
    if (!button) return;
    state.edition = button.dataset.edition;
    render();
  });
  $('#apps').addEventListener('click', (event) => {
    const button = event.target.closest('[data-key]');
    if (!button || button.disabled) return;
    const key = button.dataset.key;
    const next = state.apps.includes(key) ? state.apps.filter((app) => app !== key) : [...state.apps, key];
    if (next.length) state.apps = next;
    render();
  });
  $('#addons').addEventListener('click', (event) => {
    const button = event.target.closest('[data-key]');
    if (!button || button.disabled) return;
    const key = button.dataset.key;
    state.addOns = state.addOns.includes(key) ? state.addOns.filter((addOn) => addOn !== key) : [...state.addOns, key];
    render();
  });
  $('#language').addEventListener('change', (event) => { state.language = event.target.value; render(); });
  $('#bits').addEventListener('click', (event) => {
    const button = event.target.closest('[data-bits]');
    if (!button) return;
    state.bits = button.dataset.bits;
    render();
  });
  $('#copy').addEventListener('click', (event) => copyText($('#xml-code').dataset.copy, event.currentTarget));

  render();
  return {
    useSystem: (system) => {
      if (system.bitness === '32') state.bits = '32';
      if (!system.build) return;
      detected = {
        build: system.build,
        note: system.build === WINDOWS_11 ? 'Marcamos Windows 11 porque es el de este equipo.' : 'Marcamos Windows 10 22H2, el más común. Si el tuyo es anterior, cámbialo.',
      };
      state.build = system.build;
      boardBuild = system.build;
      state.version = recommended();
      render();
    },
  };
})();

(() => {
  const section = $('.builder');
  const cursor = $('#demo-cursor');
  if (!('IntersectionObserver' in window)) return cursor.remove();
  let visible = false;
  let stopped = false;
  let running = false;
  const stop = () => { stopped = true; cursor.classList.remove('is-on'); };
  ['pointerdown', 'keydown'].forEach((type) => section.addEventListener(type, stop, { once: true }));
  const place = (target, [dx, dy] = [0, 0]) => {
    const area = section.getBoundingClientRect();
    const box = target.getBoundingClientRect();
    cursor.style.transform = `translate(${box.left - area.left + box.width * 0.6 + dx}px, ${box.top - area.top + box.height * 0.55 + dy}px)`;
  };
  const enter = (target) => {
    cursor.style.transition = 'none';
    place(target, DEMO_ENTRY);
    cursor.getBoundingClientRect();
    cursor.style.transition = '';
    cursor.classList.add('is-on');
  };
  const onScreen = (target) => {
    const box = target.getBoundingClientRect();
    return box.top > 0 && box.bottom < innerHeight;
  };
  const loop = async () => {
    running = true;
    for (let step = 0; visible && !stopped; step = (step + 1) % DEMO_STEPS.length) {
      const target = $(DEMO_STEPS[step]);
      if (!target || target.disabled || !onScreen(target)) { await wait(DEMO_REST_MS); continue; }
      if (!cursor.classList.contains('is-on')) enter(target);
      place(target);
      await wait(DEMO_MOVE_MS);
      if (stopped || !visible) break;
      cursor.classList.add('is-press');
      await wait(DEMO_PRESS_MS);
      cursor.classList.remove('is-press');
      $(DEMO_STEPS[step])?.click();
      await wait(DEMO_REST_MS);
    }
    cursor.classList.remove('is-on');
    running = false;
  };
  new IntersectionObserver(([entry]) => {
    visible = entry.isIntersecting;
    if (visible && !stopped && !running) loop();
  }, { threshold: 0.45 }).observe(section);
})();

(() => {
  $$('[data-copy-text]').forEach((button) => {
    const label = $('[data-copy-state]', button.closest('li'));
    button.addEventListener('click', () => copyText(button.dataset.copyText, label));
  });

  fetch(RELEASE_API)
    .then((response) => (response.ok ? response.json() : Promise.reject(response.status)))
    .then((release) => {
      release.assets.forEach((asset) => $$(`[data-size="${asset.name}"]`).forEach((el) => (el.textContent = formatSize(asset.size))));
      $$('[data-release]').forEach((el) => (el.textContent = release.tag_name.replace(/^v/, '')));
      $$('[data-release-date]').forEach((el) => (el.textContent = dateEs.format(new Date(release.published_at))));
    })
    .catch(() => {});

  detectSystem().then((system) => {
    const send = $('#send-link');
    if (system.windows && !system.old) {
      builder.useSystem(system);
      const yours = system.bitness ? `${system.name} de ${system.bitness} bits` : system.name;
      $('#get-title').textContent = `Descárgalo para ${system.name}`;
      $('#get-os').textContent = `Tu sistema es ${yours}: para él, el instalador. Pesa poco, Office lo baja después de Microsoft.`;
      return;
    }
    $$('[data-download]').forEach((link) => (link.href = '#descargas'));
    $$('[data-download-label]').forEach((link) => (link.textContent = 'Ver descargas'));
    if (system.old) {
      $('#get-title').textContent = 'Pide Windows 10 u 11';
      $('#get-os').textContent = `Tu sistema es ${system.name} y OfficeGo no corre en él. Si lo vas a usar en otro equipo, estas son las descargas.`;
      return;
    }
    $('#get-title').textContent = 'OfficeGo es para Windows';
    $('#get-os').textContent = `${system.name ? `Tu sistema es ${system.name}: desde` : 'Desde'} aquí no se puede usar. Ábrelo en tu PC con Windows 10 u 11, o mándate el enlace.`;
    send.hidden = false;
    send.addEventListener('click', () => {
      const url = location.href.split('#')[0];
      if (navigator.share) return navigator.share({ title: document.title, url }).catch(() => {});
      copyText(url, send, send.textContent);
    });
  });
})();
