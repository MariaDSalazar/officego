# =====================================================================
#  Comprueba que OfficeGo.exe sirve para algo.
#
#  El .exe lleva OfficeGo.ps1 dentro como recurso incrustado, lo deja en
#  %TEMP% y lo ejecuta. Hasta ahora la compilación se daba por buena si
#  csc.exe no protestaba, sin mirar el resultado: si el recurso no
#  entraba, o entraba a medias, se descubría al abrirlo.
#
#  Solo corre en Windows y necesita OfficeGo.exe ya compilado.
#
#      powershell -File prueba-exe.ps1
# =====================================================================
$ErrorActionPreference = 'Continue'
$fallos = 0
Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue
$exe = Join-Path $PSScriptRoot 'OfficeGo.exe'
$ps1 = Join-Path $PSScriptRoot 'OfficeGo.ps1'

function Comprobar($nombre, $condicion, $detalle = '') {
  if ($condicion) { Write-Host "  ok   $nombre" -ForegroundColor Green }
  else { Write-Host "  FALLA $nombre  $detalle" -ForegroundColor Red; $script:fallos++ }
}

Write-Host "`nEL EJECUTABLE" -ForegroundColor Cyan

if (-not (Test-Path $exe)) {
  Write-Host "  No hay OfficeGo.exe. Ejecute antes compilar-exe.bat" -ForegroundColor Yellow
  exit 0
}

$info = Get-Item $exe
Comprobar 'existe y no está vacío' ($info.Length -gt 10KB) "mide $($info.Length) bytes"

# ── el recurso incrustado tiene que ser exactamente el script
$asm = [Reflection.Assembly]::LoadFile($exe)
$nombres = $asm.GetManifestResourceNames()
Comprobar 'lleva el recurso «script»' ('script' -in $nombres) "lleva: $($nombres -join ', ')"

if ('script' -in $nombres) {
  $flujo = $asm.GetManifestResourceStream('script')
  $buf = New-Object byte[] $flujo.Length
  [void]$flujo.Read($buf, 0, $buf.Length)
  $flujo.Close()

  $original = [IO.File]::ReadAllBytes($ps1)
  Comprobar 'el recurso pesa lo mismo que OfficeGo.ps1' ($buf.Length -eq $original.Length) `
    "recurso $($buf.Length) B, archivo $($original.Length) B"

  $iguales = $buf.Length -eq $original.Length
  if ($iguales) {
    for ($i = 0; $i -lt $buf.Length; $i++) {
      if ($buf[$i] -ne $original[$i]) { $iguales = $false; break }
    }
  }
  Comprobar 'y es byte a byte el mismo' $iguales

  # ── y que lo que lleva dentro siga siendo un script válido
  $texto = [Text.UTF8Encoding]::new($false).GetString($buf)
  $errores = $null
  $ast = [System.Management.Automation.Language.Parser]::ParseInput($texto, [ref]$null, [ref]$errores)
  Comprobar 'el script incrustado parsea' (-not $errores) `
    $(if ($errores) { $errores[0].Message })
  Comprobar 'y sigue admitiendo opciones' ($null -ne $ast.ParamBlock)
}

# ── el icono, que es medio motivo de compilarlo
$icono = [Drawing.Icon]::ExtractAssociatedIcon($exe)
Comprobar 'tiene icono propio' ($null -ne $icono)

# ── que arranque de verdad: -Ayuda no toca el equipo y responde y termina
Write-Host "`nQUE ARRANQUE" -ForegroundColor Cyan
# El .exe lanza PowerShell y se va, así que su salida no se puede capturar
# desde aquí. Lo que sí se puede comprobar es lo que deja hecho: que
# termine solo, sin error, y que la copia de %TEMP% esté bien escrita.
Get-ChildItem ([IO.Path]::GetTempPath()) -Filter 'OfficeGo-*.ps1' -ErrorAction SilentlyContinue |
  Remove-Item -Force -ErrorAction SilentlyContinue

$p = Start-Process $exe -ArgumentList '-Ayuda' -PassThru -WindowStyle Minimized
$p.WaitForExit(20000) | Out-Null
Comprobar 'el .exe termina solo' ($p.HasExited)
Comprobar 'y no devuelve error' ($p.ExitCode -eq 0) "código $($p.ExitCode)"

# ── deja el script en %TEMP% para que PowerShell lo ejecute
Start-Sleep -Seconds 2
$copias = @(Get-ChildItem ([IO.Path]::GetTempPath()) -Filter 'OfficeGo-*.ps1' -ErrorAction SilentlyContinue)
Comprobar 'deja el script en %TEMP%' ($copias.Count -ge 1)
if ($copias.Count) {
  $b = [IO.File]::ReadAllBytes($copias[0].FullName)
  Comprobar 'y esa copia sí lleva BOM' ($b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF) `
    'sin BOM, PowerShell 5.1 la lee en ANSI y tiene que releerse'
}

# Con opciones el .exe abre la consola con -NoExit, así que queda esperando.
# Se cierra solo el que lanzó él, reconocible por el OfficeGo-*.ps1 de su
# línea de órdenes: matar powershells a ciegas en un runner es mala idea.
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue |
  Where-Object { $_.CommandLine -and $_.CommandLine -match 'OfficeGo-\d+\.ps1' -and $_.ProcessId -ne $PID } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

Write-Host ""
if ($fallos) { Write-Host "$fallos prueba(s) fallando" -ForegroundColor Red; exit 1 }
Write-Host "El ejecutable está bien montado" -ForegroundColor Green
exit 0
