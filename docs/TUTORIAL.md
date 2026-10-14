# Tutorial de OfficeGo

Paso a paso, desde cero, para instalar Microsoft Office con OfficeGo.

Cada paso trae **qué hacer** y **qué debería verse** después. Si lo que sale en su
pantalla no coincide con lo que dice aquí, no siga: baje al
[apartado de errores](#7--cuando-algo-no-sale) y busque el mensaje.

---

## Índice

1. [Antes de empezar](#1--antes-de-empezar)
2. [Elegir cómo abrirlo](#2--elegir-cómo-abrirlo)
3. [Ruta A · El comando de una línea](#3--ruta-a--el-comando-de-una-línea)
4. [Ruta B · Descargar OfficeGo.exe](#4--ruta-b--descargar-officegoexe)
5. [Ruta C · Instalar la versión 2.0](#5--ruta-c--instalar-la-versión-20)
6. [Instalar Office, pantalla por pantalla](#6--instalar-office-pantalla-por-pantalla)
7. [Cuando algo no sale](#7--cuando-algo-no-sale)
8. [Sin tocar la ventana: opciones por escrito](#8--sin-tocar-la-ventana-opciones-por-escrito)
9. [Preguntas que salen siempre](#9--preguntas-que-salen-siempre)

---

## 1 · Antes de empezar

Compruebe estas cuatro cosas. OfficeGo las mira solo al arrancar y las enseña en la
barra de abajo, pero si falta alguna es mejor saberlo ahora.

| | Qué hace falta | Cómo comprobarlo |
|---|---|---|
| **Windows** | 10 o 11 | Tecla <kbd>Windows</kbd> + <kbd>R</kbd>, escriba `winver`, <kbd>Enter</kbd> |
| **Permisos** | Ser administrador del equipo | Si es su equipo personal, lo es |
| **Disco** | 5 GB libres como mínimo | Abra **Este equipo** y mire la unidad C: |
| **Internet** | Conexión que aguante una descarga larga | Office ocupa entre 1,5 y 3 GB |

> **Cuánto va a tardar.** Entre 10 y 30 minutos, y casi todo es descarga. Con una
> conexión lenta puede irse a una hora. No hay que estar delante mientras baja.

**¿Tiene ya un Office instalado?** No hace falta quitarlo. Si es de otra versión, el
instalador lo sustituye. Sus documentos no se tocan en ningún caso.

---

## 2 · Elegir cómo abrirlo

Tres formas. Hacen lo mismo, cambia de dónde sale el programa.

| | Ruta A · Comando | Ruta B · Descargar el .exe | Ruta C · Instalador 2.0 |
|---|---|---|---|
| Hay que descargar algo | No | Sí, un archivo | Sí, un instalador |
| Deja algo puesto en el equipo | No | No | Sí, en el menú Inicio |
| Windows avisa de seguridad | No | Sí, la primera vez | Sí, la primera vez |
| Tiempo hasta verlo en pantalla | Medio minuto | Un minuto | Dos minutos |
| Interfaz | Ventana clásica | Ventana clásica | La nueva |

**Si duda: Ruta A.** Es la más rápida y no deja nada en el equipo.

Vaya al apartado de la ruta que elija y siga desde ahí. No hace falta leer las otras.

---

## 3 · Ruta A · El comando de una línea

### Paso 1 · Abrir PowerShell como administrador

**Qué hacer:**

1. Pulse la tecla <kbd>Windows</kbd>
2. Escriba `powershell` (según lo escriba, aparece en la lista)
3. Sobre **Windows PowerShell**, haga **clic con el botón derecho**
4. Elija **Ejecutar como administrador**
5. Windows preguntará si permite que esta aplicación haga cambios: **Sí**

**Qué debería ver:** una ventana azul oscuro. Lo importante es la barra de arriba:

```
┌──────────────────────────────────────────────────────────┐
│  Administrador: Windows PowerShell            ─  □  ✕   │  ← tiene que poner
├──────────────────────────────────────────────────────────┤     "Administrador:"
│                                                          │
│  Windows PowerShell                                      │
│  Copyright (C) Microsoft Corporation.                    │
│                                                          │
│  PS C:\WINDOWS\system32>                                 │  ← y empezar por PS
│                                                          │
└──────────────────────────────────────────────────────────┘
```

Dos comprobaciones rápidas:

- La barra de título **pone «Administrador:»**. Si no lo pone, cerró y abrió con
  «Abrir» en lugar de «Ejecutar como administrador». Repita desde el punto 3.
- La línea **empieza por `PS`**. Si empieza por `C:\>` sin el `PS`, ha abierto el
  Símbolo del sistema, que es otra cosa. Cierre y repita desde el punto 1.

### Paso 2 · Copiar el comando

**Qué hacer:** copie esta línea entera. Es una sola, aunque en pantalla se parta.

```powershell
irm https://raw.githubusercontent.com/MariaDSalazar/officego/main/OfficeGo.ps1 | iex
```

> Qué significa: `irm` descarga el archivo y `iex` lo ejecuta. Nada queda instalado
> en el equipo. Al cerrar la ventana no queda rastro, salvo el Office que instale.

### Paso 3 · Pegarlo y ejecutar

**Qué hacer:**

1. Vuelva a la ventana de PowerShell
2. Pegue con **clic derecho** dentro de la ventana. <kbd>Ctrl</kbd>+<kbd>V</kbd>
   también funciona en Windows 10 y 11
3. Pulse <kbd>Enter</kbd>

**Qué debería ver:** el cursor parpadea unos segundos y se abre la ventana de OfficeGo.

**Si en vez de eso sale texto en rojo:** vaya a
[cuando algo no sale](#7--cuando-algo-no-sale) y busque las primeras palabras del
mensaje. Los dos más frecuentes tienen solución de una línea.

Ya está. **Siga en el apartado 6.**

---

## 4 · Ruta B · Descargar OfficeGo.exe

### Paso 1 · Bajar el archivo

**Qué hacer:** abra este enlace, que descarga el archivo directamente.

<https://github.com/MariaDSalazar/officego/releases/latest/download/OfficeGo.exe>

**Qué debería ver:** el navegador baja `OfficeGo.exe`, de menos de 100 KB.
Es pequeño porque el programa es un script: **Office se descarga después**, cuando
usted elija la versión.

Puede que el navegador avise de que «este archivo no se descarga habitualmente».
Elija **Conservar** o **Mantener de todos modos**.

### Paso 2 · Abrirlo

**Qué hacer:** doble clic en el archivo descargado.

**Qué debería ver:** una pantalla azul a toda pantalla que dice:

```
┌──────────────────────────────────────────────────────────┐
│                                                          │
│   Windows protegió su PC                                 │
│                                                          │
│   Microsoft Defender SmartScreen impidió el inicio de    │
│   una aplicación desconocida...                          │
│                                                          │
│   Más información            ← PULSE AQUÍ PRIMERO        │
│                                                          │
│                                        [ No ejecutar ]   │
└──────────────────────────────────────────────────────────┘
```

**Qué hacer:**

1. Pulse **Más información** (el texto pequeño, fácil de pasar por alto)
2. Aparece un botón nuevo: **Ejecutar de todas formas**
3. Púlselo
4. Windows pedirá permisos de administrador: **Sí**

> **Por qué sale ese aviso.** El ejecutable no está firmado digitalmente, y firmarlo
> cuesta unos cientos de euros al año. Windows avisa de cualquier `.exe` sin firma,
> sin mirar qué hace. Si prefiere no pasar por ahí, use la [Ruta A](#3--ruta-a--el-comando-de-una-línea),
> que no descarga ningún ejecutable.

**Qué debería ver ahora:** la ventana de OfficeGo.

**Siga en el apartado 6.**

---

## 5 · Ruta C · Instalar la versión 2.0

Es la misma herramienta con la interfaz nueva. Esta sí se instala.

### Paso 1 · Bajar el instalador

**Qué hacer:** abra la página de descargas:

<https://github.com/MariaDSalazar/officego/releases/latest>

Baje hasta **Assets** y pulse **OfficeGo-setup.exe**.

**Qué debería ver:** se descarga un archivo de unos pocos MB.

### Paso 2 · Instalarlo

**Qué hacer:** doble clic. Saldrá el mismo aviso azul de SmartScreen que en la Ruta B:
**Más información** → **Ejecutar de todas formas**.

Después, el instalador: **Siguiente**, **Siguiente**, **Instalar**.

**Qué debería ver:** OfficeGo aparece en el menú Inicio.

### Paso 3 · Abrirlo con permisos

**Qué hacer:** ábralo desde el menú Inicio. Si se abrió sin permisos de administrador,
OfficeGo lo dice nada más empezar y ofrece **Reiniciar con permisos**: púlselo y
acepte el aviso de Windows.

Si prefiere no reiniciarlo, puede mirar todas las pantallas, pero no podrá instalar,
activar ni reparar nada. También vale **clic derecho** sobre OfficeGo →
**Ejecutar como administrador**.

Cuando salga una versión nueva, la barra lateral muestra **Nueva versión** y se
actualiza desde ahí, sin desinstalar nada.

> **Si dice que falta WebView2:** Windows 11 lo trae de serie y Windows 10 al día
> también. Si su equipo no lo tiene, se baja gratis de Microsoft en
> <https://developer.microsoft.com/microsoft-edge/webview2/>, opción
> **Evergreen Standalone Installer** de x64. Es cosa de un minuto.
>
> Si no quiere instalar nada más, la [Ruta A](#3--ruta-a--el-comando-de-una-línea)
> no necesita WebView2.

**Siga en el apartado 6.**

---

## 6 · Instalar Office, pantalla por pantalla

### 6.1 · La pantalla de inicio

Nada más abrirse, OfficeGo ha mirado su equipo y ya propone una versión:

```
┌────────────┬────────────────────────────────────────────────────┐
│            │                                                    │
│  Inicio    │   Para este equipo recomendamos                    │
│  Instalar  │   ┌──────────────────────────────────────────┐     │
│  Activar   │   │  Office LTSC 2021                        │     │
│  Equipo    │   │  Professional Plus · 64 bits · 1,9 GB    │     │
│  Herram.   │   │                                          │     │
│  Ayuda     │   │            [ Instalar esto ]  ← el botón │     │
│            │   └──────────────────────────────────────────┘     │
│            │                                                    │
├────────────┴────────────────────────────────────────────────────┤
│ ● Windows 11 · 22631  ● Administrador  ● 240 GB libres  ● ...   │  ← barra
└─────────────────────────────────────────────────────────────────┘     de estado
```

**La barra de abajo** son las cuatro comprobaciones del apartado 1. En verde, todo
bien. Si alguna sale en rojo, arréglela antes de seguir:

| Lo que ponga en rojo | Qué significa |
|---|---|
| **Sin permisos** | Cierre y vuelva a abrir como administrador |
| **Sin internet** | Sin conexión no se puede descargar Office |
| Pocos **GB libres** | Haga sitio: hacen falta 5 GB como mínimo |

**Qué hacer:**

- **Si la recomendación le vale:** pulse **Instalar esto** y salte a [6.4](#64--confirmar-y-esperar).
- **Si quiere elegir usted:** pulse **Instalar** en la columna de la izquierda.

### 6.2 · Elegir la versión

En la pantalla **Instalar** se decide todo. Cuatro cosas, en este orden:

**Primero, la versión.** Pulse una de las tarjetas. La elegida se resalta.

Si la recomendación no le convence, esta es la regla corta:

| Su equipo | Elija |
|---|---|
| Windows 11, o Windows 10 al día | **Office 2024** |
| Windows 10 normal | **Office 2021** |
| Windows 10 de los primeros | **Office 2019** |
| Windows 7 u 8, o menos de 4 GB de RAM | **Office 2016** |
| Un equipo muy viejo | **Office 2013** |

**Segundo, la edición.** Cambia qué aplicaciones trae:

| Edición | Trae |
|---|---|
| **Professional Plus** | Word, Excel, PowerPoint, Outlook, Access, Publisher, OneNote |
| **Standard** | Lo mismo, sin Access |
| **Home & Business** | Word, Excel, PowerPoint, Outlook, OneNote |
| **Personal** | Word, Excel, PowerPoint, OneNote |

Al cambiarla, las casillas de la derecha se ajustan solas. Si elige *Standard*, Access
se apaga: esa edición no lo incluye y no hay forma de añadirlo.

**Tercero, las aplicaciones.** Marque solo las que vaya a usar. **Lo que no marque no
se instala**, y cada una que quita es descarga y disco que se ahorra.

**Cuarto, idioma y arquitectura.** El idioma viene en español y la arquitectura en 64
bits, que es lo correcto en casi todos los equipos de hoy.

> **Con Office 2016 y 2013 la lista de aplicaciones se apaga entera.** No es un fallo:
> Microsoft sirve esas dos versiones por otra vía que descarga la suite completa y no
> admite excluir nada. OfficeGo lo avisa en pantalla al elegirlas.

### 6.3 · Revisar el resumen

A la derecha hay un resumen que se recalcula con cada cambio:

```
┌─────────────────────────────┐
│  RESUMEN                    │
│                             │
│  Office LTSC 2021           │
│  Professional Plus          │
│  Español (es-es) · 64 bits  │
│                             │
│  Word, Excel, PowerPoint    │
│                             │
│  Descarga:  1,4 GB          │  ← cambia según lo que marque
│                             │
│      [ Instalar ]           │
└─────────────────────────────┘
```

**Qué hacer:** léalo antes de pulsar. Es el último sitio donde se ve, de un vistazo,
exactamente qué se va a instalar.

### 6.4 · Confirmar y esperar

**Qué hacer:** pulse **Instalar** y confirme.

**Qué debería ver, en este orden:**

1. **Una barra de progreso con números reales**: los MB descargados de los totales.
   Está bajando el instalador de Microsoft, que es pequeño y va rápido.
2. **Una ventana azul de Microsoft**, con la animación de Office. Esta ya no es de
   OfficeGo: es el instalador oficial. **Aquí se descarga Office entero**, y es la
   parte larga.
3. Al terminar, un aviso de que ha acabado y la pregunta de si quiere activarlo.

> **No cierre nada mientras tanto.** La ventana azul puede parecer parada varios
> minutos: está descomprimiendo. Es normal y no significa que se haya colgado.

**Cómo saber que funcionó:** abra el menú Inicio y escriba `Word`. Debería aparecer.
Y las aplicaciones que **no** marcó no deberían aparecer.

### 6.5 · Activar

Después de instalar, o entrando en **Activar** desde la columna de la izquierda.

Hay dos caminos:

**Con su clave de producto.** Si tiene una clave de 25 caracteres, escríbala ahí. Es
lo correcto y lo legal.

**Con MAS.** Herramienta externa que OfficeGo ejecuta sin abrir su menú. Antes de
lanzarla conviene saber dos cosas:

1. **Windows Defender la detecta siempre**, por diseño, aunque no sea dañina. Lo
   advierte la propia web de massgrave.dev. Habrá que pausar la protección en tiempo
   real un momento y **volver a encenderla al terminar**.
2. Activar productos sin licencia va contra los términos de Microsoft.

---

## 7 · Cuando algo no sale

Busque las primeras palabras del mensaje que le salió.

### «No se puede cargar el archivo… la ejecución de scripts está deshabilitada»

Windows viene con los scripts bloqueados. Escriba esto y pulse <kbd>Enter</kbd>:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
```

Y a continuación, otra vez el comando de OfficeGo.

`-Scope Process` significa **solo en esta ventana**: al cerrarla, todo vuelve a su
sitio. No queda el equipo desprotegido.

### «irm no se reconoce como el nombre de un cmdlet»

Está en el **Símbolo del sistema**, no en PowerShell. Son dos ventanas parecidas:

| | Símbolo del sistema | PowerShell |
|---|---|---|
| Fondo | Negro | Azul oscuro |
| La línea empieza por | `C:\>` | `PS C:\>` |

Cierre y abra PowerShell como se explica en el [paso 1 de la Ruta A](#paso-1--abrir-powershell-como-administrador).

### «No se puede establecer conexión SSL/TLS»

Pasa en Windows viejos que salen configurados con TLS 1.0. Escriba esto antes:

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
```

OfficeGo ya lo hace por su cuenta al arrancar, así que esto solo hace falta si ni
siquiera consigue descargarse.

### Faltan permisos de administrador

Abrió PowerShell con «Abrir» en vez de «Ejecutar como administrador».

OfficeGo lo detecta y se ofrece a reiniciarse con permisos. Diga que sí y se abrirá
solo una ventana nueva, ya elevada. Si no, ciérrelo y repita desde el
[paso 1](#paso-1--abrir-powershell-como-administrador).

### La ventana sale con símbolos raros donde van los acentos

El archivo perdió su marca de codificación al copiarlo. Descárguelo otra vez del
release en lugar de copiar y pegar el texto a mano.

### La ventana parece congelada

Mire el contador. Si avanza, está trabajando. Descomprimir Office tarda varios
minutos sin que la barra se mueva.

### El antivirus borró algo durante la activación

Es lo esperado, y solo pasa con MAS, nunca con el instalador. Los activadores se
marcan siempre, por diseño de los antivirus. Está explicado en la pantalla Activar.

### Office se instaló pero falta una aplicación

Es lo que se pidió: lo que no se marca no se instala. Vuelva a pasar OfficeGo
marcando también esa aplicación.

Con Office 2016 y 2013 no se puede elegir, según lo explicado en [6.2](#62--elegir-la-versión).

### Falló la instalación y quiere saber por qué

Los registros quedan en dos sitios:

- `%TEMP%\OfficeGo` lo de OfficeGo
- `%TEMP%` los `.log` que deja el instalador de Microsoft

Para abrir esa carpeta: <kbd>Windows</kbd> + <kbd>R</kbd>, escriba `%TEMP%`, <kbd>Enter</kbd>.

---

## 8 · Sin tocar la ventana: opciones por escrito

Para dejar varios equipos igual, o para no ir eligiendo cada vez.

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/MariaDSalazar/officego/main/OfficeGo.ps1))) -Instalar 2021 -Apps Word,Excel
```

Ese `[scriptblock]::Create` de en medio no es adorno: con `irm | iex` no se pueden
pasar opciones, porque `iex` recibe el texto ya montado y no queda dónde engancharlas.

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

Para no repetir la dirección entera cada vez, guárdela en una variable:

```powershell
$og = 'https://raw.githubusercontent.com/MariaDSalazar/officego/main/OfficeGo.ps1'
```

Y a partir de ahí:

```powershell
# Word y Excel, nada más
& ([scriptblock]::Create((irm $og))) -Instalar 2021 -Apps Word,Excel

# Office 2024 Standard con Visio, activado al terminar
& ([scriptblock]::Create((irm $og))) -Instalar 2024 -Edicion Standard -Complementos VisioPro -Activar

# Un aula entera, sin que nadie toque nada
& ([scriptblock]::Create((irm $og))) -Instalar 2021 -Silencioso -Activar

# Solo activar un Office que ya está puesto
& ([scriptblock]::Create((irm $og))) -Activar

# Quitar Office
& ([scriptblock]::Create((irm $og))) -Desinstalar
```

Si abrió PowerShell sin permisos, OfficeGo se da cuenta, los pide y **se vuelve a
lanzar con las mismas opciones**. No hay que repetir nada.

Con el `.exe` descargado es igual de directo:

```powershell
.\OfficeGo.exe -Instalar 2021 -Apps Word,Excel
```

---

## 9 · Preguntas que salen siempre

**¿De dónde sale Office?**
De los servidores de Microsoft: `officecdn.microsoft.com` y
`c2rsetup.officeapps.live.com`. OfficeGo no aloja ni modifica ningún archivo.

**¿Hace falta desinstalar el Office que ya tengo?**
No. Si es otra versión, el instalador la sustituye. Si quiere dejarlo limpio antes,
en **Herramientas** está la opción de quitarlo.

**¿Borra mis documentos?**
No. Ni instalando ni desinstalando. Desinstalar quita los programas y deja los
archivos donde estén.

**¿Se puede volver atrás?**
Sí. En **Herramientas → Desinstalar Office**, o con `-Desinstalar`.

**¿Deja rastro en mi equipo?**
Las rutas A y B no instalan nada ni tocan el registro. Los temporales quedan en
`%TEMP%\OfficeGo` y se pueden borrar. La Ruta C sí instala, y se quita desde
Configuración como cualquier programa.

**¿Puedo usar las dos versiones a la vez?**
Sí, no se estorban.

**¿Necesito internet después?**
No. Office funciona sin conexión con normalidad.

**¿Puedo instalarlo en varios equipos sin descargar Office cada vez?**
Sí. En **Herramientas → Crear instalador sin conexión** se baja todo a una carpeta
que puede copiar a un USB.

---

<div align="center">
<sub>¿Se ha quedado con una duda que no está aquí?
<a href="https://github.com/MariaDSalazar/officego/issues/new">Abra un issue</a>.</sub>
</div>
