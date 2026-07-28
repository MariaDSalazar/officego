# =====================================================================
#  Comprueba que OfficeGo.ps1 arranca por las vías reales.
#
#  Existe porque la 1.3 se subió rota: param() no sobrevive al BOM
#  cuando el script llega como texto, y todas las pruebas de entonces
#  usaban -File, que es justo la única vía que funcionaba.
#
#  Cada caso se lanza en un PowerShell aparte, como pasa de verdad. Si
#  se ejecutara aquí dentro, Write-Host escribe directo a la consola y
#  la prueba no mediría nada.
#
#      pwsh prueba-arranque.ps1
# =====================================================================
$ErrorActionPreference = 'Continue'
$script:fallos = 0
$archivo = Join-Path $PSScriptRoot 'OfficeGo.ps1'
$ps = (Get-Process -Id $PID).Path

# La tubería entre procesos usa la página de códigos de la consola, que
# en PowerShell 5.1 no es UTF-8: sin esto, los acentos llegan rotos aquí
# aunque el script los haya escrito bien, y la prueba culpa a quien no es.
try { [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false) } catch {}

$script:ultimaSalida = ''
function Comprobar($nombre, $condicion, $detalle = '') {
  if ($condicion) { Write-Host "  ok   $nombre" -ForegroundColor Green; return }
  Write-Host "  FALLA $nombre  $detalle" -ForegroundColor Red
  $script:fallos++
  if ($script:ultimaSalida) {
    Write-Host "         ── lo que respondió ──" -ForegroundColor DarkGray
    foreach ($l in ($script:ultimaSalida -split "`n" | Select-Object -First 40)) {
      Write-Host "         $l" -ForegroundColor DarkGray
    }
    Write-Host "         ──────────────────────" -ForegroundColor DarkGray
  }
}

# Lanza un PowerShell hijo y devuelve todo lo que escriba
function Ejecutar([string]$orden) {
  $completa = "[Console]::OutputEncoding = [Text.UTF8Encoding]::new(`$false); $orden"
  $script:ultimaSalida = (& $ps -NoProfile -NonInteractive -Command $completa 2>&1) -join "`n"
  $script:ultimaSalida
}

Write-Host "`nEL ARCHIVO" -ForegroundColor Cyan
$script:ultimaSalida = ''
$bytes = [IO.File]::ReadAllBytes($archivo)
Comprobar 'no lleva BOM' (-not ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)) `
  'con BOM, param() se rompe al llegar como texto'

$texto = [IO.File]::ReadAllText($archivo, [Text.UTF8Encoding]::new($false))
Comprobar 'es UTF-8 válido' ($texto -notmatch [char]0xFFFD)

$ast = [System.Management.Automation.Language.Parser]::ParseInput($texto, [ref]$null, [ref]$null)
Comprobar 'declara un bloque param' ($null -ne $ast.ParamBlock)
Comprobar 'trae la relectura por los acentos' ($texto -match "PSCommandPath -and 'á'\.Length")

# La prueba que faltaba: leer el archivo como lo lee PowerShell 5.1 y
# comprobar que TODAVÍA parsea.
#
# Sin BOM, 5.1 lee en ANSI y cada carácter UTF-8 se parte en dos. El
# problema es que PowerShell acepta las comillas tipográficas ' ' " "
# como delimitadores de cadena, y en Windows-1252 esas son justo los
# bytes 0x91-0x94. Así que una flecha → (E2 86 92) mete un ' en mitad
# de una cadena, la cierra antes de tiempo y el archivo deja de parsear
# entero. Cuando pasa, la relectura de los acentos ni siquiera llega a
# ejecutarse: el script no arranca.
$comoAnsi = [Text.Encoding]::GetEncoding(1252).GetString($bytes)
$errores = $null
[void][System.Management.Automation.Language.Parser]::ParseInput($comoAnsi, [ref]$null, [ref]$errores)
Comprobar 'sigue parseando aunque se lea en ANSI' (-not $errores) `
  $(if ($errores) { "línea $($errores[0].Extent.StartLineNumber): $($errores[0].Message)" })

# y de dónde vendría el problema, para poder arreglarlo sin adivinar
$culpables = @{}
foreach ($linea in ($texto -split "`n")) {
  if ($linea.TrimStart().StartsWith('#')) { continue }   # en un comentario da igual
  foreach ($c in $linea.ToCharArray()) {
    if ([int]$c -lt 128) { continue }
    $b = [Text.Encoding]::UTF8.GetBytes([string]$c)
    if ($b | Where-Object { $_ -in 0x82, 0x84, 0x91, 0x92, 0x93, 0x94 }) { $culpables[$c] = $true }
  }
}
Comprobar 'ningún carácter se convierte en comilla al leerse en ANSI' ($culpables.Count -eq 0) `
  $(if ($culpables.Count) { "son: $(($culpables.Keys | ForEach-Object { "$_ (U+{0:X4})" -f [int]$_ }) -join ', ')" })

# Al revés que OfficeGo.ps1, las pruebas SÍ llevan BOM: no llegan nunca
# por internet, y sin él PowerShell 5.1 las lee en ANSI y los textos con
# acentos que buscan aquí abajo dejan de coincidir.
foreach ($f in @('test.ps1', 'prueba-arranque.ps1', 'prueba-interfaz.ps1')) {
  $b = [IO.File]::ReadAllBytes((Join-Path $PSScriptRoot $f))
  Comprobar "$f lleva BOM" ($b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF)
}

# ── vía 1 · como texto: es la de irm | iex y la de scriptblock::Create
Write-Host "`nVÍA 1 · COMO TEXTO   (irm | iex · scriptblock::Create)" -ForegroundColor Cyan
$leer = "[IO.File]::ReadAllText('$archivo',[Text.UTF8Encoding]::new(`$false))"

