<div align="center">
  <img src="assets/officego.png" alt="OfficeGo" width="120">
  <h1>OfficeGo</h1>
  <p>
    <strong>Instalador y activador de Microsoft Office, directo desde Microsoft.</strong><br>
    Sin páginas de terceros, sin archivos de dudosa procedencia, sin instalar nada previo.
    Un solo archivo que se abre y funciona.
  </p>
  <p>
    <img src="https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white" alt="PowerShell">
    <img src="https://img.shields.io/badge/Windows_Forms-interfaz_nativa-0078D6?logo=windows&logoColor=white" alt="WinForms">
    <img src="https://img.shields.io/badge/Windows-10_%7C_11-0078D6?logo=windows11&logoColor=white" alt="Windows 10/11">
    <img src="https://img.shields.io/badge/Office-365_·_2024_·_2021_·_2019_·_2016_·_2013-D83B01?logo=microsoftoffice&logoColor=white" alt="Versiones">
    <img src="https://img.shields.io/badge/Portable-un_solo_archivo-0B57D0" alt="portable">
    <img src="https://img.shields.io/badge/Sin_dependencias-0_instalaciones-16A34A" alt="sin dependencias">
    <img src="https://img.shields.io/badge/Licencia-MIT-6366F1" alt="MIT">
    <img src="https://img.shields.io/badge/versión-1.6_·_2.4-0B57D0" alt="versiones">
    <img src="https://img.shields.io/badge/Tauri-2-24C8DB?logo=tauri&logoColor=white" alt="Tauri">
  </p>
  <p>
    <a href="https://github.com/MariaDSalazar/officego/releases/latest/download/OfficeGo.exe">
      <img src="https://img.shields.io/badge/Descargar-OfficeGo.exe-16A34A?style=for-the-badge&logo=windows&logoColor=white" alt="Descargar OfficeGo.exe"></a>
    <a href="https://github.com/MariaDSalazar/officego/releases/latest">
      <img src="https://img.shields.io/badge/Instalador-versión_de_escritorio-0B57D0?style=for-the-badge&logo=tauri&logoColor=white" alt="Instalador de la versión de escritorio"></a>
    <a href="#-puesta-en-marcha">
      <img src="https://img.shields.io/badge/o_con_un_comando-PowerShell-5391FE?style=for-the-badge&logo=powershell&logoColor=white" alt="Ejecutar con un comando"></a>
  </p>
  <p><sub><strong>Descargar</strong> es un solo archivo, no se instala, se abre y ya · <strong>Instalador</strong> es la versión de escritorio, con la interfaz nueva</sub></p>
  <p><em>Lo primero que ves no es un menú: es qué versión le conviene a tu equipo.</em></p>
</div>

---

