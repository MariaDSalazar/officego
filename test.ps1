# =====================================================================
#  Pruebas de OfficeGo · la lógica que no necesita Windows
#  Se pueden correr en cualquier sitio con PowerShell:  pwsh test.ps1
# =====================================================================
$ErrorActionPreference = 'Stop'
if (-not $env:TEMP) { $env:TEMP = '/tmp' }

. "$PSScriptRoot/src/1-catalogo.ps1"
. "$PSScriptRoot/src/2-motor.ps1"
. "$PSScriptRoot/src/2b-recomendacion.ps1"

$fallos = 0
function Comprobar($nombre, $condicion, $detalle = '') {
  if ($condicion) { Write-Host "  ok   $nombre" -ForegroundColor Green }
  else { Write-Host "  FALLA $nombre  $detalle" -ForegroundColor Red; $script:fallos++ }
}

Write-Host "`nCATÁLOGO" -ForegroundColor Cyan
Comprobar 'hay 6 versiones' ($PRODUCTOS.Count -eq 6) "son $($PRODUCTOS.Count)"
Comprobar 'todas tienen vía ODT o C2R' (-not ($PRODUCTOS | Where-Object { $_.Via -notin 'ODT','C2R' }))
Comprobar 'las de ODT llevan canal' (-not ($PRODUCTOS | Where-Object { $_.Via -eq 'ODT' -and -not $_.Canal }))
Comprobar 'las de C2R llevan versión' (-not ($PRODUCTOS | Where-Object { $_.Via -eq 'C2R' -and -not $_.Version }))
Comprobar 'toda edición del catálogo está definida' (
  -not ($PRODUCTOS | ForEach-Object { $_.Ediciones.Keys } | Where-Object { -not $EDICIONES[$_] }))
Comprobar 'ninguna edición inventa aplicaciones' (
  -not ($EDICIONES.Values | ForEach-Object { $_.Apps } | Where-Object { -not $APLICACIONES[$_] }))

Write-Host "`nEDICIONES" -ForegroundColor Cyan
Comprobar 'Standard no trae Access'   ('Access'  -notin $EDICIONES.Standard.Apps)
Comprobar 'ProPlus sí trae Access'    ('Access'  -in    $EDICIONES.ProPlus.Apps)
Comprobar 'Personal no trae Outlook'  ('Outlook' -notin $EDICIONES.Personal.Apps)
Comprobar 'HomeBusiness no trae Publisher' ('Publisher' -notin $EDICIONES.HomeBusiness.Apps)

Write-Host "`nAPLICACIONES SEGÚN LA VÍA" -ForegroundColor Cyan
$p2021 = Get-Producto '2021'
$p2016 = Get-Producto '2016'
Comprobar 'por ODT se pueden elegir apps'  ((Get-AppsDeEdicion $p2021 'ProPlus').Count -gt 0)
Comprobar 'por C2R no se puede elegir'     ((Get-AppsDeEdicion $p2016 'ProPlus').Count -eq 0)

Write-Host "`nCONFIGURATION.XML" -ForegroundColor Cyan
$ruta = New-ConfiguracionXml $p2021 'ProPlus' 'es-es' '64' @('Word','Excel') @()
$xml = [xml](Get-Content $ruta -Raw)
$prod = $xml.Configuration.Add.Product | Select-Object -First 1
Comprobar 'es XML válido'            ($null -ne $xml)
Comprobar 'Product ID correcto'      ($prod.ID -eq 'ProPlus2021Volume') $prod.ID
Comprobar 'canal correcto'           ($xml.Configuration.Add.Channel -eq 'PerpetualVL2021')
Comprobar 'arquitectura correcta'    ($xml.Configuration.Add.OfficeClientEdition -eq '64')
Comprobar 'idioma correcto'          ($prod.Language.ID -eq 'es-es')
$fuera = @($prod.ExcludeApp.ID)
Comprobar 'PowerPoint excluido si no se pidió' ('PowerPoint' -in $fuera)
Comprobar 'Word NO excluido'         ('Word'  -notin $fuera)
Comprobar 'Excel NO excluido'        ('Excel' -notin $fuera)
Comprobar 'Access excluido'          ('Access' -in $fuera)
Comprobar 'no se excluye nada inventado' (
  -not ($fuera | Where-Object { $_ -notin @('Access','Excel','Groove','Lync','OneDrive','OneNote',
        'Outlook','OutlookForWindows','PowerPoint','Publisher','Teams','Word') }))

Write-Host "`nCOMPLEMENTOS" -ForegroundColor Cyan
$ruta2 = New-ConfiguracionXml $p2021 'ProPlus' 'es-es' '64' @('Word') @('VisioPro','ProjectPro')
$xml2 = [xml](Get-Content $ruta2 -Raw)
$ids = @($xml2.Configuration.Add.Product.ID)
Comprobar 'Visio se añade como producto aparte'   ('VisioPro2021Volume'   -in $ids) ($ids -join ',')
Comprobar 'Project se añade como producto aparte' ('ProjectPro2021Volume' -in $ids)
Comprobar 'son tres productos en total' ($ids.Count -eq 3) "son $($ids.Count)"

