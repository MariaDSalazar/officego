// =====================================================================
//  OfficeGo · interfaz
//  Pinta las pantallas y le pide el trabajo al motor a traves de Rust.
// =====================================================================
const { invoke } = window.__TAURI__.core;
const { listen }  = window.__TAURI__.event;

const $  = (s, r = document) => r.querySelector(s);
const esc = t => String(t ?? '').replace(/[&<>"]/g, c =>
  ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

// ─────────────────────────────────────────────────────────────── estado
const S = {
  pantalla: 'Inicio',
  equipo: null, grafica: null, office: null, rec: null, cat: null, licencia: null,
  sel: { producto: '2021', edicion: 'ProPlus', idioma: 'es-es', bits: '64',
         apps: ['Word', 'Excel', 'PowerPoint'], complementos: [] },
  ocupado: false,
};

const PANTALLAS = ['Inicio', 'Instalar', 'Activar', 'Equipo', 'Herramientas', 'Ayuda'];
const ICONOS = {
  Inicio: '<path d="M3 11l9-7 9 7v9a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z" fill="none" stroke="C" stroke-width="1.9" stroke-linejoin="round"/>',
  Instalar: '<path d="M12 3v12m0 0l-4.5-4.5M12 15l4.5-4.5M4 18v2.5h16V18" fill="none" stroke="C" stroke-width="2" stroke-linecap="round"/>',
  Activar: '<circle cx="8" cy="12" r="4" fill="none" stroke="C" stroke-width="2"/><path d="M12 12h9m-3 0v3m-3-3v2" stroke="C" stroke-width="2" stroke-linecap="round"/>',
  Equipo: '<rect x="2" y="4" width="20" height="13" rx="2" fill="none" stroke="C" stroke-width="1.9"/><path d="M8 20h8M12 17v3" stroke="C" stroke-width="1.9" stroke-linecap="round"/>',
  Herramientas: '<path d="M14.5 4.5a4 4 0 0 0 5 5L21 8v8a5 5 0 0 1-5 5H8a5 5 0 0 1-5-5V8a5 5 0 0 1 5-5h8z" fill="none" stroke="C" stroke-width="1.8"/>',
  Ayuda: '<circle cx="12" cy="12" r="9" fill="none" stroke="C" stroke-width="2"/><path d="M9.5 9.5a2.6 2.6 0 1 1 3.3 3.4c-.5.3-.8.8-.8 1.4M12 17.2v.1" stroke="C" stroke-width="2" stroke-linecap="round" fill="none"/>',
};

// ───────────────────────────────────────────────────── puente con Rust
async function consultar(accion, datos) {
  const txt = await invoke('consultar', { accion, datos: JSON.stringify(datos || {}) });
  try { return JSON.parse(txt); }
  catch { throw new Error(txt || 'El motor no respondió'); }
}

function progreso(pc, texto) {
  $('#barra').style.width = (pc < 0 ? 100 : pc) + '%';
  $('#barra').style.opacity = pc < 0 ? .5 : 1;
  if (texto !== undefined) $('#estadoProg').textContent = texto;
}

// Las tareas largas informan linea a linea desde PowerShell
listen('motor', e => {
  let m; try { m = JSON.parse(e.payload); } catch { return; }
  if (m.evento === 'progreso') progreso(m.pc, `Descargando: ${m.pc} % · ${m.hecho} / ${m.total} MB`);
  if (m.evento === 'paso')     progreso(m.pc ?? -1, m.texto);
  if (m.evento === 'espera')   progreso(-1, $('#estadoProg').textContent.replace(/ · \d+ s$/, '') +
                                         (m.segundos ? ` · ${m.segundos} s` : ''));
  if (m.evento === 'fin')      finTarea(m);
  const log = $('#log');
  if (log) { log.textContent += (m.texto || m.evento) + '\n'; log.scrollTop = log.scrollHeight; }
});

let alTerminar = null;
function finTarea(m) {
  S.ocupado = false;
  progreso(m.ok ? 100 : 0, m.ok ? 'Listo' : 'La tarea terminó sin completarse');
  if (alTerminar) { const f = alTerminar; alTerminar = null; f(m); }
}

async function tarea(accion, datos, cuandoAcabe) {
  if (S.ocupado) return;
  S.ocupado = true; alTerminar = cuandoAcabe;
  progreso(0, 'Empezando…');
  try { await invoke('ejecutar', { accion, datos: JSON.stringify(datos || {}) }); }
  catch (e) { S.ocupado = false; progreso(0, 'Error: ' + e); }
}

// ────────────────────────────────────────────────────────────── piezas
const aviso = (tipo, html) => `<div class="${tipo}">${html}</div>`;

function tarjetaProducto(p) {
  const on = p.clave === S.sel.producto;
  const clase = { volumen: 'v', retail: 'r' }[p.tipo] || 's';
  return `<div class="card${on ? ' elegida' : ''}" data-prod="${p.clave}">
    <div class="ic" style="background:${p.color}">${p.sigla}</div>
    <b>${esc(p.nombre)}</b><s>${esc(p.sub)}</s>
    <span class="pill ${clase}">${p.tipo}</span></div>`;
}

function chipApp(clave, app, activa, disponible) {
  return `<div class="chip${activa ? ' on' : ''}${disponible ? '' : ' bloq'}"
     ${disponible ? `data-app="${clave}"` : ''}>
     <span class="ic" style="background:${disponible ? app.Color : '#c7ccd1'}">${app.Sigla}</span>
     ${esc(app.Nombre)}${activa ? ' &#10003;' : ''}</div>`;
}

// ────────────────────────────────────────────────────────────── inicio
function pantallaInicio() {
  const r = S.rec, eq = S.equipo;
  const p = S.cat.productos.find(x => x.clave === r.Clave);
  const alerta = ['2016', '2013'].includes(r.Clave);
  const avisos = (r.Avisos || []).map(a =>
    aviso({ error: 'dang', warn: 'warn', info: 'info' }[a.Tipo] || 'info', esc(a.Texto))).join('');

  return `
  <div class="hero">
    <svg class="lg" viewBox="0 0 64 64"><rect width="64" height="64" rx="14" fill="rgba(255,255,255,.2)"/>
      <circle cx="32" cy="32" r="17" fill="none" stroke="#fff" stroke-width="5.5"/>
      <path d="M32 23v14m0 0l-6.5-6.5M32 37l6.5-6.5" stroke="#fff" stroke-width="4.6" fill="none"
            stroke-linecap="round" stroke-linejoin="round"/></svg>
    <div><h1>Instale Office en tres pasos</h1>
      <p>Descarga directa de los servidores de Microsoft, sin páginas de terceros</p></div>
  </div>

  <h3>LO QUE LE CONVIENE A ESTE EQUIPO</h3>
  <div class="rec" ${alerta ? 'style="border-color:#e8a33d"' : ''}>
    <div class="ic" style="background:${p.color}">${p.sigla}</div>
    <div><h4>${esc(p.nombre)} · Professional Plus</h4><p>${esc(r.Motivo)}</p></div>
    <div class="bt2" id="instalarRec" ${alerta ? 'style="background:#e8590c"' : ''}>Instalar esto</div>
  </div>

  <h3 class="mt">CÓMO FUNCIONA</h3>
  <div class="p3">
    <div class="paso"><div class="n">1</div><b>Elija su versión</b>
      <s>Seis versiones desde 2013 hasta Microsoft 365, con sus ediciones</s></div>
    <div class="paso"><div class="n">2</div><b>Marque lo que quiere</b>
      <s>Solo Word y Excel, o la suite entera. Se descarga únicamente eso</s></div>
    <div class="paso"><div class="n">3</div><b>Active al terminar</b>
      <s>Con su clave de producto, o con MAS si no la tiene</s></div>
  </div>

  ${avisos || aviso('ok', `<b>Equipo listo.</b> ${esc(eq.SO)} · ${eq.RamGB} GB de RAM ·
     ${eq.Discos.find(d => d.Sistema)?.LibreGB} GB libres · permisos de administrador.`)}`;
}

// ──────────────────────────────────────────────────────────── instalar
function pantallaInstalar() {
  const cat = S.cat;
  const prod = cat.productos.find(p => p.clave === S.sel.producto);
  const esC2R = prod.via === 'C2R';
  const permitidas = esC2R ? [] : (cat.ediciones[S.sel.edicion]?.Apps || []);

  const apps = Object.entries(cat.aplicaciones).map(([k, a]) =>
    chipApp(k, a, S.sel.apps.includes(k) && permitidas.includes(k), permitidas.includes(k))).join('');

  const comps = cat.complementos.map(c => {
    const hay = c.versiones.includes(prod.clave);
    const on = S.sel.complementos.includes(c.clave) && hay;
    return `<div class="chip${on ? ' on' : ''}${hay ? '' : ' bloq'}" ${hay ? `data-comp="${c.clave}"` : ''}>
      <span class="ic" style="background:${hay ? c.color : '#c7ccd1'}">${c.sigla}</span>
      ${esc(c.nombre)}${on ? ' &#10003;' : ''}</div>`;
  }).join('');

  const peso = (prod.peso + S.sel.complementos.length * 0.6).toFixed(1);

  return `<div class="cols"><div class="izq">
    <h3>ELIGE TU VERSIÓN</h3>
    <div class="cards">${cat.productos.map(tarjetaProducto).join('')}</div>

    <h3 class="mt">EDICIÓN, IDIOMA Y ARQUITECTURA</h3>
    <div class="row">
      <div class="fld"><select class="sel" id="selEd">${prod.ediciones.map(e =>
        `<option value="${e}"${e === S.sel.edicion ? ' selected' : ''}>${esc(cat.ediciones[e].Nombre)}</option>`).join('')}</select></div>
      <div class="fld"><select class="sel" id="selIdioma">${Object.entries(cat.idiomas).map(([k, v]) =>
        `<option value="${k}"${k === S.sel.idioma ? ' selected' : ''}>${esc(v)}</option>`).join('')}</select></div>
      <div class="fld" style="flex:.7"><select class="sel" id="selBits">
        <option value="64"${S.sel.bits === '64' ? ' selected' : ''}>64 bits</option>
        <option value="32"${S.sel.bits === '32' ? ' selected' : ''}>32 bits</option></select></div>
    </div>

    <h3 class="mt">APLICACIONES</h3>
    ${esC2R ? aviso('warn', `Office ${prod.clave} se descarga entero: Microsoft no permite
        elegir aplicaciones por esa vía.`) : `<div class="chips">${apps}</div>`}

    <h3 class="mt">COMPLEMENTOS</h3>
    <div class="chips">${comps}</div>
  </div>

  <div class="der"><h3>RESUMEN</h3><div class="sum">
    <div class="peso"><b>${peso} GB</b><s>tamaño de la descarga</s></div>
    <table class="t">
      <tr><td>Producto</td><td>${esc(prod.nombre)}</td></tr>
      <tr><td>Edición</td><td>${esc(S.cat.ediciones[S.sel.edicion].Nombre)}</td></tr>
      <tr><td>Aplicaciones</td><td>${esC2R ? 'todas' : `${S.sel.apps.length} de ${permitidas.length}`}</td></tr>
      <tr><td>Canal</td><td>${esc(prod.canal || 'c2rsetup')}</td></tr>
      <tr><td>Origen</td><td>Microsoft CDN</td></tr>
    </table>
    ${aviso('info', 'Al cambiar de edición se ajustan solas las aplicaciones que esa edición incluye.')}
    <div class="log oculto" id="log"></div>
  </div></div></div>`;
}

// ───────────────────────────────────────────────────────────── activar
function pantallaActivar() {
  const lic = S.licencia, activo = lic && lic.Activado;
  return `<h3>ESTADO DE LA LICENCIA</h3>
  <div class="big"><div class="ic" style="background:${activo ? '#137333' : '#c5221f'}">${activo ? '&#10003;' : '!'}</div>
    <div><h4>${activo ? 'Office está activado' : (S.office ? 'Office no está activado' : 'No hay Office instalado')}</h4>
      <p>${esc(lic?.Nombre || (S.office ? 'Sin licencia válida' : 'Instálelo desde la pantalla Instalar'))}</p></div>
    <div class="go" id="recomprobar">Comprobar</div></div>

  <h3 class="mt">CÓMO ACTIVAR</h3>
  <div class="big"><div class="ic" style="background:#0b57d0">K</div>
    <div><h4>Clave de producto</h4><p>Si tiene una clave de 25 caracteres, es lo correcto y lo legal</p></div>
    <div class="go" id="usarClave">Usar</div></div>
  <div class="big"><div class="ic" style="background:#7719aa">M</div>
    <div><h4>MAS · massgrave.dev</h4><p>Herramienta externa que OfficeGo ejecuta sin abrir su menú</p></div>
    <div class="go" id="usarMAS">Usar</div></div>

  ${S.equipo.Defender ? aviso('warn', `<b>Defender está encendido.</b> Marca toda herramienta de
     activación, por diseño, y puede interrumpir a MAS a mitad de camino.`) : ''}
  ${aviso('info', `Activar productos sin licencia va contra los términos de Microsoft.
     Esta opción se ofrece a título informativo.`)}
  <div class="log oculto" id="log"></div>`;
}

// ────────────────────────────────────────────────────────────── equipo
function tarjetaHW(t, sub, sigla, color, filas, barra) {
  return `<div class="hw"><div class="top">
    <div class="ic" style="background:${color}">${sigla}</div>
    <div><h4>${esc(t)}</h4><div class="sub">${esc(sub)}</div></div></div>
    ${filas.map(([a, b]) => `<div class="dato">${esc(a)} <b>${esc(b)}</b></div>`).join('')}
    ${barra ? `<div class="uso"><i style="width:${barra[0]}%;background:${barra[1]}"></i></div>
               <div class="mini">${esc(barra[2])}</div>` : ''}</div>`;
}

function pantallaEquipo() {
  const e = S.equipo, g = S.grafica, r = S.rec;
  const p = S.cat.productos.find(x => x.clave === r.Clave);
  const discos = e.Discos.map(d => tarjetaHW(`Disco ${d.Letra}`,
    d.Sistema ? 'unidad del sistema' : 'datos', d.Letra, '#5f6368',
    [['Capacidad', d.TotalGB + ' GB']],
    [d.UsadoPc, d.LibreGB < 5 ? '#c5221f' : '#0b57d0', d.LibreGB + ' GB libres'])).join('');

  return `<h3>LO QUE LE CONVIENE A ESTE EQUIPO</h3>
  <div class="rec" style="margin-bottom:14px">
    <div class="ic" style="background:${p.color}">${p.sigla}</div>
    <div><h4>${esc(p.nombre)}</h4><p>${esc(r.Motivo)}</p></div>
    <div class="bt2" id="instalarRec">Instalar</div></div>

  <h3>CARACTERÍSTICAS</h3>
  <div class="g2">
    ${tarjetaHW('Sistema operativo', e.SO, '&#8862;', '#0b57d0',
       [['Compilación', e.Build], ['Arquitectura', e.Arquitectura], ['PowerShell', e.PowerShell]])}
    ${tarjetaHW('Procesador', e.CPU, 'CPU', '#c5221f',
       [['Frecuencia', e.CPUGhz + ' GHz'], ['Núcleos / hilos', `${e.Nucleos} / ${e.Hilos}`]],
       [e.CPUUso, '#c5221f', `Uso actual ${e.CPUUso} %`])}
    ${tarjetaHW('Memoria RAM', `${e.RamGB} GB ${e.RamTipo}`, 'RAM', '#137333',
       [['Módulos', String(e.RamModulos)], ['Disponible', e.RamLibreGB + ' GB']],
       [e.RamUsoPc, '#137333', `${(e.RamGB - e.RamLibreGB).toFixed(1)} GB en uso`])}
    ${tarjetaHW('Tarjeta gráfica', e.GPU, g.sigla, g.color,
       [['Marca', g.marca], ['Resolución', e.Resolucion],
        ['Aceleración', g.antigua ? 'no recomendada' : 'compatible']])}
    ${discos}
  </div>

  <h3 class="mt">A TENER EN CUENTA</h3>
  ${(r.Avisos || []).map(a => aviso({ error: 'dang', warn: 'warn', info: 'info' }[a.Tipo] || 'info',
     esc(a.Texto))).join('') || aviso('ok', 'El equipo cumple de sobra con lo que pide Office.')}`;
}

// ───────────────────────────────────────────────────────── herramientas
function pantallaHerramientas() {
  const fila = (id, sigla, color, t, d, peligro) =>
    `<div class="big"${peligro ? ' style="border-color:#f5c9c6"' : ''}>
      <div class="ic" style="background:${color}">${sigla}</div>
      <div><h4>${t}</h4><p>${d}</p></div>
      <div class="go" id="${id}"${peligro ? ' style="color:#c5221f;border-color:#f5c9c6;background:#fce8e6"' : ''}>
        ${peligro ? 'Desinstalar' : 'Ejecutar'}</div></div>`;

  return `<h3>MANTENIMIENTO</h3>
  ${fila('descargarOffline', 'D', '#137333', 'Crear instalador sin conexión',
         'Descarga los archivos a una carpeta para instalar en otros equipos')}
  ${fila('verXml', 'X', '#0b57d0', 'Ver el configuration.xml',
         'Muestra exactamente lo que se le va a pedir a Microsoft')}
  <h3 class="mt">DESINSTALAR</h3>
  ${fila('desinstalar', '&#10005;', '#c5221f', 'Quitar Office del equipo',
         'Se eliminan los programas. <b>Los documentos no se borran.</b>', true)}
  ${aviso('dang', 'Desinstalar pide confirmación escrita: un clic accidental no basta.')}
  <div class="log oculto" id="log"></div>`;
}

// ─────────────────────────────────────────────────────────────── ayuda
function pantallaAyuda() {
  const enlace = (id, sigla, color, t, u) =>
    `<div class="enl" data-url="${u}"><div class="ic" style="background:${color}">${sigla}</div>
      <div><b>${t}</b><s>${u.replace('https://', '')}</s></div><div class="ir">Abrir &#8594;</div></div>`;
  const faq = (n, q, a) => `<div class="faq"><div class="q"><span class="n">${n}</span>${q}</div>
      <div class="a">${a}</div></div>`;

  return `<div class="hero" style="padding:20px 24px">
    <svg class="lg" style="width:54px;height:54px" viewBox="0 0 64 64">
      <rect width="64" height="64" rx="14" fill="rgba(255,255,255,.2)"/>
      <circle cx="32" cy="32" r="17" fill="none" stroke="#fff" stroke-width="5.5"/>
      <path d="M32 23v14m0 0l-6.5-6.5M32 37l6.5-6.5" stroke="#fff" stroke-width="4.6" fill="none"
            stroke-linecap="round" stroke-linejoin="round"/></svg>
    <div><h1 style="font-size:21px">OfficeGo 2.0</h1>
      <p>Instalador y activador de Microsoft Office para Windows 10 y 11</p></div></div>

  <h3>ENLACES</h3>
  ${enlace('e1', '&lt;/&gt;', '#24292f', 'Código de OfficeGo', 'https://github.com/MariaDSalazar/officego')}
  ${enlace('e2', 'M', '#7719aa', 'MAS · Microsoft Activation Scripts', 'https://github.com/massgravel/Microsoft-Activation-Scripts')}
  ${enlace('e3', '?', '#0b57d0', 'Guía de problemas de MAS', 'https://massgrave.dev/troubleshoot')}

  <h3 class="mt">PROBLEMAS FRECUENTES</h3>
  ${faq(1, 'La instalación no arranca', 'Compruebe que OfficeGo se abrió con permisos de administrador. Sin ellos Windows no deja instalar nada.')}
  ${faq(2, 'La descarga falla nada más empezar', 'Un Windows sin actualizar usa un protocolo de seguridad antiguo. OfficeGo fuerza TLS 1.2, así que esto solo aparece en equipos muy desactualizados.')}
  ${faq(3, 'El antivirus bloquea la activación', 'Defender marca todas las herramientas de activación, por diseño. Pause la protección en tiempo real, active, y <b>vuelva a encenderla</b>.')}
  ${faq(4, 'Parece congelado durante la instalación', 'La barra puede quedarse quieta varios minutos mientras Microsoft descomprime. Si el contador de abajo avanza, está trabajando.')}

  <h3 class="mt">LICENCIA</h3>
  <div class="lic">
    <div class="c"><b>Open Source</b> · licencia MIT</div>
    <div class="c">Sin telemetría</div>
    <div class="c">Sin publicidad</div>
  </div>`;
}

// ────────────────────────────────────────────────────────────── pintar
const BOTONES = {
  Inicio: [['Empezar', 1, () => ir('Instalar')], ['Ver el equipo', 0, () => ir('Equipo')]],
  Instalar: [['Instalar Office', 1, instalar], ['Solo descargar', 0, () => tarea('descargar', S.sel)]],
  Activar: [['Comprobar estado', 0, async () => { await cargarLicencia(); pintar(); }]],
  Equipo: [['Actualizar', 0, async () => { await cargarEquipo(); pintar(); }]],
  Herramientas: [], Ayuda: [],
};

function pintar() {
  $('#menu').innerHTML = PANTALLAS.map(p => {
    const on = p === S.pantalla;
    return `<div class="nav${on ? ' on' : ''}" data-ir="${p}">
      <svg width="17" height="17" viewBox="0 0 24 24">
        ${ICONOS[p].replaceAll('"C"', on ? '"#0b57d0"' : '"#5f6368"')}</svg> ${p}</div>`;
  }).join('');

  const render = { Inicio: pantallaInicio, Instalar: pantallaInstalar, Activar: pantallaActivar,
                   Equipo: pantallaEquipo, Herramientas: pantallaHerramientas, Ayuda: pantallaAyuda };
  $('#pantalla').innerHTML = render[S.pantalla]();
  $('#pantalla').scrollTop = 0;

  $('#botones').innerHTML = (BOTONES[S.pantalla] || []).map((b, i) =>
    `<button class="btn${b[1] ? '' : ' gh'}" data-btn="${i}">${b[0]}</button>`).join('');

  pintarBarraEstado();
}

function pintarBarraEstado() {
  const e = S.equipo; if (!e) return;
  const sis = e.Discos.find(d => d.Sistema) || {};
  const punto = (txt, col) => `<span class="est"><span class="pt ${col}"></span> ${esc(txt)}</span>`;
  $('#barraEstado').innerHTML =
    punto(`${e.SO} · ${String(e.Build).split('.')[0]}`, e.Compatible ? 'g' : 'r') +
    punto(e.Admin ? 'Administrador' : 'Sin permisos', e.Admin ? 'g' : 'r') +
    punto(`${sis.LibreGB} GB libres`, sis.LibreGB >= 5 ? 'g' : 'r') +
    punto(e.Defender ? 'Defender activo' : 'Defender apagado', 'a') +
    punto(S.office ? 'Office instalado' : 'Office no instalado', 'a') +
    `<span class="der2">OfficeGo 2.0</span>`;
}

function ir(p) { S.pantalla = p; pintar(); }

// ───────────────────────────────────────────────────────────── acciones
async function instalar() {
  const prod = S.cat.productos.find(p => p.clave === S.sel.producto);
  const apps = prod.via === 'C2R' ? 'la suite completa' : S.sel.apps.join(', ');
  if (!confirm(`Se va a instalar:\n\n  ${prod.nombre}\n  ${apps}\n\n` +
               `Tarda entre 10 y 30 minutos. Cierre Word, Excel y PowerPoint antes de seguir.\n\n¿Continuar?`)) return;
  $('#log')?.classList.remove('oculto');
  tarea('instalar', S.sel, async m => {
    if (m.ok) { await cargarEquipo(); alert('Office quedó instalado.'); ir('Activar'); }
    else alert('La instalación no se completó. Revise el registro.');
  });
}

async function activarConMAS() {
  if (!confirm('MAS es una herramienta externa que se ejecutará en segundo plano.\n\n' +
    'Windows Defender la detecta SIEMPRE, por diseño. Si la protección en tiempo real\n' +
    'está encendida puede interrumpirla.\n\n' +
    'Activar productos sin licencia va contra los términos de Microsoft.\n\n¿Continuar?')) return;
  $('#log')?.classList.remove('oculto');
  tarea('activar', {}, async m => {
    await cargarLicencia(); pintar();
    alert(m.ok ? 'Office quedó activado.'
               : 'MAS terminó pero Office sigue sin aparecer activado. Lo más probable es que Defender lo interrumpiera.');
  });
}

// clics: uno solo para toda la pantalla, en vez de mil escuchadores
document.addEventListener('click', async ev => {
  const t = ev.target.closest('[data-ir],[data-prod],[data-app],[data-comp],[data-btn],[data-url],#instalarRec,#usarMAS,#usarClave,#recomprobar,#desinstalar,#descargarOffline,#verXml');
  if (!t) return;

  if (t.dataset.ir)   return ir(t.dataset.ir);
  if (t.dataset.url)  return invoke('abrir_enlace', { url: t.dataset.url });
  if (t.dataset.btn !== undefined) return BOTONES[S.pantalla][+t.dataset.btn][2]();

  if (t.dataset.prod) {
    S.sel.producto = t.dataset.prod;
    const p = S.cat.productos.find(x => x.clave === t.dataset.prod);
    if (!p.ediciones.includes(S.sel.edicion)) S.sel.edicion = p.ediciones[0];
    ajustarApps(); return pintar();
  }
  if (t.dataset.app) {
    const a = t.dataset.app;
    S.sel.apps = S.sel.apps.includes(a) ? S.sel.apps.filter(x => x !== a) : [...S.sel.apps, a];
    return pintar();
  }
  if (t.dataset.comp) {
    const c = t.dataset.comp;
    S.sel.complementos = S.sel.complementos.includes(c)
      ? S.sel.complementos.filter(x => x !== c) : [...S.sel.complementos, c];
    return pintar();
  }

  switch (t.id) {
    case 'instalarRec':
      S.sel.producto = S.rec.Clave;
      S.sel.edicion = S.cat.productos.find(p => p.clave === S.rec.Clave).ediciones[0];
      ajustarApps(); return ir('Instalar');
    case 'usarMAS':     return activarConMAS();
    case 'usarClave':   return alert('Abra Word y vaya a Archivo → Cuenta → Cambiar clave de producto.');
    case 'recomprobar': await cargarLicencia(); return pintar();
    case 'desinstalar':
      if (prompt('Escriba BORRAR para confirmar que quiere quitar Office:') !== 'BORRAR') return;
      $('#log')?.classList.remove('oculto');
      return tarea('desinstalar', {}, async m => {
        await cargarEquipo(); pintar();
        alert(m.ok ? 'Office se quitó del equipo.' : 'La desinstalación no terminó bien.');
      });
    case 'descargarOffline': return alert('Elija la carpeta en la ventana que va a aparecer.');
    case 'verXml': {
      const r = await consultar('preparar-xml', S.sel);
      return alert(r.ok ? r.contenido : r.error);
    }
  }
});

document.addEventListener('change', ev => {
  const id = ev.target.id;
  if (id === 'selEd')     { S.sel.edicion = ev.target.value; ajustarApps(); pintar(); }
  if (id === 'selIdioma') { S.sel.idioma  = ev.target.value; }
  if (id === 'selBits')   { S.sel.bits    = ev.target.value; }
});

function ajustarApps() {
  const prod = S.cat.productos.find(p => p.clave === S.sel.producto);
  if (prod.via === 'C2R') return;
  const ok = S.cat.ediciones[S.sel.edicion]?.Apps || [];
  S.sel.apps = S.sel.apps.filter(a => ok.includes(a));
  if (!S.sel.apps.length) S.sel.apps = ok.slice(0, 3);
  S.sel.complementos = S.sel.complementos.filter(c =>
    S.cat.complementos.find(x => x.clave === c)?.versiones.includes(prod.clave));
}

// ───────────────────────────────────────────────────────────── arranque
async function cargarEquipo() {
  const r = await consultar('equipo');
  if (!r.ok) throw new Error(r.error);
  S.equipo = r.equipo; S.grafica = r.grafica; S.office = r.office;
  S.rec = (await consultar('recomendar')).recomendacion;
}
async function cargarLicencia() {
  try { S.licencia = (await consultar('licencia')).licencia; } catch { S.licencia = null; }
}

(async () => {
  try {
    S.cat = await consultar('catalogo');
    await cargarEquipo();
    await cargarLicencia();
    S.sel.bits = S.equipo.Bits;
    S.sel.producto = S.rec.Clave;
    S.sel.edicion = S.cat.productos.find(p => p.clave === S.rec.Clave).ediciones[0];
    ajustarApps();
    pintar();
    if (!S.equipo.Admin) {
      alert('OfficeGo se abrió sin permisos de administrador.\n\n' +
            'Puede mirar las pantallas, pero no podrá instalar ni activar nada.\n\n' +
            'Cierre y ábralo con clic derecho → Ejecutar como administrador.');
    }
  } catch (e) {
    $('#pantalla').innerHTML = `<div class="dang" style="margin:40px">
      <b>No se pudo consultar el equipo.</b><br>${esc(e.message || e)}</div>`;
  }
})();