$s = Ejecutar "& ([scriptblock]::Create($leer)) -Ayuda"
Comprobar 'monta el bloque sin error' ($s -notmatch 'assignment expression|not recognized|ParseException') `
  (($s -split "`n")[0])
Comprobar 'acepta -Ayuda y responde'   ($s -match 'OPCIONES')
Comprobar 'los acentos llegan enteros' ($s -match 'parámetros')
Comprobar 'no monta la interfaz'       ($s -notmatch 'Windows\.Forms')

$s = Ejecutar "([scriptblock]::Create($leer)) | Out-Null; 'parseado'"
Comprobar 'con iex tampoco reventaría' ($s -match 'parseado')

# ── vía 2 · como archivo, que es lo del .exe, el .cmd y .\OfficeGo.ps1
Write-Host "`nVÍA 2 · COMO ARCHIVO   (-File)" -ForegroundColor Cyan
$s = Ejecutar "& '$archivo' -Ayuda"
Comprobar 'responde'                   ($s -match 'OPCIONES')
Comprobar 'los acentos salen enteros'  ($s -match 'parámetros')
Comprobar 'no se relee sin motivo'     ((($s -split 'EJEMPLOS').Count - 1) -eq 1) `
  'la ayuda sale dos veces: está entrando en la relectura sin hacer falta'

# ── vía 3 · las opciones llegan de verdad, no solo se parsean
Write-Host "`nLAS OPCIONES LLEGAN" -ForegroundColor Cyan
$s = Ejecutar "& ([scriptblock]::Create($leer)) -Silencioso"
Comprobar 'sin orden, avisa de qué falta' ($s -match 'necesita saber qué hacer')
Comprobar 'y no pide permisos antes'      ($s -notmatch 'Pidiéndolos')

$s = Ejecutar "& ([scriptblock]::Create($leer)) -Instalar 9999"
Comprobar 'rechaza una versión inventada' ($s -match 'ValidateSet|does not belong|no pertenece')

# Lo que sigue comprueba que se avisa ANTES de pedir permisos: si el
# mensaje sale, es que se validó primero, porque sin permisos no se pasa de ahí.
$s = Ejecutar "& ([scriptblock]::Create($leer)) -Instalar 2021 -Edicion Business"
Comprobar 'rechaza una edición que esa versión no trae' ($s -match 'no tiene la edición')
Comprobar 'y lo dice antes de pedir permisos'           ($s -notmatch 'Pidiéndolos')

$s = Ejecutar "& ([scriptblock]::Create($leer)) -Instalar 2021 -Apps Word,Excell"
Comprobar 'rechaza una aplicación mal escrita' ($s -match 'No existe Excell')

$s = Ejecutar "& ([scriptblock]::Create($leer)) -Instalar 2016 -Complementos VisioPro"
Comprobar 'avisa si el complemento no sale para esa versión' ($s -match 'no sale para')

$s = Ejecutar "& ([scriptblock]::Create($leer)) -Instalar 2021 -Idioma xx-xx"
Comprobar 'rechaza un idioma que no está' ($s -match 'no está en la lista')

Write-Host ""
if ($PSVersionTable.PSVersion.Major -le 5) {
  Write-Host "  Corriendo en PowerShell $($PSVersionTable.PSVersion): la vía 2 de arriba ha" -ForegroundColor DarkGray
  Write-Host "  probado de verdad la relectura, porque este PowerShell lee en ANSI" -ForegroundColor DarkGray
  Write-Host "  todo archivo sin BOM y OfficeGo.ps1 no lo lleva." -ForegroundColor DarkGray
} else {
  Write-Host "  Queda por comprobar en el PowerShell 5.1 que trae Windows: que al" -ForegroundColor DarkGray
  Write-Host "  leer el archivo en ANSI se relea solo. Aquí no llega a hacer falta," -ForegroundColor DarkGray
  Write-Host "  porque PowerShell $($PSVersionTable.PSVersion.Major) lee UTF-8 siempre." -ForegroundColor DarkGray
}

Write-Host ""
if ($script:fallos) { Write-Host "$script:fallos prueba(s) fallando" -ForegroundColor Red; exit 1 }
Write-Host "El arranque funciona por las dos vías" -ForegroundColor Green
# exit 0 explícito: varios casos lanzan un PowerShell hijo que termina en
# error a propósito, y ese código se queda en $LASTEXITCODE. Sin esto, la
# prueba pasa pero el paso sale como fallido.
exit 0