Write-Host "`nRECOMENDACIÓN" -ForegroundColor Cyan
function EquipoFalso($build, $ram, $libre, $gpu = 'NVIDIA GeForce GTX 1650', $bits = '64') {
  [pscustomobject]@{
    Build = "$build.1"; RamGB = $ram; Bits = $bits; GPU = $gpu; Defender = $false
    Discos = @([pscustomobject]@{ Letra='C:'; LibreGB=$libre; Sistema=$true })
  }
}
Comprobar 'Windows 11 moderno -> 2024' ((Get-Recomendacion (EquipoFalso 22631 16 200)).Clave -eq '2024')
Comprobar 'Windows 10 22H2   -> 2024' ((Get-Recomendacion (EquipoFalso 19045 16 200)).Clave -eq '2024')
Comprobar 'Windows 10 1909   -> 2021' ((Get-Recomendacion (EquipoFalso 18363 16 200)).Clave -eq '2021')
Comprobar 'Windows 10 1507   -> 2019' ((Get-Recomendacion (EquipoFalso 10240 16 200)).Clave -eq '2019')
Comprobar 'Windows 7         -> 2016' ((Get-Recomendacion (EquipoFalso  7601 16 200)).Clave -eq '2016')
Comprobar 'poca RAM manda sobre todo -> 2016' ((Get-Recomendacion (EquipoFalso 22631 3 200)).Clave -eq '2016')
Comprobar 'poco disco genera aviso' (
  (Get-Recomendacion (EquipoFalso 22631 16 2)).Avisos.Tipo -contains 'error')
Comprobar 'equipo holgado no genera avisos' (
  (Get-Recomendacion (EquipoFalso 22631 16 200)).Avisos.Count -eq 0)

Write-Host "`nTARJETA GRÁFICA" -ForegroundColor Cyan
Comprobar 'detecta NVIDIA' ((Get-MarcaGrafica 'NVIDIA GeForce RTX 4060').Marca -eq 'NVIDIA')
Comprobar 'detecta AMD'    ((Get-MarcaGrafica 'AMD Radeon RX 6600').Marca -eq 'AMD')
Comprobar 'detecta Intel'  ((Get-MarcaGrafica 'Intel UHD Graphics 630').Marca -eq 'Intel')
Comprobar 'detecta la falta de controlador' (
  (Get-MarcaGrafica 'Microsoft Basic Display Adapter').Marca -eq 'Sin controlador')
Comprobar 'HD 4400 se marca como antigua' (Test-GraficaAntigua (EquipoFalso 19045 8 100 'Intel HD Graphics 4400'))
Comprobar 'RTX 4060 no se marca como antigua' (-not (Test-GraficaAntigua (EquipoFalso 19045 8 100 'NVIDIA GeForce RTX 4060')))

Write-Host "`nDESINSTALAR" -ForegroundColor Cyan
$xml3 = [xml](Get-Content (New-XmlDesinstalar) -Raw)
Comprobar 'el XML quita todo' ($xml3.Configuration.Remove.All -eq 'TRUE')

Write-Host "`nMODO SILENCIOSO" -ForegroundColor Cyan
$conVentana = [xml](Get-Content (New-ConfiguracionXml $p2021 'ProPlus' 'es-es' '64' @('Word') @() $false) -Raw)
$sinVentana = [xml](Get-Content (New-ConfiguracionXml $p2021 'ProPlus' 'es-es' '64' @('Word') @() $true)  -Raw)
Comprobar 'normal enseña la ventana de Microsoft' ($conVentana.Configuration.Display.Level -eq 'Full')
Comprobar 'silencioso la esconde'                 ($sinVentana.Configuration.Display.Level -eq 'None')
Comprobar 'desinstalar silencioso también' (
  ([xml](Get-Content (New-XmlDesinstalar $true) -Raw)).Configuration.Display.Level -eq 'None')

Write-Host "`nLÍNEA DE ÓRDENES" -ForegroundColor Cyan
. "$PSScriptRoot/src/7-arranque.ps1"
# Lo que se le repite a la copia elevada tiene que ser lo que pidió el usuario
$script:INVOCADO = [ordered]@{ Instalar = '2021'; Apps = @('Word','Excel'); Silencioso = $true }
$linea = Get-LineaArgumentos
Comprobar 'repite el producto'         ($linea -match '-Instalar "2021"')
Comprobar 'la lista de apps va con comas' ($linea -match '-Apps Word,Excel')
Comprobar 'los interruptores van sueltos' ($linea -match '-Silencioso(\s|$)')
$script:INVOCADO = [ordered]@{ Activar = $false }
Comprobar 'un interruptor apagado no se repite' ((Get-LineaArgumentos) -eq '')

if (Test-Path "$PSScriptRoot/OfficeGo.ps1") {
  $ast = [System.Management.Automation.Language.Parser]::ParseFile(
    "$PSScriptRoot/OfficeGo.ps1", [ref]$null, [ref]$null)
  Comprobar 'el script montado admite parámetros' (
    $ast.ParamBlock -and $ast.ParamBlock.Parameters.Count -ge 8)
  Comprobar 'admite -Instalar' (
    $ast.ParamBlock.Parameters.Name.VariablePath.UserPath -contains 'Instalar')
}

Write-Host ""
if ($fallos) { Write-Host "$fallos prueba(s) fallando" -ForegroundColor Red; exit 1 }
Write-Host "Todas las pruebas pasan" -ForegroundColor Green
