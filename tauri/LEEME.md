# OfficeGo · versión Tauri (2.0)

La misma herramienta que la versión 1.x, pero con la interfaz web en lugar de
Windows Forms. Las pantallas son literalmente los diseños originales: no una
aproximación en controles nativos, sino el propio HTML.

## Cómo está montado

```
tauri/
├── ui/                     la interfaz. HTML + CSS + JS, sin frameworks
│   ├── index.html          el esqueleto
│   ├── estilo.css          sale del mismo CSS que generó los mockups
│   └── app.js              pinta las pantallas y habla con Rust
└── src-tauri/
    ├── src/main.rs         capa fina: llama a PowerShell y reenvía lo que dice
    ├── motor-api.ps1       traduce acciones a JSON
    ├── motor/              copia de src/*.ps1 de la raíz (el mismo motor)
    └── tauri.conf.json
```

**El motor no se duplica en Rust.** `main.rs` deja el PowerShell en `%TEMP%` y lo
invoca; las tareas largas escriben una línea JSON por evento y Rust las reenvía a la
interfaz, así la barra de progreso se mueve de verdad en lugar de fingir.

Un arreglo en `src/2-motor.ps1` de la raíz sirve para las dos versiones. Antes de
compilar hay que copiarlo:

```bash
cp src/1-catalogo.ps1 src/2-motor.ps1 src/2b-recomendacion.ps1 tauri/src-tauri/motor/
```

## Compilar

No hace falta hacerlo a mano: el workflow `.github/workflows/compilar.yml` lo hace
en un runner de Windows al etiquetar una versión.

Para compilar en local, en Windows:

```bash
cargo install tauri-cli --version "^2" --locked
cd tauri && cargo tauri build
```

Sale un `.exe` portable y un instalador NSIS en
`src-tauri/target/release/`.

## Requisito que la versión 1.x no tiene

**WebView2.** Viene de serie en Windows 11 y llegó a Windows 10 por Windows Update
hacia 2021. Un Windows 10 sin actualizar desde entonces no lo tiene y habría que
instalarlo aparte.

Por eso las dos versiones conviven: para el portátil viejo del laboratorio está la
1.x, que funciona con lo que Windows ya trae.