**OfficeGo** instala Microsoft Office en Windows 10 y 11 desde una ventana sencilla.
Pide los archivos a los **servidores oficiales de Microsoft** (`officecdn.microsoft.com`
y `c2rsetup.officeapps.live.com`) con las opciones que elijas en pantalla, y te deja
activarlo con tu clave o con [MAS](https://github.com/massgravel/Microsoft-Activation-Scripts).

Está escrito en **PowerShell con Windows Forms**: eso significa que es un archivo de
texto legible, que no hay que instalar ningún runtime, y que el antivirus no se pone
nervioso como con un `.exe` descargado.

**¿Primera vez?** El **[tutorial](docs/TUTORIAL.md)** lleva de la mano desde abrir
PowerShell hasta tener Office puesto, diciendo en cada paso qué debería verse en
pantalla.

> **Nada se instala hasta que lo confirmas.** El programa arranca revisando tu equipo
> (Windows, memoria, disco, gráfica) y recomienda la versión que de verdad te cabe.
> Con 3 GB de RAM te propone Office 2016, no la última.

![Pantalla de inicio](capturas/inicio.png)

## Features

| | Feature | Qué hace |
|---|---|---|
| 🎯 | **Recomienda por ti** | Lee Windows, RAM, disco y gráfica, y propone la versión adecuada según los requisitos publicados por Microsoft. Con poca memoria baja sola a 2016. |
| 📦 | **Seis versiones** | Microsoft 365, Office **2024**, **2021**, **2019**, **2016** y **2013**, cada una con sus ediciones: Professional Plus, Standard, Home & Business, Personal. |
| ✅ | **Eliges qué instalar** | Solo Word y Excel, o la suite entera. Al cambiar de edición las aplicaciones se ajustan solas: con *Standard* se apaga Access, porque esa edición no lo trae. |
| 📐 | **Visio y Project** | Como complementos, en el mismo `configuration.xml` que Office. |
| 🔑 | **Activación integrada** | Con tu clave de 25 caracteres, o con MAS ejecutado con `/Ohook` **sin abrir su menú**: todo ocurre dentro de la ventana. |
| 🖥️ | **Conoce tu equipo** | Procesador con uso en vivo, memoria, cada disco con su ocupación y la tarjeta gráfica con su marca: NVIDIA, AMD o Intel. |
| 🧰 | **Herramientas** | Reparar la instalación, crear un instalador sin conexión para otros equipos, y desinstalar (pidiendo escribir `BORRAR`). |
| 🚑 | **Ayuda de verdad** | Los errores frecuentes con el **mensaje literal** que sale en pantalla y el comando exacto que los arregla. |
| 🪶 | **Portable** | Un `.ps1` de 76 KB. Cabe en un USB, no deja rastro en el registro, no necesita instalarse. |
| 🧪 | **Se prueba sola** | 44 pruebas del motor, el arranque por las dos vías, y un analizador que monta las seis pantallas con controles simulados y busca controles solapados. Todo corre en cada compilación, y también en el PowerShell 5.1 que trae Windows. |
| ⚡ | **Desatendido** | `-Instalar 2021 -Apps Word,Excel -Silencioso -Activar` deja un aula entera igual, sin que nadie toque nada. Y si faltan permisos, se los pide y se relanza con las mismas opciones. |
| 🔒 | **Sin telemetría** | No manda nada a ninguna parte. El código está aquí para leerlo. |

<details>
<summary><strong>Arquitectura</strong></summary>

<br>

```
 Equipo ─► WMI (Windows, CPU, RAM, discos, GPU) ─► recomendación de versión
        ─► catálogo (Product ID + vía + canal) ─► configuration.xml
        ─► setup.exe /configure  ó  c2rsetup ─► Office instalado
        └─► [opcional] MAS /Ohook en segundo plano ─► activado

              todo en PowerShell + Windows Forms, sin dependencias externas
```

**Dos vías, y no son intercambiables:**

| Vía | Sirve | ¿Elegir aplicaciones? |
|---|---|---|
| **ODT** · `setup.exe /configure` | Microsoft 365, Office 2024 / 2021 / 2019 (volumen) | Sí, con `<ExcludeApp>` |
| **C2R** · `c2rsetup.officeapps.live.com` | Office 2016 y 2013 (retail) | No: descarga la suite entera |

Por eso, al elegir 2016 o 2013, la columna de aplicaciones se desactiva sola. No es
una limitación del programa, es de Microsoft.

```
officego/
├── OfficeGo.ps1        → el programa · se genera con build.sh · NO editar a mano
├── OfficeGo.cmd        → lanzador de doble clic, pide permisos solo
├── compilar-exe.bat    → genera OfficeGo.exe con el csc.exe que Windows ya trae
├── src/
│   ├── 0-parametros.ps1    Las opciones de la línea de órdenes
│   ├── 1-catalogo.ps1      Versiones, ediciones, qué apps trae cada una
│   ├── 2-motor.ps1         Descarga con progreso, configuration.xml, WMI, MAS
│   ├── 2b-recomendacion.ps1 Qué versión le conviene a este equipo
│   ├── 3-interfaz.ps1      Ventana, barra lateral, controles reutilizables
│   ├── 4-pantallas.ps1     Instalar · Activar · Equipo · Herramientas · Ayuda
│   ├── 5-inicio.ps1        Pantalla de bienvenida con la recomendación
│   ├── 6-acciones.ps1      Qué pasa al pulsar cada botón
│   ├── 7-arranque.ps1      Elevación, modo consola y puesta en marcha
│   └── Lanzador.cs         Envoltorio del .exe (C#, compilación opcional)
├── test.ps1            → 63 pruebas del motor
├── prueba-arranque.ps1 → que arranque por irm|iex y como archivo
├── prueba-interfaz.ps1 → monta las pantallas y busca solapes, sin Windows
├── prueba-exe.ps1      → que el .exe lleve dentro lo que dice (solo Windows)
├── build.sh            → ensambla src/*.ps1 y valida la sintaxis
├── tauri/              → versión de escritorio: Svelte 5 + Rust (Tauri 2) · ver tauri/LEEME.md
├── .github/workflows/  → comprueba y compila todo en un runner de Windows al etiquetar
├── CHANGELOG.md        → lo nuevo de la última versión: son las notas del release
├── assets/             → icono en .ico (7 tamaños) y .png
└── capturas/           → las pantallas
```

</details>

<details>
<summary><strong>Las pantallas</strong></summary>

<br>

**Instalar.** Versión, edición, idioma y aplicaciones. El resumen de la derecha se
recalcula con cada cambio.

![Instalar](capturas/instalar.png)

**Equipo.** Procesador, memoria, discos y gráfica, con la recomendación arriba.

![Equipo](capturas/equipo.png)

El mismo programa en una máquina con 3 GB de RAM y Windows 10 build 18363: la
recomendación **cambia sola a Office 2016**, el marco pasa a ámbar y aparecen los
avisos que correspondan.

![Equipo antiguo](capturas/equipo-antiguo.png)

**Activar.** Con tu clave o con MAS, que se ejecuta en segundo plano.

![Activar](capturas/activar.png)

**Herramientas** y **Ayuda**

![Herramientas](capturas/herramientas.png)
![Ayuda](capturas/ayuda.png)

</details>

## Dos versiones, un mismo motor

| | **1.x · PowerShell** | **2.x · escritorio** |
|---|---|---|
| Interfaz | Windows Forms | Svelte 5 sobre Tauri 2 (Rust) |
| Peso | 88 KB | ~4 MB (instalador de 1,5 MB) |
| Windows 10 antiguo | Funciona siempre | Necesita WebView2 |
| Antivirus | Tranquilo | SmartScreen avisa la primera vez |
| `irm \| iex` | Sí | No, hay que descargar |
| Se actualiza sola | No, siempre baja la última | Sí, desde la propia app |
| Idiomas | Español | Español e inglés, según el sistema |

**Las dos comparten el motor.** La versión de escritorio no reimplementa nada en Rust:
deja el mismo PowerShell en `%TEMP%` y lo invoca, y Rust tipa cada respuesta y reenvía
a la interfaz cada línea de progreso. Un arreglo en `src/2-motor.ps1` vale para ambas.

La 1.x es la vía universal, la del comando de una línea, la que funciona en el portátil
viejo. La de escritorio es la interfaz cuidada para equipos normales: clave de producto,
reparación, instalador sin conexión con selector de carpeta y actualización desde la
propia app. Ver [`tauri/LEEME.md`](tauri/LEEME.md).

## ⬇️ Descargas

Todo sale del [**último release**](https://github.com/MariaDSalazar/officego/releases/latest).
Si no sabes cuál, el primero.

| Archivo | Qué es | Cuándo te sirve |
|---|---|---|
| [**OfficeGo.exe**](https://github.com/MariaDSalazar/officego/releases/latest/download/OfficeGo.exe) | El programa entero en un archivo. Doble clic y ya | **Lo normal.** No se instala, no toca el registro, cabe en un USB |
| [**OfficeGo-setup.exe**](https://github.com/MariaDSalazar/officego/releases/latest/download/OfficeGo-setup.exe) | La versión de escritorio, con su acceso en el menú Inicio y que se actualiza sola | Si lo vas a usar a menudo en el mismo equipo |
| [OfficeGo-portable.exe](https://github.com/MariaDSalazar/officego/releases/latest/download/OfficeGo-portable.exe) | La versión de escritorio sin instalar nada | La interfaz nueva, pero desde un USB |
| [OfficeGo.ps1](https://github.com/MariaDSalazar/officego/releases/latest/download/OfficeGo.ps1) + [OfficeGo.cmd](https://github.com/MariaDSalazar/officego/releases/latest/download/OfficeGo.cmd) | El script suelto, en texto legible | Para leer qué hace antes de ejecutarlo, o para un aula |

> **Windows dirá «Windows protegió su PC» la primera vez.** Sale con cualquier `.exe`
> descargado que no esté firmado, y firmarlo cuesta unos cientos de euros al año.
> Para seguir: **Más información** → **Ejecutar de todas formas**. Si prefieres no
> descargar nada, usa [el comando de una línea](#-puesta-en-marcha) o
> [compílate el `.exe` tú mismo](#4--con-icono-propio) con lo que Windows ya trae.

## 🚀 Puesta en marcha

Cuatro formas, todas locales. La primera no descarga nada.

### 1 · Un solo comando

Abre **PowerShell como administrador**: tecla <kbd>Windows</kbd> → escribe
`PowerShell` → *Ejecutar como administrador*, y pega:

```powershell
irm https://raw.githubusercontent.com/MariaDSalazar/officego/main/OfficeGo.ps1 | iex
```

Si lo abriste sin permisos, OfficeGo se da cuenta, los pide y se relanza solo.

### 2 · Un solo comando, con opciones

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/MariaDSalazar/officego/main/OfficeGo.ps1))) -Instalar 2021 -Apps Word,Excel
```

Ese `[scriptblock]::Create` no es adorno: con `irm | iex` **no se pueden pasar
parámetros**, porque `iex` recibe el texto ya montado y no queda dónde engancharlos.

<details>
<summary>Todas las opciones</summary>

<br>

| Opción | Qué hace |
|---|---|
| `-Instalar` | `365` `2024` `2021` `2019` `2016` `2013` |
| `-Edicion` | `ProPlus` (por defecto), `Standard`, `Professional`, `HomeStudent`… |
| `-Apps` | `Word,Excel,PowerPoint`. Lo que no se nombre, no se instala |
| `-Complementos` | `VisioPro`, `VisioStd`, `ProjectPro`, `ProjectStd` |
| `-Idioma` | `es-es` (por defecto), `es-mx`, `en-us`… |
| `-Bits` | `64` o `32`. Por defecto, lo que sea el Windows |
| `-Activar` | Activa al terminar. Suelto, activa sin instalar nada |
| `-Desinstalar` | Quita Office del equipo |
| `-Silencioso` | Sin ventanas de Microsoft ni preguntas |
| `-Ayuda` | Enseña todo esto en pantalla |

```powershell
# un aula entera, sin que nadie toque nada
... -Instalar 2021 -Apps Word,Excel,PowerPoint -Silencioso -Activar
```

</details>

### 3 · Portable

Baja [`OfficeGo.exe`](https://github.com/MariaDSalazar/officego/releases/latest/download/OfficeGo.exe)
y haz doble clic: lleva el script dentro y pide los permisos solo. También admite
opciones, igual que el comando:

```powershell
.\OfficeGo.exe -Instalar 2021 -Apps Word,Excel
```

Si prefieres el script suelto, en texto legible, copia
[`OfficeGo.ps1`](https://github.com/MariaDSalazar/officego/releases/latest/download/OfficeGo.ps1)
y [`OfficeGo.cmd`](https://github.com/MariaDSalazar/officego/releases/latest/download/OfficeGo.cmd)
a la misma carpeta y haz **doble clic en `OfficeGo.cmd`**.

### 4 · Con icono propio

```bat
compilar-exe.bat
```

Genera `OfficeGo.exe`. No hace falta instalar nada: **Windows ya trae el compilador de
C#** en `C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe`. Y como lo compilas
en tu propio equipo, SmartScreen no lo marca igual que a un ejecutable bajado de internet.

## Documentación

- **[Tutorial completo](docs/TUTORIAL.md)**: instalar y ejecutar las dos versiones paso
  a paso, con todos los errores que salen y cómo se arreglan.
- **[Guía rápida](docs/GUIA-RAPIDA.md)**: instalar Office en cinco minutos, qué versión
  elegir y qué hacer si algo falla. Para quien no quiere leerse todo esto.
- **[Pruebas en máquina virtual](docs/PRUEBAS-VM.md)**: checklist para validar las dos
  versiones antes de darlas por buenas.

## Requisitos

| | |
|---|---|
| Sistema | Windows 10 (build 10240) o Windows 11 |
| Permisos | Administrador |
| Disco | 5 GB libres en la unidad del sistema |
| Red | Conexión a internet |

Se comprueban los cuatro al arrancar y quedan a la vista en la barra inferior.

## Qué versión te toca

Las reglas salen de los requisitos que publica Microsoft:

| Versión | Necesita |
|---|---|
| Office LTSC **2024** | Windows 11, o Windows 10 versión 22H2 |
| Office LTSC **2021** | Windows 10 versión 1809 o superior |
| Office **2019** | Windows 10 |
| Office **2016** / **2013** | Windows 7 SP1 en adelante |

Con menos de 4 GB de RAM se recomienda siempre la versión ligera, sin importar el Windows.

## Antivirus

El instalador no debería dar problemas: descarga de dominios de Microsoft y no hace
nada ofuscado.

**MAS sí lo detecta Windows Defender**, siempre y por diseño. Está advertido en la
propia web de massgrave.dev. OfficeGo lo avisa antes de lanzarlo y explica cómo pausar
la protección un momento y **volver a encenderla al terminar**.

## Estado del proyecto

Cada compilación pasa las 44 pruebas del motor, comprueba que el script arranque por
las dos vías y monta las seis pantallas buscando controles solapados. Todo eso se
repite además en el **PowerShell 5.1 que trae Windows**, que no lee los archivos igual
que el 7 y es donde se escondía uno de los fallos de la 1.3.

Lo que **no** se puede comprobar sin un Windows delante es cómo se ve de verdad: las
medidas de la letra son una estimación y los clics no se pueden pulsar solos. Si al
abrirlo ves algo descolocado o un botón que no responde,
[abre un issue](../../issues/new) con una captura y se corrige.

<details>
<summary>Lo que se rompió en la 1.3 y cómo se evita ahora</summary>

<br>

Tres fallos, los tres invisibles hasta que alguien lo abrió en un Windows de verdad:

| Qué pasaba | Por qué | Qué lo detecta ahora |
|---|---|---|
| `irm \| iex` no arrancaba | El archivo llevaba BOM. Ese carácter invisible viaja en el texto que devuelve `irm`, así que `param()` deja de ser lo primero del bloque y PowerShell lo parsea como una llamada a un comando | `prueba-arranque.ps1` |
| Media ventana no respondía | Los clics usaban `.GetNewClosure()`, y dentro de un closure `$script:` apunta a su propio módulo: las asignaciones a `$script:sel` se perdían y el botón se quedaba mudo | `prueba-interfaz.ps1`, sección de closures |
| Las tarjetas se montaban unas encima de otras | `[int]($i / 3)` para la fila. En PowerShell `[int]` **redondea**, no trunca, así que `[int](5/3)` da 2 y la sexta tarjeta caía una fila de más, justo encima de los desplegables | `prueba-interfaz.ps1`, análisis de solapes |

A eso se suma que la ventana se declaraba *DPI-aware*, lo que hacía crecer la letra con
el escalado de la pantalla mientras las coordenadas seguían en píxeles fijos: al 125 %
se solapaban 21 controles. Ya no se declara, así que Windows escala la ventana entera.

</details>

## Para desarrollar

```bash
./build.sh                             # junta src/*.ps1 y valida la sintaxis
pwsh test.ps1                          # 63 pruebas del motor
pwsh prueba-arranque.ps1               # que arranque por las dos vías
pwsh prueba-interfaz.ps1               # que la ventana no se solape
pwsh prueba-interfaz.ps1 -Factor 1.15  # ídem con la letra más ancha
```

La versión de escritorio tiene sus propias comprobaciones (lint, tipos, clippy y las
pruebas de Rust, incluida una que corre el motor de verdad): están en
[`tauri/LEEME.md`](tauri/LEEME.md).

**Las de PowerShell no necesitan Windows.** Las del motor comprueban que cada edición declare las
aplicaciones que de verdad incluye, que el `configuration.xml` salga bien formado con
sus `ExcludeApp`, y que la recomendación acierte con siete equipos distintos.

`prueba-interfaz.ps1` es lo menos obvio: monta las seis pantallas con controles
simulados que solo guardan dónde y cuánto ocupan, y busca controles encima de otros o
salidos de su caja. Recorre además las 17 combinaciones de versión y edición, porque
el reparto de la pantalla Instalar cambia con cada una. Con `-Factor` se simula una
letra más ancha, que es lo que pasa cuando la fuente del equipo no es la esperada.

Lo que antes cruzaba `prueba-tauri.ps1` (que cada acción de la interfaz exista en el
puente, que cada `invoke` exista en Rust y que el puente cargue lo que Rust escribe)
ahora lo comprueban los tipos que Rust genera para la interfaz y las pruebas de Rust.

## Créditos

- Instalación: [Office Deployment Tool](https://learn.microsoft.com/microsoft-365-apps/deploy/overview-office-deployment-tool) de Microsoft
- Activación: [MAS · Microsoft Activation Scripts](https://github.com/massgravel/Microsoft-Activation-Scripts), proyecto independiente
- Idea original del catálogo de versiones: la comunidad de [massgrave.dev](https://massgrave.dev)

<div align="center">
<table>
<tr>
<td align="center" width="50%">
<a href="https://github.com/DiegoFernandoLojanTenesaca">
<img src="https://github.com/DiegoFernandoLojanTenesaca.png" width="80" style="border-radius:50%"><br>
<strong>Diego Fernando Loján Tenesaca</strong></a><br>
<sub>Desarrollo e interfaz</sub>
</td>
<td align="center" width="50%">
<a href="https://github.com/MariaDSalazar">
<img src="https://github.com/MariaDSalazar.png" width="80" style="border-radius:50%"><br>
<strong>María del Carmen Salazar Torres</strong></a><br>
<sub>Script base y documentación</sub>
</td>
</tr>
</table>
</div>

## Aviso

Activar productos sin pagar la licencia va contra los términos de Microsoft. Este
proyecto se publica con fines educativos y de administración de equipos propios.

## Licencia

MIT. Ver [LICENSE](LICENSE).

---

<div align="center">
  <sub><strong>OfficeGo</strong> · Office donde lo pone Microsoft, sin vueltas.</sub>
</div>
