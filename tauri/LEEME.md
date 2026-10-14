# OfficeGo · versión de escritorio

La misma herramienta que la versión 1.x, con una interfaz en Svelte 5 sobre Tauri 2.
**El motor no se duplica:** Rust deja en `%TEMP%\OfficeGo-motor` los mismos
`src/*.ps1` que usa la 1.x (los toma con `include_str!` de la raíz del repositorio) y
los invoca a través de un puente. Un arreglo en `src/2-motor.ps1` vale para las dos.

## Cómo está montado

| Ruta | Qué lleva |
|---|---|
| `src-tauri/motor-api.ps1` | El puente: recibe la petición en la variable `OFFICEGO_PAYLOAD` (JSON, sin líos de comillas) y responde en UTF-8 con los nombres que espera Rust. Consultas: una línea `{"data":…}` o `{"error":…}`. Tareas: una línea por evento y al final `done` o `failed`. Lo vacío no se envía: en PowerShell 5.1 un `$(if …)` sin salida sale en el JSON como `{}` y no como `null`. Instalar por el ODT va en dos tiempos, `/download` a una carpeta con el avance medido en el disco y `/configure` desde ella. |
| `src-tauri/src/engine.rs` | Escribe el motor una vez por ejecución, llama a Windows PowerShell por su ruta completa y tipa cada respuesta. Una tarea siempre termina: si PowerShell muere a mitad, devuelve `engineStopped` con el final de su error, y si la línea final no encaja, `engineAnswer` con lo que llegó. `stop` corta la tarea en curso con todo lo que abrió y la da por `stopped`. |
| `src-tauri/src/model.rs` | Los tipos que ve la interfaz. `cargo test` los exporta con ts-rs a `src/lib/generated/`. |
| `src-tauri/src/errors.rs` | `AppError`: cada fallo tiene un código que la interfaz pinta como `errors:<código>`. |
| `src-tauri/src/updates.rs` | La última release de GitHub, la descarga del instalador y su comprobación con el SHA-256 que publica GitHub. |
| `src-tauri/src/commands.rs` | Comandos de una línea que delegan en lo anterior, más reiniciar con permisos y abrir carpetas. |
| `src/lib/services/` | El único sitio que llama a `invoke`: una función tipada por comando. |
| `src/lib/app.svelte.ts` | El estado de la interfaz y lo que hace cada botón; las pantallas lo importan. |
| `src/lib/selection.ts` | Las reglas de la selección (qué apps trae cada edición, complementos por versión), las mismas que `Ajustar-Seleccion` en la 1.x. |
| `src/lib/screens/`, `src/lib/ui/` | Las seis pantallas, montadas con los componentes del catálogo de `ui/`. |
| `locales/<idioma>/<espacio>.json` | Todo el texto que se ve. Español es la base; inglés va igual. |
| `design/tokens.json` | Colores, espacios, letra, bordes y tamaños. `theme.ts` los publica como variables CSS; un valor entre llaves (`{color.accent}`) apunta a otro. |

## Cómo se amplía

- **Texto nuevo:** la clave en todos los idiomas de `locales/` (la prueba `every_language_has_the_base_keys` falla si falta en uno). La lógica devuelve claves o códigos; las pantallas pintan `t(clave)`.
- **Idioma nuevo:** una carpeta más en `locales/` con los mismos archivos. Sin tocar código.
- **Código nuevo del motor** (un motivo, un paso, un error): la variante en Rust, `cargo test` para regenerar los tipos y su texto en `locales/es`. `src/lib/i18n/coverage.ts` hace fallar `pnpm check` si un código no tiene texto.
- **Acción nueva:** el caso en `motor-api.ps1`, la variante en `Query` o `Task` de `engine.rs` (la prueba `the_bridge_answers_every_action` comprueba que el puente la atiende) y su función en `src/lib/services/`.
- **Comando nuevo:** la función en `commands.rs`, registrada en `main.rs`, y su envoltorio en `src/lib/services/` (la prueba `every_command_the_ui_invokes_is_registered` comprueba los nombres).
- **Color o tamaño nuevo:** en `design/tokens.json`, y `var(--grupo-nombre)` en el CSS.

## Reglas

- La lógica de Office vive en `src/*.ps1`. Rust y Svelte no deciden nada sobre versiones, ediciones ni requisitos: lo preguntan.
- El código va en inglés y sin comentarios, salvo docstrings de una línea para lo que el código no puede decir. Los textos, en `locales/`.
- Nada de colores ni tamaños sueltos en los componentes: todo sale de los tokens. Los iconos, de Lucide.
- Ninguna tarea arranca sin que el usuario la confirme. Desinstalar pide escribir la palabra.

## Comandos

```powershell
pnpm install
pnpm tauri dev
pnpm lint
pnpm check
pnpm test
pnpm build
cargo fmt --manifest-path src-tauri/Cargo.toml --check
cargo clippy --manifest-path src-tauri/Cargo.toml --all-targets -- -D warnings
cargo test --manifest-path src-tauri/Cargo.toml
cargo test --manifest-path src-tauri/Cargo.toml -- --ignored   # el motor de verdad, en este Windows
pnpm tauri build --debug --no-bundle                              # prueba rápida sin instalador
pnpm tauri build                                                  # instalador NSIS
```

`cargo` necesita que exista `dist/` (Tauri la incrusta): la primera vez, `pnpm build`.

## Publicar una versión

Versionado semántico: PATCH solo arregla, MINOR añade funciones, MAJOR cambia algo que
el usuario tiene que saber.

1. Subir `version` en `src-tauri/Cargo.toml` (la app, el instalador y la pantalla Ayuda la leen de ahí) y, si cambió la 1.x, `$script:VERSION` en `src/0-parametros.ps1` y `./build.sh`.
2. Reemplazar `CHANGELOG.md` de la raíz con lo cambiado desde la última versión: son las notas del release.
3. En un Windows 10 u 11 de escritorio, `cargo test --manifest-path src-tauri/Cargo.toml -- --ignored`: corre el motor de verdad,
   que el CI no prueba porque su runner es un Windows Server virtual.
4. Commit, push y `git tag v2.4.0 && git push origin v2.4.0`. El CI solo corre con la etiqueta: nada se compila en cada push.

`.github/workflows/compilar.yml` comprueba que la etiqueta coincide con la versión,
corre todas las comprobaciones de las dos versiones y publica `OfficeGo.exe`,
`OfficeGo.ps1`, `OfficeGo.cmd`, `OfficeGo-setup.exe` y `OfficeGo-portable.exe`. La app
instalada busca en la última release el archivo que acaba en `-setup.exe`, lo baja,
comprueba su SHA-256 y se instala encima con `/P /UPDATE /R`; la portable abre la
página de la release.

## Requisito que la 1.x no tiene

**WebView2.** Viene de serie en Windows 11 y llegó a Windows 10 por Windows Update
hacia 2021. Para el portátil viejo del laboratorio está la 1.x, que funciona con lo
que Windows ya trae.
