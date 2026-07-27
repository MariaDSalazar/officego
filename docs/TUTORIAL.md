# Cómo instalar y ejecutar OfficeGo

Hay dos versiones y las dos hacen lo mismo. Cambia cómo se ejecutan.

| | Versión 1.3 · PowerShell | Versión 2.0 · Tauri |
|---|---|---|
| Qué es | Un archivo de texto que ya trae Windows para ejecutar | Un programa que se instala |
| Hay que descargar algo | No, se pega una línea y listo | Sí, un instalador de 1 MB |
| Aspecto | Ventana clásica de Windows | Interfaz moderna |
| Necesita | Nada, viene con Windows 10 y 11 | WebView2, que ya trae Windows 11 |
| Para qué va mejor | Un equipo suelto, un aula, arreglar algo deprisa | Usarlo a menudo en el mismo equipo |

Si no tiene claro cuál, use la de PowerShell. No hay que instalar nada.

---

# Versión 1.3 · PowerShell

## Paso 1 · Abrir PowerShell como administrador

Sin permisos de administrador no se puede instalar Office. OfficeGo los pide
solo si hace falta, pero es más cómodo empezar con ellos.

1. Pulse el botón **Inicio**
2. Escriba `powershell`
3. En el resultado **Windows PowerShell**, clic derecho
4. Elija **Ejecutar como administrador**
5. Windows preguntará si permite los cambios: **Sí**

La ventana correcta pone `Administrador: Windows PowerShell` en la barra de título.

## Paso 2 · Pegar el comando

```powershell
irm https://raw.githubusercontent.com/MariaDSalazar/officego/main/OfficeGo.ps1 | iex
```

Cópielo, pegue en PowerShell con **clic derecho** (Ctrl+V también vale) y pulse
**Enter**. En unos segundos se abre la ventana de OfficeGo.

> `irm` descarga el script y `iex` lo ejecuta. No queda nada instalado en el
> equipo: al cerrar la ventana no queda rastro salvo Office, si lo instaló.

## Paso 3 · Usar la ventana

La pantalla de inicio propone una versión de Office según lo que tenga el equipo.
Si le vale, **Instalar esto**. Si no, vaya a **Instalar** y elija a mano.

En **Instalar** se decide:

- la versión de Office
- la edición, que cambia qué aplicaciones trae
- qué aplicaciones quiere de verdad, porque lo que no marque no se instala
- el idioma y si de 64 o 32 bits

Abajo se ve cuánto va a ocupar la descarga antes de empezar.

---

## Con opciones, sin tocar la ventana

