# =====================================================================
#  Comprueba que las tres capas de la versión 2.0 encajan.
#
#  Interfaz web → Rust → PowerShell. Cada una habla con la siguiente por
#  nombres sueltos en cadenas de texto, que nadie verifica: el botón
#  «Solo descargar» llamaba a una acción que no existía en el puente y
#  respondía «Acción desconocida» sin que nada lo avisara.
#
#      pwsh prueba-tauri.ps1
# =====================================================================
$ErrorActionPreference = 'Continue'
$fallos = 0
$raiz = $PSScriptRoot

function Comprobar($nombre, $condicion, $detalle = '') {
  if ($condicion) { Write-Host "  ok   $nombre" -ForegroundColor Green }
  else { Write-Host "  FALLA $nombre  $detalle" -ForegroundColor Red; $script:fallos++ }
}

$api  = Get-Content "$raiz/tauri/src-tauri/motor-api.ps1" -Raw
$js   = Get-Content "$raiz/tauri/ui/app.js" -Raw
$rust = Get-Content "$raiz/tauri/src-tauri/src/main.rs" -Raw
$html = Get-Content "$raiz/tauri/ui/index.html" -Raw
$css  = Get-Content "$raiz/tauri/ui/estilo.css" -Raw

# ── 1 · las acciones que pide la interfaz tienen que estar en el puente
Write-Host "`nLA INTERFAZ Y EL PUENTE" -ForegroundColor Cyan
$delPuente = [regex]::Matches($api, "(?m)^    '([a-z-]+)' \{") | ForEach-Object { $_.Groups[1].Value }
$pedidas = @()
foreach ($patron in "consultar\(\s*'([a-z-]+)'", "tarea\(\s*'([a-z-]+)'") {
  $pedidas += [regex]::Matches($js, $patron) | ForEach-Object { $_.Groups[1].Value }
}
$pedidas = @($pedidas | Sort-Object -Unique)
Comprobar 'la interfaz pide alguna acción' ($pedidas.Count -gt 0)
foreach ($a in $pedidas) {
  Comprobar "«$a» existe en el puente" ($a -in $delPuente) "el puente tiene: $($delPuente -join ', ')"
}
$sinUsar = @($delPuente | Where-Object { $_ -notin $pedidas })
if ($sinUsar) { Write-Host "  (sin usar desde la interfaz: $($sinUsar -join ', '))" -ForegroundColor DarkGray }

# ── 2 · los comandos de Rust
Write-Host "`nLA INTERFAZ Y RUST" -ForegroundColor Cyan
$deRust = [regex]::Matches($rust, '(?m)^async fn (\w+)|(?m)^fn (\w+)\(') |
  ForEach-Object { if ($_.Groups[1].Value) { $_.Groups[1].Value } else { $_.Groups[2].Value } }
$deRust += [regex]::Matches($rust, 'generate_handler!\[([^\]]+)\]') |
  ForEach-Object { $_.Groups[1].Value -split ',' } | ForEach-Object { $_.Trim() }
$invocados = @([regex]::Matches($js, "invoke\(\s*'(\w+)'") | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
foreach ($i in $invocados) {
  Comprobar "invoke('$i') existe en main.rs" ($i -in $deRust) "main.rs expone: $($deRust -join ', ')"
}

# ── 3 · el motor que Rust incrusta tiene que existir
Write-Host "`nRUST Y EL MOTOR" -ForegroundColor Cyan
$incluidos = [regex]::Matches($rust, 'include_str!\("([^"]+)"\)') | ForEach-Object { $_.Groups[1].Value }
foreach ($ruta in $incluidos) {
  $completa = Join-Path "$raiz/tauri/src-tauri/src" $ruta
  Comprobar "include_str! $ruta" (Test-Path $completa)
}

# El puente carga el motor de una subcarpeta «motor», que no está en el
# repositorio: la crea main.rs en %TEMP% al arrancar. Los nombres tienen
# que coincidir o el puente no encuentra nada.
$cargados = [regex]::Matches($api, '\$PSScriptRoot\\motor\\([\w.-]+\.ps1)') | ForEach-Object { $_.Groups[1].Value }
$escritos = [regex]::Matches($rust, 'sub\.join\("([^"]+)"\)') | ForEach-Object { $_.Groups[1].Value }
Comprobar 'el puente carga tres archivos del motor' ($cargados.Count -eq 3) "carga $($cargados.Count)"
foreach ($c in $cargados) {
  Comprobar "main.rs deja «$c» donde el puente lo busca" ($c -in $escritos) "main.rs escribe: $($escritos -join ', ')"
}

# ── 4 · el puente no puede pedirle al catálogo campos que no tiene
Write-Host "`nEL PUENTE Y EL CATÁLOGO" -ForegroundColor Cyan
. "$raiz/src/1-catalogo.ps1"
foreach ($campo in 'Clave','Nombre','Sub','Sigla','Color','Tipo','Via','Peso','Ediciones') {
  $faltan = @($script:PRODUCTOS | Where-Object { -not $_.ContainsKey($campo) })
  Comprobar "todo producto tiene $campo" ($faltan.Count -eq 0) `
    $(if ($faltan.Count) { "sin $campo`: $($faltan.Clave -join ', ')" })
}
foreach ($campo in 'Clave','Nombre','Sigla','Color','Ids') {
  $faltan = @($script:COMPLEMENTOS | Where-Object { -not $_.ContainsKey($campo) })
  Comprobar "todo complemento tiene $campo" ($faltan.Count -eq 0)
}

# ── 5 · sintaxis, que es gratis comprobar
Write-Host "`nQUE TODO PARSEE" -ForegroundColor Cyan
$err = $null
[void][System.Management.Automation.Language.Parser]::ParseFile(
  "$raiz/tauri/src-tauri/motor-api.ps1", [ref]$null, [ref]$err)
Comprobar 'motor-api.ps1 parsea' (-not $err) $(if ($err) { "línea $($err[0].Extent.StartLineNumber): $($err[0].Message)" })

Comprobar 'index.html carga app.js y estilo.css' (
  $html -match 'app\.js' -and $html -match 'estilo\.css')

# las clases que usa el JS deberían estar en el CSS, o la ventana sale sin pintar
$clases = @([regex]::Matches($js, 'class="([a-z0-9 _-]+)"') |
  ForEach-Object { $_.Groups[1].Value -split ' ' } | Where-Object { $_ } | Sort-Object -Unique)
$sinEstilo = @($clases | Where-Object { $css -notmatch "\.$([regex]::Escape($_))[\s,{:.]" })
Comprobar 'toda clase del JS tiene estilo' ($sinEstilo.Count -eq 0) "sin estilo: $($sinEstilo -join ', ')"

Write-Host ""
if ($fallos) { Write-Host "$fallos prueba(s) fallando" -ForegroundColor Red; exit 1 }
Write-Host "Las tres capas de la versión 2.0 encajan" -ForegroundColor Green
exit 0
