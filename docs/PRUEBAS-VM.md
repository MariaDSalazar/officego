# Cómo probar OfficeGo en una máquina virtual

Lista para ir marcando. Lo que falle, apúntalo con una captura: casi todo lo que
puede salir mal aquí es de posición de controles o de permisos, y se arregla rápido.

> **Haz un snapshot antes de empezar.** Vas a instalar y desinstalar Office varias
> veces; volver atrás en un clic ahorra la tarde.

---

## Preparar la máquina

| | |
|---|---|
| Sistema | Windows 10 o 11, cualquiera vale para empezar |
| RAM | 4 GB o más si vas a instalar Office de verdad |
| Disco | 20 GB libres como mínimo |
| Red | Con salida a internet |
| Snapshot | **Hecho antes de la primera prueba** |

---

## 1 · La versión de PowerShell (1.5)

> **Lo que se arregló en la 1.4 y hay que mirar primero.** La 1.3 salió con el
> comando roto y media ventana muerta. Si estas tres cosas van, lo demás es afinar:
>
> 1. El comando `irm ... | iex` **abre la ventana** (antes daba «assignment
>    expression is not valid»)
> 2. En **Instalar**, pulsar una tarjeta de versión **la resalta** (antes no pasaba nada)
> 3. Las seis tarjetas de versión están en **dos filas de tres**, sin montarse
>    unas encima de otras ni encima de los desplegables

### 1.1 Arranque con el comando

```powershell
irm https://raw.githubusercontent.com/MariaDSalazar/officego/main/OfficeGo.ps1 | iex
```

- [ ] La ventana se abre
- [ ] No hay ningún control encima de otro, ni texto cortado
- [ ] Los acentos y las eñes se ven bien
- [ ] Las seis tarjetas de versión están en dos filas de tres
- [ ] La barra inferior muestra Windows, permisos, disco, conexión y Defender

### 1.2 Con la pantalla al 125 %

Configuración → Sistema → Pantalla → **Escala: 125 %**, cerrar sesión y volver a entrar.

- [ ] La ventana se ve algo menos nítida, pero **proporcionada**
- [ ] No hay ni un control encima de otro
- [ ] Repetir a 150 %

Es lo que hace la mitad de los portátiles de fábrica, así que no es un caso raro.

### 1.3 Sin permisos de administrador

Abre PowerShell **normal**, sin elevar, y ejecuta el mismo comando.

- [ ] Avisa de que faltan permisos y ofrece reiniciarse elevado
- [ ] Si dices que no, deja mirar las pantallas sin romperse

### 1.4 Pantalla de inicio

- [ ] La recomendación coincide con la máquina (mira la tabla de abajo)
- [ ] El botón «Instalar esto» lleva a Instalar con esa versión ya marcada

### 1.5 Pantalla Instalar

Aquí es donde estaba casi todo lo roto de la 1.3, así que conviene ir despacio.

- [ ] Al pulsar otra versión, la tarjeta se resalta
- [ ] Pulsar **justo encima del icono** o **del nombre** también la selecciona
- [ ] Al marcar y desmarcar una aplicación, la casilla cambia de color
- [ ] El botón «Instalar esto» de la pantalla de inicio deja marcada esa versión
- [ ] Con **Standard**, Access se apaga solo
- [ ] Con **Office 2016**, desaparece la lista de aplicaciones y sale el aviso
- [ ] Con **Personal**, Outlook se apaga
- [ ] El tamaño del resumen cambia al marcar Visio o Project
- [ ] Cambiar idioma y arquitectura no rompe nada

### 1.6 Instalar de verdad

Elige **Office LTSC 2021 · Professional Plus** con solo Word y Excel.

- [ ] Pide confirmación antes de tocar nada
- [ ] La barra de descarga avanza con números reales, no a saltos
- [ ] Se abre la ventana azul de Microsoft
- [ ] Al terminar avisa y ofrece activar
- [ ] En el menú Inicio están **Word y Excel**, y **no** PowerPoint

> Esta es la prueba más importante: confirma que el `configuration.xml` se generó bien.

### 1.7 Pantalla Equipo

- [ ] El procesador, la RAM y los discos coinciden con lo que dice Windows
- [ ] La marca de la gráfica es la correcta (en una VM suele salir «Sin controlador»,
      lo cual es correcto: es el adaptador virtual)
- [ ] «Copiar informe» deja algo pegable en el portapapeles

### 1.8 Herramientas