Sirve para dejarlo puesto en varios equipos, o para no tener que ir eligiendo
cada vez. Es lo mismo, pero por escrito.

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/MariaDSalazar/officego/main/OfficeGo.ps1))) -Instalar 2021 -Apps Word,Excel
```

Ese `[scriptblock]::Create` de en medio no es adorno: con `irm | iex` no se
pueden pasar opciones, porque `iex` recibe el texto ya montado y no queda dónde
enganchar los parámetros.

### Las opciones

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

### Ejemplos

Word y Excel solamente, nada más:
```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/MariaDSalazar/officego/main/OfficeGo.ps1))) -Instalar 2021 -Apps Word,Excel
```

Office 2024 Standard con Visio, y activado al terminar:
```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/MariaDSalazar/officego/main/OfficeGo.ps1))) -Instalar 2024 -Edicion Standard -Complementos VisioPro -Activar
```

Desatendido, para un aula entera por script:
```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/MariaDSalazar/officego/main/OfficeGo.ps1))) -Instalar 2021 -Silencioso -Activar
```

Solo activar un Office que ya está puesto:
```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/MariaDSalazar/officego/main/OfficeGo.ps1))) -Activar
```

Si abrió PowerShell sin permisos, OfficeGo se da cuenta, pide los permisos y se
vuelve a lanzar con las mismas opciones. No hay que repetir nada.

---

## Sin internet en el equipo de destino

Descargue `OfficeGo.ps1` del [último release](https://github.com/MariaDSalazar/officego/releases),
llévelo en un pendrive y desde la carpeta donde lo dejó:

```powershell
.\OfficeGo.ps1
```

Office sí se descarga de internet, así que el equipo lo necesitará igualmente
para instalar. Sin conexión solo se pueden mirar las pantallas.

---

# Versión 2.0 · Tauri

## Instalarla

1. Vaya a los [releases](https://github.com/MariaDSalazar/officego/releases)
2. Baje **OfficeGo_2.0.0_x64-setup.exe**
3. Ábralo

Windows enseñará una pantalla azul que dice **Windows protegió su PC**. Sale
porque el instalador no está firmado, y firmarlo cuesta unos cientos de euros al
año. Para seguir: **Más información** y luego **Ejecutar de todas formas**.

4. Siga el instalador, que son dos clics
5. OfficeGo queda en el menú Inicio

Para abrirlo con permisos: clic derecho en el icono, **Ejecutar como administrador**.

## Sin instalar

En el mismo release está **OfficeGo-tauri-portable.exe**. Se ejecuta tal cual, no
instala nada y se puede llevar en un pendrive.

## Si dice que falta WebView2

Windows 11 lo trae de serie y Windows 10 actualizado también. Si su equipo no lo
tiene, se baja gratis de Microsoft:

<https://developer.microsoft.com/microsoft-edge/webview2/>

Elija **Evergreen Standalone Installer** de x64.

---

# Cuando algo no sale

## «No se puede cargar el archivo … no está firmado digitalmente»

Windows viene con los scripts bloqueados. Se desbloquea para esta ventana y nada
más, así que no queda el equipo tocado:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
```

Y a continuación el comando de OfficeGo otra vez.

## «No se puede establecer conexión SSL/TLS»

Pasa en Windows viejos que salen con TLS 1.0. Antes del comando:

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
```

OfficeGo ya lo hace por su cuenta al arrancar, así que esto solo hace falta si
ni siquiera consigue descargarse.

## «irm no se reconoce como un cmdlet»

Está usando el **Símbolo del sistema** (fondo negro, `C:\>`), no PowerShell.
Cierre y abra PowerShell como se explica en el paso 1.

## La ventana sale con símbolos raros en lugar de acentos

El archivo perdió su marca de codificación al copiarlo. Bájelo otra vez del
release en vez de copiar y pegar el texto.

## El antivirus borra algo durante la activación

Es lo esperado. Los activadores se marcan siempre, por diseño de los antivirus,
sin que eso signifique que haya un virus. OfficeGo avisa antes de empezar.
Si quiere seguir, pause la protección en tiempo real, active, y **vuelva a
encenderla al terminar**.

## Office se instaló pero falta una aplicación

Es lo que se pidió: lo que no se marca no se instala. Vuelva a pasar OfficeGo
marcando también esa aplicación.

Con Office 2016 y 2013 no se puede elegir: Microsoft los sirve enteros por otra
vía y no admite excluir nada. OfficeGo lo avisa al elegirlos.

## Dónde mirar si falla la instalación

Los registros quedan en:

- `%TEMP%\OfficeGo` lo de OfficeGo
- `%TEMP%` los `.log` que deja el instalador de Microsoft

---

# Preguntas que salen siempre

**¿Hace falta desinstalar el Office que ya tengo?**
No. Si es una versión distinta, el instalador la sustituye. Si quiere dejarlo
limpio, en **Herramientas** está la opción de quitarlo antes.

**¿Se puede volver atrás?**
Sí. En **Herramientas**, «Desinstalar Office», o con `-Desinstalar`.

**¿Cuánto tarda?**
Entre diez minutos y media hora, casi todo descargando. Office ocupa entre 1,5 y
3 GB según la versión.

**¿Puedo usar las dos versiones en el mismo equipo?**
Sí, no se estorban. La de PowerShell no instala nada.

**¿De dónde sale Office?**
De los servidores de Microsoft, `officecdn.microsoft.com` y
`c2rsetup.officeapps.live.com`. OfficeGo no aloja ninguna copia.
