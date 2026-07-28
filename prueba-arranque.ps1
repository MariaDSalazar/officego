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

function Comprobar($nombre, $condicion, $detalle = '') {
  if ($condicion) { Write-Host "  ok   $nombre" -ForegroundColor Green }
  else { Write-Host "  FALLA $nombre  $detalle" -ForegroundColor Red; $script:fallos++ }
}

# Lanza un PowerShell hijo y devuelve todo lo que escriba
function Ejecutar([string]$orden) {
  (& $ps -NoProfile -NonInteractive -Command $orden 2>&1) -join "`n"
}

Write-Host "`nEL ARCHIVO" -ForegroundColor Cyan
$bytes = [IO.File]::ReadAllBytes($archivo)
Comprobar 'no lleva BOM' (-not ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)) `
  'con BOM, param() se rompe al llegar como texto'

$texto = [IO.File]::ReadAllText($archivo, [Text.UTF8Encoding]::new($false))
Comprobar 'es UTF-8 válido' ($texto -notmatch [char]0xFFFD)

$ast = [System.Management.Automation.Language.Parser]::ParseInput($texto, [ref]$null, [ref]$null)
Comprobar 'declara un bloque param' ($null -ne $ast.ParamBlock)
Comprobar 'trae la relectura por los acentos' ($texto -match "PSCommandPath -and 'á'\.Length")

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
Write-Host "  Queda por comprobar en Windows con PowerShell 5.1: que al leer el" -ForegroundColor DarkGray
Write-Host "  archivo en ANSI se relea solo. Aquí no se puede: pwsh lee UTF-8" -ForegroundColor DarkGray
Write-Host "  siempre, así que nunca llega a hacer falta. Está en PRUEBAS-VM.md" -ForegroundColor DarkGray

Write-Host ""
if ($script:fallos) { Write-Host "$script:fallos prueba(s) fallando" -ForegroundColor Red; exit 1 }
Write-Host "El arranque funciona por las dos vías" -ForegroundColor Green
# exit 0 explícito: varios casos lanzan un PowerShell hijo que termina en
# error a propósito, y ese código se queda en $LASTEXITCODE. Sin esto, la
# prueba pasa pero el paso sale como fallido.
exit 0