- [ ] Desinstalar pide escribir `BORRAR` y no hace nada si escribes otra cosa
- [ ] Desinstalar de verdad quita Office

---

### 1.9 Con opciones, sin ventana

Lo nuevo de la 1.3, y lo que más conviene probar porque nunca ha corrido en Windows.

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/MariaDSalazar/officego/main/OfficeGo.ps1))) -Ayuda
```

- [ ] Sale la ayuda **sin abrir ninguna ventana**
- [ ] Los acentos se ven bien también aquí

Con PowerShell **sin elevar**, y una orden de verdad:

```powershell
& ([scriptblock]::Create((irm https://.../OfficeGo.ps1))) -Instalar 2021 -Apps Word,Excel
```

- [ ] Windows pide permisos
- [ ] Al aceptar, **la ventana nueva sigue con las mismas opciones**, no vuelve al principio
- [ ] Instala Word y Excel, y **no** PowerPoint

> Esta es la prueba clave del relanzado: el script llegó por internet, así que no
> había ningún archivo en disco al que apuntar. Tuvo que guardarse solo en `%TEMP%`.

Desatendido entero, con PowerShell **ya elevado**:

```powershell
& ([scriptblock]::Create((irm https://.../OfficeGo.ps1))) -Instalar 2021 -Silencioso
```

- [ ] **No** aparece la ventana azul de Microsoft en ningún momento
- [ ] La barra de progreso de PowerShell avanza
- [ ] Al terminar, Office está puesto

Y las equivocaciones:

- [ ] `-Instalar 9999` lo rechaza al momento diciendo qué versiones hay
- [ ] `-Instalar 2021 -Edicion Business` avisa de que esa edición no existe ahí
- [ ] `-Silencioso` a secas dice qué falta **sin pedir permisos antes**

---

## 2 · La versión Tauri (2.0)

Baja `OfficeGo_2.0.0_x64-setup.exe` del release.

- [ ] SmartScreen avisa: «Más información» → «Ejecutar de todas formas» (es lo esperado
      en un ejecutable sin firmar)
- [ ] Instala y abre
- [ ] **La ventana se ve igual que los diseños**, que es el motivo de esta versión
- [ ] Los datos del equipo son reales, no los de ejemplo
- [ ] La barra de progreso se mueve durante una descarga

### En un Windows 10 sin actualizar

- [ ] Si falta WebView2, comprobar qué mensaje sale exactamente

Ese es el punto flaco conocido de esta versión y conviene documentar el mensaje real.

---

## 3 · Qué debería recomendar

Levanta varias VM o cambia la RAM para comprobarlo:

| Máquina | Recomendación esperada |
|---|---|
| Windows 11 · 8 GB | Office 2024 |
| Windows 10 22H2 (19045) · 8 GB | Office 2024 |
| Windows 10 1909 (18363) · 8 GB | Office 2021 |
| Windows 10 1507 (10240) · 8 GB | Office 2019 |
| Cualquiera · **3 GB de RAM** | Office 2016, mande lo que mande el Windows |
| Cualquiera · menos de 5 GB libres | Aviso rojo de espacio |

La RAM manda sobre la versión de Windows: es a propósito.

---

## 4 · Errores que hay que provocar a posta

Para comprobar que los mensajes de ayuda dicen la verdad:

**Política de ejecución.** En la VM:
```powershell
Set-ExecutionPolicy Restricted -Scope CurrentUser -Force
```
- [ ] Sale el error esperado y la solución del manual lo arregla
- [ ] Devolverlo después: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force`

**Sin internet.** Desconecta el adaptador de red.
- [ ] Avisa de que no hay conexión y no se queda colgado

**Disco lleno.** Llena el disco hasta dejar menos de 5 GB.
- [ ] Sale el aviso rojo y no deja instalar

---

## 5 · Activación

Solo si vas a probarla, y en la VM con snapshot.

- [ ] El aviso del antivirus sale **antes** de ejecutar nada
- [ ] Con Defender encendido: comprobar si lo interrumpe y cómo lo cuenta
- [ ] Con Defender pausado: comprobar que termina y que el estado pasa a activado
- [ ] **Volver a encender Defender**

---

## Qué apuntar de lo que falle

Para cada fallo, esto basta para arreglarlo:

1. Captura de la ventana
2. Qué versión de Windows (`winver`)
3. Qué estabas haciendo
4. Si sale error en rojo, el texto entero

Los registros quedan en `%TEMP%\OfficeGo` y `%TEMP%` (los `.log` de Microsoft).
