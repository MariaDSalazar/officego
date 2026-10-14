# =====================================================================
#
#   ██████  ███████ ███████ ██  ██████ ███████  ██████   ██████
#  ██    ██ ██      ██      ██ ██      ██      ██       ██    ██
#  ██    ██ █████   █████   ██ ██      █████   ██   ███ ██    ██
#  ██    ██ ██      ██      ██ ██      ██      ██    ██ ██    ██
#   ██████  ██      ██      ██  ██████ ███████  ██████   ██████
#
#  Instalador y activador de Microsoft Office para Windows 10 y 11
#  https://github.com/MariaDSalazar/officego
#
#  Diego Fernando Loján Tenesaca  · desarrollo e interfaz
#  María del Carmen Salazar Torres · script base y documentación
#
#  Licencia MIT · sin telemetría · sin publicidad
#
#  USO
#    irm https://raw.githubusercontent.com/MariaDSalazar/officego/main/OfficeGo.ps1 | iex
#    & ([scriptblock]::Create((irm ...OfficeGo.ps1))) -Instalar 2021 -Apps Word,Excel
#    .\OfficeGo.ps1 -Ayuda
#
#  Descarga Office de los servidores oficiales de Microsoft:
#    officecdn.microsoft.com   ·  c2rsetup.officeapps.live.com
#
#  ESTE ARCHIVO SE GENERA: no lo edite a mano.
#  Toque src/*.ps1 y ejecute build.sh
# =====================================================================


# ─────────────────────────────────────────────── 0-parametros.ps1
# =====================================================================
#  OfficeGo · parámetros
#
#  Con `irm URL | iex` no se pueden pasar parámetros: iex recibe el
#  texto ya montado. Por eso el arranque recomendado es
#
#     & ([scriptblock]::Create((irm URL))) -Instalar 2021 -Silencioso
#
#  que crea un bloque de script de verdad y sí los acepta. Sin ningún
#  parámetro se abre la ventana, que es lo habitual.
#
#  ESTE ARCHIVO NO LLEVA BOM, y es a propósito. Con BOM, el carácter
#  invisible del principio se cuela en el texto que devuelve irm, param
#  deja de ser lo primero del bloque y PowerShell lo toma por una llamada
#  a un comando: "The assignment expression is not valid". Como sin BOM
#  PowerShell 5.1 lee el archivo en ANSI y parte los acentos, más abajo
#  hay una relectura que lo arregla.
# =====================================================================
param(
  # Qué instalar, sin tocar la ventana
  [ValidateSet('365','2024','2021','2019','2016','2013')]
  [string]$Instalar,

  [ValidateSet('ProPlus','Standard','Professional','HomeBusiness','HomeStudent','Personal','Business')]
  [string]$Edicion = 'ProPlus',

  # Word,Excel,PowerPoint · lo que no se nombre no se instala
  [string[]]$Apps = @('Word','Excel','PowerPoint'),

  [string]$Idioma = 'es-es',

  [ValidateSet('64','32')]
  [string]$Bits,

  # VisioPro, VisioStd, ProjectPro, ProjectStd
  [string[]]$Complementos = @(),

  # Activar al terminar (o por su cuenta, sin instalar nada)
  [switch]$Activar,

  # Sin ventana: para desplegar en varios equipos o desde un script
  [switch]$Silencioso,

  # Quitar Office del equipo
  [switch]$Desinstalar,

  [switch]$Ayuda
)

# ── acentos
#
# PowerShell 5.1 lee en ANSI todo archivo que no lleve BOM, y entonces
# cada acento llega partido en dos caracteres: 'á' mide 2 en vez de 1.
# Cuando pasa, el archivo se relee diciéndole que es UTF-8 y se ejecuta
# esa versión. No hay vuelta atrás posible: el texto releído ya trae los
# acentos enteros, así que la condición no se cumple una segunda vez.
if ($PSCommandPath -and 'á'.Length -ne 1 -and (Test-Path $PSCommandPath)) {
  $bien = [IO.File]::ReadAllText($PSCommandPath, [Text.UTF8Encoding]::new($false))
  & ([scriptblock]::Create($bien)) @PSBoundParameters
  return
}

$script:VERSION = '1.6'
$script:URL_SCRIPT = 'https://raw.githubusercontent.com/MariaDSalazar/officego/main/OfficeGo.ps1'

# Se guardan aquí porque hacen falta para volver a lanzarse como
# administrador, y dentro de una función ya no se ven:
#   INVOCADO · qué parámetros dio el usuario, para repetírselos
#   FUENTE   · la ruta del .ps1, o su texto entero si vino de internet
$script:INVOCADO = $PSBoundParameters
$script:FUENTE   = $MyInvocation.MyCommand.Definition

# Si viene con órdenes, no hay ventana que enseñar. Y entonces tampoco se
# monta: así el modo desatendido no depende de Windows Forms ni carga con
# el segundo largo que cuesta construirla.
$script:SIN_INTERFAZ = [bool]($Ayuda -or $Silencioso -or $Instalar -or $Desinstalar -or $Activar)

# ─────────────────────────────────────────────── 1-catalogo.ps1
# =====================================================================
#  OfficeGo · catálogo de productos
#
#  Dos vías, y no son intercambiables:
#    ODT  -> setup.exe /configure con un configuration.xml. Productos de
#            volumen y suscripción. Permite excluir aplicaciones.
#    C2R  -> c2rsetup.officeapps.live.com. Productos retail (2016 y 2013).
#            NO admite excluir aplicaciones: instala la suite entera.
# =====================================================================

# Aplicaciones que el ODT sabe excluir (ExcludeApp ID)
$script:APLICACIONES = [ordered]@{
  Word       = @{ Nombre='Word';       Color='#2B579A'; Sigla='W'  }
  Excel      = @{ Nombre='Excel';      Color='#217346'; Sigla='X'  }
  PowerPoint = @{ Nombre='PowerPoint'; Color='#D24726'; Sigla='P'  }
  Outlook    = @{ Nombre='Outlook';    Color='#0F6CBD'; Sigla='O'  }
  Access     = @{ Nombre='Access';     Color='#A4373A'; Sigla='A'  }
  Publisher  = @{ Nombre='Publisher';  Color='#077568'; Sigla='Pb' }
  OneNote    = @{ Nombre='OneNote';    Color='#7719AA'; Sigla='N'  }
}

# Qué trae realmente cada edición. De aquí sale que al elegir Standard
# se apague Access: esa edición no lo incluye.
$script:EDICIONES = @{
  ProPlus       = @{ Nombre='Professional Plus'; Apps=@('Word','Excel','PowerPoint','Outlook','Access','Publisher','OneNote') }
  Standard      = @{ Nombre='Standard';          Apps=@('Word','Excel','PowerPoint','Outlook','Publisher','OneNote') }
  Professional  = @{ Nombre='Professional';      Apps=@('Word','Excel','PowerPoint','Outlook','Access','Publisher','OneNote') }
  HomeBusiness  = @{ Nombre='Home & Business';   Apps=@('Word','Excel','PowerPoint','Outlook','OneNote') }
  HomeStudent   = @{ Nombre='Home & Student';    Apps=@('Word','Excel','PowerPoint','OneNote') }
  Personal      = @{ Nombre='Personal';          Apps=@('Word','Excel','PowerPoint','OneNote') }
  Business      = @{ Nombre='Business';          Apps=@('Word','Excel','PowerPoint','Outlook','OneNote') }
}

# Catálogo. Id = Product ID que entiende Microsoft.
$script:PRODUCTOS = @(
  @{ Clave='365';  Nombre='Microsoft 365';   Sub='siempre al día'; Sigla='365'; Color='#D83B01'
     Tipo='suscripción'; Via='ODT'; Canal='Current'; Peso=1.9
     Ediciones=[ordered]@{ ProPlus='O365ProPlusRetail'; Business='O365BusinessRetail' } }

  @{ Clave='2024'; Nombre='Office 2024';     Sub='LTSC';           Sigla='24';  Color='#B7472A'
     Tipo='volumen'; Via='ODT'; Canal='PerpetualVL2024'; Peso=2.1
     Ediciones=[ordered]@{ ProPlus='ProPlus2024Volume'; Standard='Standard2024Volume' } }

  @{ Clave='2021'; Nombre='Office 2021';     Sub='LTSC · recomendada'; Sigla='21'; Color='#C43E1C'
     Tipo='volumen'; Via='ODT'; Canal='PerpetualVL2021'; Peso=1.9; Recomendado=$true
     Ediciones=[ordered]@{ ProPlus='ProPlus2021Volume'; Standard='Standard2021Volume' } }

  @{ Clave='2019'; Nombre='Office 2019';     Sub='perpetua';       Sigla='19';  Color='#D24726'
     Tipo='volumen'; Via='ODT'; Canal='PerpetualVL2019'; Peso=1.8
     Ediciones=[ordered]@{ ProPlus='ProPlus2019Volume'; Standard='Standard2019Volume' } }

  # 2016 y 2013 van por c2rsetup: la suite entera, sin poder excluir nada.
  @{ Clave='2016'; Nombre='Office 2016';     Sub='clásica';        Sigla='16';  Color='#E8590C'
     Tipo='retail'; Via='C2R'; Version='O16GA'; Peso=2.5
     Ediciones=[ordered]@{ ProPlus='ProPlusRetail'; Standard='StandardRetail'
                           Professional='ProfessionalRetail'; HomeBusiness='HomeBusinessRetail'
                           HomeStudent='HomeStudentRetail' } }

  @{ Clave='2013'; Nombre='Office 2013';     Sub='antigua';        Sigla='13';  Color='#F08C00'
     Tipo='retail'; Via='C2R'; Version='O15GA'; Peso=1.5
     Ediciones=[ordered]@{ ProPlus='ProPlusRetail'; Standard='StandardRetail'
                           Professional='ProfessionalRetail'; HomeBusiness='HomeBusinessRetail' } }
)

# Complementos: productos aparte que se añaden al mismo configuration.xml.
# Cada uno suma más o menos esto a la descarga.
$script:PESO_COMPLEMENTO_GB = 0.6
$script:COMPLEMENTOS = @(
  @{ Clave='VisioPro';   Nombre='Visio Professional';   Sigla='V';  Color='#3955A3'
     Ids=@{ '2024'='VisioPro2024Volume'; '2021'='VisioPro2021Volume'; '2019'='VisioPro2019Volume'
            '365'='VisioProRetail' } }
  @{ Clave='VisioStd';   Nombre='Visio Standard';       Sigla='Vs'; Color='#5B76C4'
     Ids=@{ '2024'='VisioStd2024Volume'; '2021'='VisioStd2021Volume'; '2019'='VisioStd2019Volume' } }
  @{ Clave='ProjectPro'; Nombre='Project Professional'; Sigla='Pj'; Color='#31752F'
     Ids=@{ '2024'='ProjectPro2024Volume'; '2021'='ProjectPro2021Volume'; '2019'='ProjectPro2019Volume'
            '365'='ProjectProRetail' } }
  @{ Clave='ProjectStd'; Nombre='Project Standard';     Sigla='Ps'; Color='#5B9E59'
     Ids=@{ '2024'='ProjectStd2024Volume'; '2021'='ProjectStd2021Volume'; '2019'='ProjectStd2019Volume' } }
)

$script:IDIOMAS = [ordered]@{
  'es-es' = 'Español (España)';    'es-mx' = 'Español (México)'
  'en-us' = 'English (US)';        'pt-br' = 'Português (Brasil)'
  'fr-fr' = 'Français';            'de-de' = 'Deutsch';  'it-it' = 'Italiano'
}

function Get-Producto($clave) { $script:PRODUCTOS | Where-Object { $_.Clave -eq $clave } | Select-Object -First 1 }

function Get-AppsDeEdicion($producto, $edicion) {
  # Qué aplicaciones se pueden marcar. Por C2R no se puede elegir: van todas.
  if ($producto.Via -eq 'C2R') { return @() }
  $script:EDICIONES[$edicion].Apps
}

# ─────────────────────────────────────────────── 2-motor.ps1
# =====================================================================
#  OfficeGo · motor
#  Todo lo que hace trabajo de verdad. No sabe nada de la interfaz:
#  recibe datos, devuelve datos y avisa del progreso por un callback.
# =====================================================================

$script:ODT_URL  = 'https://officecdn.microsoft.com/pr/wsus/setup.exe'
$script:C2R_URL  = 'https://c2rsetup.officeapps.live.com/c2r/download.aspx'
$script:MAS_URL  = 'https://get.activated.win'
if (-not $env:TEMP) { $env:TEMP = [IO.Path]::GetTempPath() }   # falta al correr como SYSTEM
$script:TRABAJO  = Join-Path $env:TEMP 'OfficeGo'
$script:DISCO_MINIMO_GB = 5

# Windows 10 sin actualizar negocia TLS 1.0 y los CDN de Microsoft lo
# rechazan: sin esto la descarga muere con "conexión cerrada". Si .NET ya
# deja elegir al sistema (SystemDefault, 0) no se toca, para no perder TLS 1.3.
try {
  $tls = [Net.ServicePointManager]::SecurityProtocol
  if ([int]$tls -ne 0) {
    [Net.ServicePointManager]::SecurityProtocol = $tls -bor [Net.SecurityProtocolType]::Tls12
  }
} catch {}

function Test-Administrador {
  try {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal $id).IsInRole(
      [Security.Principal.WindowsBuiltInRole]::Administrator)
  } catch { $false }   # fuera de Windows esta API no existe
}

function Test-Internet {
  try {
    $r = [Net.HttpWebRequest]::Create($script:ODT_URL)
    $r.Method = 'HEAD'; $r.Timeout = 8000
    $r.GetResponse().Close(); $true
  } catch { $false }
}

# ─────────────────────────────────────────────── características del equipo
function Get-EquipoInfo {
  $so   = Get-CimInstance Win32_OperatingSystem
  $cpu  = Get-CimInstance Win32_Processor | Select-Object -First 1
  # Con dos gráficas, o en escritorio remoto, la primera puede ser el
  # adaptador genérico de Microsoft: se prefiere una con controlador propio
  # y, entre esas, la que mueve una pantalla (la otra no tiene resolución).
  $gpu  = Get-CimInstance Win32_VideoController |
            Sort-Object { $_.Name -match 'Microsoft Basic|Standard VGA|Remote Display' },
                        { -not $_.CurrentHorizontalResolution } |
            Select-Object -First 1
  $rams = @(Get-CimInstance Win32_PhysicalMemory)
  $build = [Environment]::OSVersion.Version.Build

  $discos = foreach ($d in Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3') {
    [pscustomobject]@{
      Letra   = $d.DeviceID
      TotalGB = [math]::Round($d.Size / 1GB, 1)
      LibreGB = [math]::Round($d.FreeSpace / 1GB, 1)
      UsadoPc = if ($d.Size) { [int](100 - 100 * $d.FreeSpace / $d.Size) } else { 0 }
      Sistema = ($d.DeviceID -eq $env:SystemDrive)
    }
  }

  [pscustomobject]@{
    SO           = ($so.Caption -replace '^Microsoft ', '')
    Build        = "$build.$((Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -EA SilentlyContinue).UBR)"
    EsWin11      = ($build -ge 22000)
    Compatible   = ($build -ge 10240)
    Arquitectura = $so.OSArchitecture
    Bits         = if ([Environment]::Is64BitOperatingSystem) { '64' } else { '32' }
    Instalado    = $so.InstallDate
    PowerShell   = $PSVersionTable.PSVersion.ToString()
    CPU          = $cpu.Name.Trim()
    CPUGhz       = [math]::Round($cpu.MaxClockSpeed / 1000, 2)
    Nucleos      = $cpu.NumberOfCores
    Hilos        = $cpu.NumberOfLogicalProcessors
    CPUUso       = [int]$cpu.LoadPercentage
    RamGB        = [math]::Round($so.TotalVisibleMemorySize / 1MB, 1)
    RamLibreGB   = [math]::Round($so.FreePhysicalMemory / 1MB, 1)
    RamUsoPc     = [int](100 - 100 * $so.FreePhysicalMemory / $so.TotalVisibleMemorySize)
    RamModulos   = $rams.Count
    RamTipo      = if ($rams -and $rams[0].Speed) { "$($rams[0].Speed) MHz" } else { '' }
    GPU          = $gpu.Name
    Resolucion   = "$($gpu.CurrentHorizontalResolution) × $($gpu.CurrentVerticalResolution)"
    Discos       = @($discos)
    Admin        = (Test-Administrador)
    Defender     = try { (Get-MpComputerStatus).RealTimeProtectionEnabled } catch { $null }
  }
}

# ───────────────────────────────────────────────────── Office ya instalado
function Get-OfficeInstalado {
  $k = 'HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration'
  if (-not (Test-Path $k)) { return $null }
  $c = Get-ItemProperty $k
  [pscustomobject]@{
    Productos    = $c.ProductReleaseIds
    Version      = $c.VersionToReport
    Idioma       = $c.ClientCulture
    Arquitectura = $c.Platform
    Canal        = $c.CDNBaseUrl
    Ruta         = $c.InstallationPath
  }
}

# Office 2016 en adelante instala en Office16 y 2013 en Office15. Buscando
# solo en Office16, con Office 2013 puesto se decia que no habia ninguno.
# Y lo instalado por Click-to-Run (2019, 2021, 2024, 365) lo deja dentro de
# root: sin mirar ahí, con Office puesto se decía que no había ninguno.
function Get-RutaOspp {
  $bases = @($env:ProgramFiles, ${env:ProgramFiles(x86)}) | Where-Object { $_ }
  foreach ($b in $bases) {
    foreach ($v in 'root\Office16', 'Office16', 'root\Office15', 'Office15') {
      $r = Join-Path $b "Microsoft Office\$v\ospp.vbs"
      if (Test-Path $r) { return $r }
    }
  }
  $null
}

function Get-EstadoLicencia {
  $ospp = Get-RutaOspp
  if (-not $ospp) { return $null }
  $salida = & cscript //nologo $ospp /dstatus 2>$null
  [pscustomobject]@{
    Activado = [bool]($salida -match '---LICENSED---')
    Nombre   = ($salida | Select-String 'LICENSE NAME' | Select-Object -First 1) -replace '.*:\s*', ''
    Dias     = ([regex]::Match(($salida -join "`n"), 'REMAINING GRACE:\s*(\d+)').Groups[1].Value)
    Cruda    = $salida
  }
}

# La clave se aplica con guiones (XXXXX-XXXXX-...), que es el único formato
# que el servicio de licencias acepta siempre. Motivo vale invalidKey,
# noOffice o keyRejected cuando no se aplica.
function Set-ClaveProducto {
  param([string]$Clave)
  $limpia = ($Clave -replace '[^A-Za-z0-9]', '').ToUpper()
  if ($limpia.Length -ne 25) { return [pscustomobject]@{ Ok = $false; Motivo = 'invalidKey'; Salida = '' } }
  $ospp = Get-RutaOspp
  if (-not $ospp) { return [pscustomobject]@{ Ok = $false; Motivo = 'noOffice'; Salida = '' } }

  $conGuiones = ($limpia -split '(.{5})' | Where-Object { $_ }) -join '-'
  $r = & cscript //nologo $ospp "/inpkey:$conGuiones" 2>&1
  if (-not ($r -match 'successful')) {
    return [pscustomobject]@{ Ok = $false; Motivo = 'keyRejected'; Salida = ($r -join "`n") }
  }
  & cscript //nologo $ospp /act | Out-Null
  [pscustomobject]@{ Ok = $true; Motivo = ''; Salida = '' }
}

# ─────────────────────────────────────────────── descarga con progreso real
function Invoke-Descarga {
  param([string]$Url, [string]$Destino, [scriptblock]$AlAvanzar)

  $req = [Net.HttpWebRequest]::Create($Url); $req.Timeout = 30000
  $res = $req.GetResponse()
  # Cuando Microsoft no tiene lo pedido redirige a una página de aviso: sin
  # esto se guardaba como OfficeSetup.exe y fallaba al ejecutarla.
  if ($res.ContentType -like 'text/html*') {
    $res.Close()
    throw "Microsoft no ofrece esa descarga ahora mismo ($($res.ResponseUri.Host))."
  }
  $total = $res.ContentLength
  $ent = $res.GetResponseStream(); $sal = [IO.File]::Create($Destino)
  $buf = New-Object byte[] 65536
  $hecho = 0; $ultimo = -1
  try {
    while (($n = $ent.Read($buf, 0, $buf.Length)) -gt 0) {
      $sal.Write($buf, 0, $n); $hecho += $n
      if ($total -gt 0) {
        $pc = [int](100 * $hecho / $total)
        if ($pc -ne $ultimo -and $AlAvanzar) {
          $ultimo = $pc
          & $AlAvanzar $pc ([math]::Round($hecho/1MB,1)) ([math]::Round($total/1MB,1))
        }
      }
    }
  } finally { $sal.Close(); $ent.Close(); $res.Close() }
  $Destino
}

# ────────────────────────────────────────────────────── configuration.xml
function New-ConfiguracionXml {
  param($Producto, [string]$Edicion, [string]$Idioma, [string]$Bits,
        [string[]]$AppsQueSi, [string[]]$Complementos, [bool]$SinVentanas = $false)

  $id = $Producto.Ediciones[$Edicion]
  # Se excluye lo que la edición trae pero el usuario no marcó
  $todas = $script:EDICIONES[$Edicion].Apps
  $fuera = @($todas | Where-Object { $_ -notin $AppsQueSi })
  # OneDrive y Skype no los quiere casi nadie y no están en la lista visible
  $fuera += 'Groove', 'Lync', 'OneDrive', 'OutlookForWindows', 'Teams'

  $sb = [Text.StringBuilder]::new()
  [void]$sb.AppendLine('<Configuration>')
  [void]$sb.AppendLine("  <Add OfficeClientEdition=`"$Bits`" Channel=`"$($Producto.Canal)`">")
  [void]$sb.AppendLine("    <Product ID=`"$id`">")
  [void]$sb.AppendLine("      <Language ID=`"$Idioma`" />")
  foreach ($a in ($fuera | Select-Object -Unique)) {
    [void]$sb.AppendLine("      <ExcludeApp ID=`"$a`" />")
  }
  [void]$sb.AppendLine('    </Product>')
  foreach ($c in $Complementos) {
    $comp = $script:COMPLEMENTOS | Where-Object { $_.Clave -eq $c }
    $cid = $comp.Ids[$Producto.Clave]
    if ($cid) {
      [void]$sb.AppendLine("    <Product ID=`"$cid`">")
      [void]$sb.AppendLine("      <Language ID=`"$Idioma`" />")
      [void]$sb.AppendLine('    </Product>')
    }
  }
  [void]$sb.AppendLine('  </Add>')
  [void]$sb.AppendLine('  <Property Name="AUTOACTIVATE" Value="0" />')
  [void]$sb.AppendLine('  <Property Name="FORCEAPPSHUTDOWN" Value="TRUE" />')
  # Level="None" esconde la ventana azul de Microsoft: para desatendido
  $nivel = if ($SinVentanas) { 'None' } else { 'Full' }
  [void]$sb.AppendLine("  <Display Level=`"$nivel`" AcceptEULA=`"TRUE`" />")
  [void]$sb.AppendLine('</Configuration>')

  New-Item -ItemType Directory -Force -Path $script:TRABAJO | Out-Null
  $ruta = Join-Path $script:TRABAJO 'configuration.xml'
  [IO.File]::WriteAllText($ruta, $sb.ToString(), [Text.UTF8Encoding]::new($false))
  $ruta
}

function New-XmlDesinstalar {
  param([bool]$SinVentanas = $false)
  $nivel = if ($SinVentanas) { 'None' } else { 'Full' }
  $xml = @"
<Configuration>
  <Remove All="TRUE" />
  <Property Name="FORCEAPPSHUTDOWN" Value="TRUE" />
  <Display Level="$nivel" AcceptEULA="TRUE" />
</Configuration>
"@
  New-Item -ItemType Directory -Force -Path $script:TRABAJO | Out-Null
  $ruta = Join-Path $script:TRABAJO 'quitar.xml'
  [IO.File]::WriteAllText($ruta, $xml, [Text.UTF8Encoding]::new($false))
  $ruta
}

# ─────────────────────────────────────────────────────────── instalación
function Get-SetupODT {
  param([scriptblock]$AlAvanzar)
  New-Item -ItemType Directory -Force -Path $script:TRABAJO | Out-Null
  $setup = Join-Path $script:TRABAJO 'setup.exe'
  Invoke-Descarga $script:ODT_URL $setup $AlAvanzar
}

function Start-InstalacionODT {
  param([string]$Setup, [string]$Xml)
  Start-Process $Setup -ArgumentList "/configure `"$Xml`"" -PassThru
}

function Start-InstalacionC2R {
  param($Producto, [string]$Edicion, [string]$Idioma, [string]$Bits, [scriptblock]$AlAvanzar)
  New-Item -ItemType Directory -Force -Path $script:TRABAJO | Out-Null
  $exe = Join-Path $script:TRABAJO 'OfficeSetup.exe'
  $id  = $Producto.Ediciones[$Edicion]
  # c2rsetup llama x86 a los 32 bits: con platform=x32 devuelve su página de error
  $plataforma = if ($Bits -eq '32') { 'x86' } else { 'x64' }
  $url = "$($script:C2R_URL)?ProductreleaseID=$id&platform=$plataforma&language=$Idioma&version=$($Producto.Version)"
  Invoke-Descarga $url $exe $AlAvanzar | Out-Null
  Start-Process $exe -PassThru
}

# ─────────────────────────────────────────── instalador sin conexión
#
# La carpeta queda lista para llevarla a otro equipo: setup.exe, un
# configuration.xml SIN SourcePath (así setup.exe busca Office a su lado)
# e instalar.cmd para no tener que escribir nada. El XML que se usa para
# descargar sí lleva SourcePath, escapado: una carpeta con & lo rompía.
function Start-DescargaSinConexion {
  param($Producto, [string]$Edicion, [string]$Idioma, [string]$Bits,
        [string[]]$AppsQueSi, [string[]]$Complementos, [string]$Destino, [scriptblock]$AlAvanzar)

  New-Item -ItemType Directory -Force -Path $Destino | Out-Null
  $setup = Get-SetupODT $AlAvanzar
  $xml = New-ConfiguracionXml $Producto $Edicion $Idioma $Bits $AppsQueSi $Complementos

  Copy-Item $setup (Join-Path $Destino 'setup.exe') -Force
  Copy-Item $xml (Join-Path $Destino 'configuration.xml') -Force
  [IO.File]::WriteAllText((Join-Path $Destino 'instalar.cmd'),
    "@echo off`r`ncd /d `"%~dp0`"`r`nsetup.exe /configure configuration.xml`r`n", [Text.Encoding]::ASCII)

  $ruta = [Security.SecurityElement]::Escape($Destino)
  $conRuta = (Get-Content $xml -Raw).Replace('<Add ', "<Add SourcePath=`"$ruta`" ")
  [IO.File]::WriteAllText($xml, $conRuta, [Text.UTF8Encoding]::new($false))
  Start-Process $setup -ArgumentList "/download `"$xml`"" -PassThru
}

# ────────────────────────────────────────────────────────────── reparación
#
# Office no se repara con el Office Deployment Tool: /configure no tiene
# modo reparar, y aquí se le pasaba un repair.xml que no existía, así que
# la reparación fallaba siempre. Lo hace su propio motor Click-to-Run, el
# mismo al que llama Windows desde Configuración > Aplicaciones > Modificar.
function Get-MotorClickToRun {
  @("$env:ProgramFiles\Common Files\Microsoft Shared\ClickToRun\OfficeClickToRun.exe",
    "${env:ProgramFiles(x86)}\Common Files\Microsoft Shared\ClickToRun\OfficeClickToRun.exe") |
    Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
}

function Start-Reparacion {
  param([ValidateSet('Rapida','Completa')][string]$Tipo = 'Rapida')
  $exe = Get-MotorClickToRun
  if (-not $exe) { throw 'No se encontro el motor de Office (OfficeClickToRun.exe).' }

  # La rápida no necesita internet y arregla casi todo; la completa
  # vuelve a descargar Office entero.
  $of = Get-OfficeInstalado
  $plataforma = if ($of -and $of.Arquitectura) { $of.Arquitectura } else { 'x64' }
  $cultura    = if ($of -and $of.Idioma)       { $of.Idioma }       else { 'es-es' }
  $modo       = if ($Tipo -eq 'Rapida') { 'QuickRepair' } else { 'FullRepair' }

  Start-Process $exe -PassThru -ArgumentList @(
    'scenario=Repair', "platform=$plataforma", "culture=$cultura",
    'forceappshutdown=True', "RepairType=$modo", 'DisplayLevel=True')
}

# ───────────────────────────────────────────────────────── activación (MAS)
# MAS entra en modo desatendido con cualquier argumento que lleve "/":
#   if defined _args echo "%_args%" | find /i "/" && set _unattended=1
# Así que /Ohook activa Office sin mostrar su menú.
function Invoke-MAS {
  param([ValidateSet('Ohook','HWID','Ohook-Uninstall')][string]$Modo = 'Ohook')
  New-Item -ItemType Directory -Force -Path $script:TRABAJO | Out-Null
  $cmd = Join-Path $script:TRABAJO 'MAS.cmd'
  (Invoke-RestMethod $script:MAS_URL) | Set-Content $cmd -Encoding Ascii
  Start-Process 'cmd.exe' -ArgumentList "/c `"$cmd`" /$Modo" -WindowStyle Hidden -PassThru
}

function Test-DefenderBloquea {
  # Defender marca toda herramienta de activación, por diseño. Si la
  # protección está encendida, MAS puede desaparecer a mitad de camino.
  try { (Get-MpComputerStatus).RealTimeProtectionEnabled } catch { $false }
}

# ─────────────────────────────────────────────── 2b-recomendacion.ps1
# =====================================================================
#  OfficeGo · qué versión le conviene a este equipo
#
#  Requisitos reales publicados por Microsoft:
#    Office LTSC 2024 -> Windows 11, o Windows 10 versión 22H2 (build 19045+)
#    Office LTSC 2021 -> Windows 10 versión 1809 (build 17763) o superior
#    Office 2019      -> Windows 10
#    Office 2016/2013 -> Windows 7 SP1 en adelante
#    RAM: 4 GB para 64 bits · 2 GB para 32 bits    Disco: 4 GB
# =====================================================================

function Get-MarcaGrafica($nombre) {
  if (-not $nombre) { return @{ Marca='Desconocida'; Color='#5F6368'; Sigla='?' } }
  switch -Regex ($nombre) {
    'NVIDIA|GeForce|Quadro|RTX|GTX' { return @{ Marca='NVIDIA'; Color='#76B900'; Sigla='NV' } }
    'AMD|Radeon|FirePro|Vega'       { return @{ Marca='AMD';    Color='#ED1C24'; Sigla='AMD' } }
    'Intel|UHD|Iris|HD Graphics'    { return @{ Marca='Intel';  Color='#0071C5'; Sigla='IN' } }
    'Microsoft Basic|Standard VGA'  { return @{ Marca='Sin controlador'; Color='#C5221F'; Sigla='!' } }
    default                          { return @{ Marca='Otra';   Color='#5F6368'; Sigla='G' } }
  }
}

function Test-GraficaAntigua($eq) {
  # Office acelera por hardware con DirectX. En tarjetas viejas o sin
  # controlador propio conviene apagar esa aceleración: si no, Word y
  # Excel parpadean al desplazarse.
  if (-not $eq.GPU) { return $true }
  if ($eq.GPU -match 'Microsoft Basic|Standard VGA') { return $true }
  # las UHD/HD anteriores a la serie 500 ya tienen sus años
  if ($eq.GPU -match 'HD Graphics [2-4]\d{2}') { return $true }
  $false
}

function Get-Recomendacion($eq) {
  $avisos = @()
  $b = [int]($eq.Build -split '\.')[0]

  # ── qué versión aguanta este Windows
  $clave = if     ($b -ge 22000) { '2024' }   # Windows 11
           elseif ($b -ge 19045) { '2024' }   # Windows 10 22H2
           elseif ($b -ge 17763) { '2021' }   # Windows 10 1809
           elseif ($b -ge 10240) { '2019' }   # Windows 10 primeras
           else                  { '2016' }   # anterior al 10

  $motivo = switch ($clave) {
    '2024' { 'El equipo cumple los requisitos de la versión más nueva.' }
    '2021' { 'Su Windows 10 no llega a la versión 22H2, que es lo que pide Office 2024.' }
    '2019' { 'Su Windows 10 es de las primeras versiones: 2021 y 2024 piden una más reciente.' }
    '2016' { 'Su Windows es anterior al 10, así que solo cabe una versión clásica.' }
  }
  # El código es lo que traduce la versión de escritorio; el texto, la 1.x
  $codigo = @{ '2024' = 'latest'; '2021' = 'win10Before22H2'; '2019' = 'win10Early'; '2016' = 'beforeWin10' }[$clave]

  # ── la memoria puede cambiar la respuesta
  if ($eq.RamGB -lt 4) {
    $clave = '2016'
    $motivo = "Con $($eq.RamGB) GB de RAM conviene la versión más ligera; las nuevas piden 4 GB."
    $codigo = 'lowMemory'
    $avisos += @{ Tipo='warn'; Codigo='lowMemory'; Datos=@{ ramGb = $eq.RamGB }
                  Texto="Solo hay $($eq.RamGB) GB de RAM. Office funcionará, pero irá justo con varios documentos abiertos." }
  }

  if ($eq.Bits -eq '32') {
    $avisos += @{ Tipo='warn'; Codigo='windows32'; Datos=@{}; Texto='Windows de 32 bits: se instalará Office de 32 bits, que no puede usar más de 2 GB por documento.' }
  }

  $sistema = $eq.Discos | Where-Object { $_.Sistema } | Select-Object -First 1
  if ($sistema -and $sistema.LibreGB -lt $script:DISCO_MINIMO_GB) {
    $avisos += @{ Tipo='error'; Codigo='lowDisk'
                  Datos=@{ freeGb = $sistema.LibreGB; drive = $sistema.Letra; minimumGb = $script:DISCO_MINIMO_GB }
                  Texto="Quedan $($sistema.LibreGB) GB libres en $($sistema.Letra) y hacen falta al menos $($script:DISCO_MINIMO_GB) GB." }
  }

  if (Test-GraficaAntigua $eq) {
    $avisos += @{ Tipo='warn'; Codigo='oldGraphics'; Datos=@{}; Texto='La tarjeta gráfica es antigua o no tiene controlador propio. Si Word o Excel parpadean, desactive la aceleración por hardware en Archivo > Opciones > Avanzadas.' }
  }

  if ($eq.Defender -eq $true) {
    $avisos += @{ Tipo='info'; Codigo='defenderOn'; Datos=@{}; Texto='Defender está encendido. No molesta al instalar, pero sí marcará las herramientas de activación.' }
  }

  [pscustomobject]@{
    Clave   = $clave
    Nombre  = (Get-Producto $clave).Nombre
    Motivo  = $motivo
    Codigo  = $codigo
    Avisos  = $avisos
    Apto    = ($b -ge 10240)
  }
}

# ─────────────────────────────────────────────── 3-interfaz.ps1
if (-not $script:SIN_INTERFAZ) {
# =====================================================================
#  OfficeGo · interfaz (Windows Forms)
#  Solo dibuja y recoge lo que se elige. El trabajo lo hace el motor.
# =====================================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
try { [Windows.Forms.Application]::EnableVisualStyles() } catch {}

# Aquí había un SetProcessDPIAware() y era justo lo que descolocaba la
# ventana. Al declararse DPI-aware, Windows deja de escalar y entonces
# las letras, que van en puntos, crecen con la pantalla mientras las
# coordenadas, que van en píxeles, se quedan igual: a 125 % se solapaban
# 21 controles y a 150 % ciento y pico. Sin esa llamada Windows estira
# la ventana entera: se ve un pelín menos nítida en pantallas densas,
# pero proporcionada y sin nada encima de nada.
#
# Lo comprueba prueba-interfaz.ps1 -Factor 1.5

$C = @{
  Fondo='#F6F7F9'; Panel='#FFFFFF'; Borde='#E0E3E7'; Azul='#0B57D0'; AzulSuave='#E8F0FE'
  AzulClaro='#F5F9FF'; Texto='#202124'; Gris='#5F6368'; GrisClaro='#80868B'
  Verde='#137333'; VerdeSuave='#E6F4EA'; Rojo='#C5221F'; RojoSuave='#FCE8E6'
  Ambar='#8A6116'; AmbarSuave='#FEF7E0'; Linea='#F1F3F4'; Estado='#EEF1F4'
}
function Hex($h) { [Drawing.ColorTranslator]::FromHtml($h) }
function Fuente($t = 9, $b = $false) {
  New-Object Drawing.Font('Segoe UI', $t, $(if ($b) { [Drawing.FontStyle]::Bold } else { [Drawing.FontStyle]::Regular }))
}

# Pone el mismo clic en un control y en todo lo que lleva dentro, con el
# mismo Tag. Hacen falta las dos cosas: si se pulsa justo encima del icono
# o del texto, el evento lo recibe ese hijo y no la tarjeta, y entonces
# $this.Tag tiene que valer lo mismo o el manejador no sabe qué se pulsó.
#
# Ojo con GetNewClosure() aquí: dentro de un closure $script: apunta a su
# propio módulo, así que $script:sel se pierde y el clic no hace nada. Por
# eso lo que necesita saber el manejador viaja en el Tag y no capturado.
function Set-ClicEnTodo($ctl, $accion) {
  $ctl.Add_Click($accion)
  foreach ($h in $ctl.Controls) {
    $h.Cursor = $ctl.Cursor
    $h.Tag    = $ctl.Tag
    Set-ClicEnTodo $h $accion
  }
}

function Set-Redondeado($ctl, $r = 8) {
  $gp = New-Object Drawing.Drawing2D.GraphicsPath
  $w = $ctl.Width; $h = $ctl.Height; $d = $r * 2
  if ($w -le $d -or $h -le $d) { return }
  $gp.AddArc(0, 0, $d, $d, 180, 90);        $gp.AddArc($w-$d, 0, $d, $d, 270, 90)
  $gp.AddArc($w-$d, $h-$d, $d, $d, 0, 90);  $gp.AddArc(0, $h-$d, $d, $d, 90, 90)
  $gp.CloseFigure()
  $ctl.Region = New-Object Drawing.Region $gp
}

function New-Lbl($txt, $x, $y, $tam = 9, $col = $C.Texto, $bold = $false, $ancho = 0) {
  $l = New-Object Windows.Forms.Label
  $l.Text = $txt; $l.Location = New-Object Drawing.Point($x, $y)
  $l.Font = Fuente $tam $bold; $l.ForeColor = Hex $col
  $l.BackColor = [Drawing.Color]::Transparent
  if ($ancho) { $l.Size = New-Object Drawing.Size($ancho, 0); $l.AutoSize = $false; $l.Height = 40 }
  else { $l.AutoSize = $true }
  $l
}

function New-Caja($x, $y, $w, $h, $fondo = $C.Panel, $borde = $C.Borde) {
  $p = New-Object Windows.Forms.Panel
  $p.Location = New-Object Drawing.Point($x, $y)
  $p.Size = New-Object Drawing.Size($w, $h)
  $p.BackColor = Hex $fondo
  $p.Add_Paint({
    param($s, $e)
    $col = if ($s.Tag -and $s.Tag.Borde) { Hex $s.Tag.Borde } else { Hex $C.Borde }
    $lap = New-Object Drawing.Pen($col, 1)
    $e.Graphics.DrawRectangle($lap, 0, 0, $s.Width - 1, $s.Height - 1)
  })
  $p.Tag = @{ Borde = $borde }
  $p
}

function New-Boton($txt, $x, $y, $w, $h, $primario = $true) {
  $b = New-Object Windows.Forms.Button
  $b.Text = $txt; $b.Location = New-Object Drawing.Point($x, $y)
  $b.Size = New-Object Drawing.Size($w, $h)
  $b.FlatStyle = 'Flat'; $b.Font = Fuente 9.5 $primario
  $b.Cursor = 'Hand'
  if ($primario) {
    $b.BackColor = Hex $C.Azul; $b.ForeColor = [Drawing.Color]::White
    $b.FlatAppearance.BorderSize = 0
  } else {
    $b.BackColor = Hex $C.Panel; $b.ForeColor = Hex $C.Azul
    $b.FlatAppearance.BorderColor = Hex '#D2E3FC'
  }
  Set-Redondeado $b 7
  $b
}

function New-Icono($sigla, $color, $x, $y, $lado = 34, $tam = 10) {
  $p = New-Object Windows.Forms.Panel
  $p.Location = New-Object Drawing.Point($x, $y)
  $p.Size = New-Object Drawing.Size($lado, $lado)
  $p.BackColor = Hex $color
  $l = New-Lbl $sigla 0 0 $tam '#FFFFFF' $true
  $l.AutoSize = $false; $l.Size = New-Object Drawing.Size($lado, $lado)
  $l.TextAlign = 'MiddleCenter'
  $p.Controls.Add($l)
  Set-Redondeado $p 7
  $p
}

function New-Aviso($txt, $x, $y, $w, $tipo = 'info') {
  $col = switch ($tipo) {
    'ok'     { @($C.VerdeSuave, $C.Verde) }
    'warn'   { @($C.AmbarSuave, $C.Ambar) }
    'error'  { @($C.RojoSuave,  $C.Rojo)  }
    default  { @($C.AzulSuave,  $C.Azul)  }
  }
  $p = New-Object Windows.Forms.Panel
  $p.Location = New-Object Drawing.Point($x, $y)
  $p.Size = New-Object Drawing.Size($w, 44)
  $p.BackColor = Hex $col[0]
  $l = New-Lbl $txt 11 8 8.5 $col[1]
  $l.AutoSize = $false; $l.Size = New-Object Drawing.Size(($w - 22), 30)
  $p.Controls.Add($l)
  Set-Redondeado $p 7
  $p
}

# ══════════════════════════════════════════════════════ ventana principal
$frm = New-Object Windows.Forms.Form
$frm.Text = 'OfficeGo · Instalador de Microsoft Office'
$frm.Size = New-Object Drawing.Size(1016, 700)
$frm.StartPosition = 'CenterScreen'
$frm.BackColor = Hex $C.Fondo
$frm.Font = Fuente 9
$frm.FormBorderStyle = 'FixedSingle'
$frm.MaximizeBox = $false

# ── barra lateral
$side = New-Object Windows.Forms.Panel
$side.Location = New-Object Drawing.Point(0, 0)
$side.Size = New-Object Drawing.Size(172, 610)
$side.BackColor = Hex $C.Panel
$frm.Controls.Add($side)

$logo = New-Icono 'O' $C.Azul 14 14 30 12
$side.Controls.Add($logo)
$side.Controls.Add((New-Lbl 'OfficeGo' 52 18 11.5 $C.Texto $true))

$script:PANTALLAS = @('Inicio', 'Instalar', 'Activar', 'Equipo', 'Herramientas', 'Ayuda')
$script:botonesNav = @{}
$y = 62
foreach ($p in $script:PANTALLAS) {
  $b = New-Object Windows.Forms.Button
  $b.Text = "   $p"; $b.Location = New-Object Drawing.Point(8, $y)
  $b.Size = New-Object Drawing.Size(156, 36)
  $b.FlatStyle = 'Flat'; $b.FlatAppearance.BorderSize = 0
  $b.TextAlign = 'MiddleLeft'; $b.Font = Fuente 9.5
  $b.BackColor = Hex $C.Panel; $b.ForeColor = Hex $C.Gris; $b.Cursor = 'Hand'
  $b.Tag = $p
  $b.Add_Click({ Mostrar-Pantalla $this.Tag })
  Set-Redondeado $b 7
  $side.Controls.Add($b)
  $script:botonesNav[$p] = $b
  $y += 40
}

# ── zona de contenido
$cont = New-Object Windows.Forms.Panel
$cont.Location = New-Object Drawing.Point(172, 0)
$cont.Size = New-Object Drawing.Size(844, 610)
$cont.BackColor = Hex $C.Fondo
$cont.AutoScroll = $true
$frm.Controls.Add($cont)

# ── barra de estado del equipo
$barra = New-Object Windows.Forms.Panel
$barra.Location = New-Object Drawing.Point(0, 632)
$barra.Size = New-Object Drawing.Size(1016, 30)
$barra.BackColor = Hex $C.Estado
$frm.Controls.Add($barra)

function Punto($x, $color) {
  $p = New-Object Windows.Forms.Panel
  $p.Location = New-Object Drawing.Point($x, 11)
  $p.Size = New-Object Drawing.Size(8, 8)
  $p.BackColor = Hex $color
  Set-Redondeado $p 4
  $p
}

# ── pie con botones y progreso
$pie = New-Object Windows.Forms.Panel
$pie.Location = New-Object Drawing.Point(0, 610)
$pie.Size = New-Object Drawing.Size(1016, 22)
$pie.BackColor = Hex $C.Panel
$frm.Controls.Add($pie)

$prog = New-Object Windows.Forms.ProgressBar
$prog.Location = New-Object Drawing.Point(430, 6)
$prog.Size = New-Object Drawing.Size(400, 10)
$prog.Style = 'Continuous'
$pie.Controls.Add($prog)

$lblProg = New-Lbl '' 430 -2 8 $C.Gris
$pie.Controls.Add($lblProg)

function Set-Progreso($pc, $texto) {
  if ($pc -ge 0) { $prog.Value = [Math]::Min(100, [Math]::Max(0, $pc)) }
  $lblProg.Text = $texto
  [Windows.Forms.Application]::DoEvents()   # ponytail: sin hilos; la UI respira aquí
}

# ══════════════════════════════════════════════════════════ estado global
$script:sel = @{
  Producto = '2021'; Edicion = 'ProPlus'; Idioma = 'es-es'
  Bits = if ([Environment]::Is64BitOperatingSystem) { '64' } else { '32' }
  Apps = @('Word', 'Excel', 'PowerPoint'); Complementos = @()
}
$script:equipo = $null

function Mostrar-Pantalla($nombre) {
  foreach ($k in $script:botonesNav.Keys) {
    $b = $script:botonesNav[$k]
    if ($k -eq $nombre) { $b.BackColor = Hex $C.AzulSuave; $b.ForeColor = Hex $C.Azul; $b.Font = Fuente 9.5 $true }
    else { $b.BackColor = Hex $C.Panel; $b.ForeColor = Hex $C.Gris; $b.Font = Fuente 9.5 }
  }
  $cont.Controls.Clear()
  switch ($nombre) {
    'Inicio'       { Pantalla-Inicio }
    'Instalar'     { Pantalla-Instalar }
    'Activar'      { Pantalla-Activar }
    'Equipo'       { Pantalla-Equipo }
    'Herramientas' { Pantalla-Herramientas }
    'Ayuda'        { Pantalla-Ayuda }
  }
}

# ─────────────────────────────────────────────── 4-pantallas.ps1
# =====================================================================
#  OfficeGo · las cinco pantallas
# =====================================================================

# Los títulos se escriben en minúsculas y se suben aquí. No es capricho:
# leídos en ANSI, Ó (C3 93) y Ñ (C3 91) se convierten en comillas
# tipográficas, que PowerShell acepta como delimitador de cadena y parten
# el archivo. En minúscula, ó (C3 B3) y ñ (C3 B1) no dan problema.
function Titulo($txt, $x, $y) { New-Lbl $txt.ToUpper() $x $y 8.5 $C.Gris $true }

# ─────────────────────────────────────────────────────────── 1 · INSTALAR
function Pantalla-Instalar {
  $cont.Controls.Add((Titulo 'Elige tu versión' 18 14))

  # tarjetas de producto, 3 por fila
  $i = 0
  foreach ($p in $script:PRODUCTOS) {
    # Floor, no [int]: en PowerShell [int] REDONDEA, así que [int](5/3)
    # da 2 y la sexta tarjeta se iba una fila de más, encima de los
    # desplegables de edición. Con Floor cada tres tarjetas bajan una fila.
    $col = $i % 3; $fila = [Math]::Floor($i / 3)
    $x = 18 + $col * 158; $y = 36 + $fila * 92
    $elegida = ($p.Clave -eq $script:sel.Producto)
    $t = New-Caja $x $y 148 84 $(if ($elegida) { $C.AzulClaro } else { $C.Panel }) `
                  $(if ($elegida) { $C.Azul } else { $C.Borde })
    $t.Cursor = 'Hand'; $t.Tag = @{ Borde = $(if ($elegida) { $C.Azul } else { $C.Borde }); Clave = $p.Clave }

    $ic = New-Icono $p.Sigla $p.Color 57 9 34 10
    $t.Controls.Add($ic)
    $ln = New-Lbl $p.Nombre 0 47 9 $C.Texto $true
    $ln.AutoSize = $false; $ln.Size = New-Object Drawing.Size(148, 16); $ln.TextAlign = 'MiddleCenter'
    $t.Controls.Add($ln)
    $ls = New-Lbl $p.Tipo 0 63 7.5 $(switch ($p.Tipo) { 'volumen' { $C.Verde } 'retail' { $C.Ambar } default { $C.Azul } })
    $ls.AutoSize = $false; $ls.Size = New-Object Drawing.Size(148, 14); $ls.TextAlign = 'MiddleCenter'
    $t.Controls.Add($ls)

    $clic = { $script:sel.Producto = $this.Tag.Clave
              $script:sel.Edicion = @((Get-Producto $this.Tag.Clave).Ediciones.Keys)[0]
              Ajustar-Seleccion; Mostrar-Pantalla 'Instalar' }
    Set-ClicEnTodo $t $clic
    Set-Redondeado $t 9
    $cont.Controls.Add($t)
    $i++
  }

  $prod = Get-Producto $script:sel.Producto
  $yb = 36 + 92 * [Math]::Ceiling($script:PRODUCTOS.Count / 3) + 6

  # edición · idioma · arquitectura
  $cont.Controls.Add((Titulo 'Edición, idioma y arquitectura' 18 $yb))
  $cbEd = New-Object Windows.Forms.ComboBox
  $cbEd.Location = New-Object Drawing.Point(18, ($yb + 22))
  $cbEd.Size = New-Object Drawing.Size(180, 24); $cbEd.DropDownStyle = 'DropDownList'
  foreach ($e in $prod.Ediciones.Keys) { [void]$cbEd.Items.Add($script:EDICIONES[$e].Nombre) }
  $cbEd.SelectedIndex = [Math]::Max(0, @($prod.Ediciones.Keys).IndexOf($script:sel.Edicion))
  $cbEd.Add_SelectedIndexChanged({
    $script:sel.Edicion = @((Get-Producto $script:sel.Producto).Ediciones.Keys)[$this.SelectedIndex]
    Ajustar-Seleccion; Mostrar-Pantalla 'Instalar' })
  $cont.Controls.Add($cbEd)

  $cbId = New-Object Windows.Forms.ComboBox
  $cbId.Location = New-Object Drawing.Point(206, ($yb + 22))
  $cbId.Size = New-Object Drawing.Size(170, 24); $cbId.DropDownStyle = 'DropDownList'
  foreach ($v in $script:IDIOMAS.Values) { [void]$cbId.Items.Add($v) }
  $cbId.SelectedIndex = @($script:IDIOMAS.Keys).IndexOf($script:sel.Idioma)
  $cbId.Add_SelectedIndexChanged({ $script:sel.Idioma = @($script:IDIOMAS.Keys)[$this.SelectedIndex] })
  $cont.Controls.Add($cbId)

  $cbAr = New-Object Windows.Forms.ComboBox
  $cbAr.Location = New-Object Drawing.Point(384, ($yb + 22))
  $cbAr.Size = New-Object Drawing.Size(100, 24); $cbAr.DropDownStyle = 'DropDownList'
  [void]$cbAr.Items.AddRange(@('64 bits', '32 bits'))
  $cbAr.SelectedIndex = $(if ($script:sel.Bits -eq '64') { 0 } else { 1 })
  $cbAr.Add_SelectedIndexChanged({ $script:sel.Bits = $(if ($this.SelectedIndex -eq 0) { '64' } else { '32' }) })
  $cont.Controls.Add($cbAr)

  # aplicaciones
  $ya = $yb + 56
  $cont.Controls.Add((Titulo 'Aplicaciones' 18 $ya))
  $permitidas = Get-AppsDeEdicion $prod $script:sel.Edicion
  if ($prod.Via -eq 'C2R') {
    $cont.Controls.Add((New-Aviso "Office $($prod.Clave) se descarga entero: Microsoft no permite elegir aplicaciones por esta vía." 18 ($ya + 20) 480 'warn'))
    $yf = $ya + 72
  } else {
    $x = 18; $yc = $ya + 20
    foreach ($k in $script:APLICACIONES.Keys) {
      $app = $script:APLICACIONES[$k]
      $hay = ($k -in $permitidas)
      $on  = ($k -in $script:sel.Apps) -and $hay
      $ch = New-Caja $x $yc 118 32 $(if ($on) { $C.AzulClaro } else { $C.Panel }) `
                     $(if ($on) { $C.Azul } else { $C.Borde })
      $ch.Tag = @{ Borde = $(if ($on) { $C.Azul } else { $C.Borde }); App = $k }
      $ic = New-Icono $app.Sigla $(if ($hay) { $app.Color } else { '#C7CCD1' }) 5 5 22 8
      $ch.Controls.Add($ic)
      $ch.Controls.Add((New-Lbl $app.Nombre 33 8 8.5 $(if ($hay) { $C.Texto } else { $C.GrisClaro }) $on))
      if ($hay) {
        $ch.Cursor = 'Hand'
        $clic = { $a = $this.Tag.App
                  if ($a -in $script:sel.Apps) { $script:sel.Apps = @($script:sel.Apps | Where-Object { $_ -ne $a }) }
                  else { $script:sel.Apps += $a }
                  Mostrar-Pantalla 'Instalar' }
        Set-ClicEnTodo $ch $clic
      }
      Set-Redondeado $ch 16
      $cont.Controls.Add($ch)
      $x += 126; if ($x -gt 440) { $x = 18; $yc += 38 }
    }
    $yf = $yc + 46
  }

  # complementos
  $cont.Controls.Add((Titulo 'Complementos' 18 $yf))
  $x = 18
  foreach ($c in $script:COMPLEMENTOS) {
    $disponible = [bool]$c.Ids[$prod.Clave]
    $on = ($c.Clave -in $script:sel.Complementos) -and $disponible
    # 168 y no 152: «Project Professional» es el nombre más largo y con
    # una letra un poco más ancha se salía de la caja por la derecha
    $ch = New-Caja $x ($yf + 20) 168 32 $(if ($on) { $C.AzulClaro } else { $C.Panel }) `
                   $(if ($on) { $C.Azul } else { $C.Borde })
    $ch.Tag = @{ Borde = $(if ($on) { $C.Azul } else { $C.Borde }); Comp = $c.Clave }
    $ch.Controls.Add((New-Icono $c.Sigla $(if ($disponible) { $c.Color } else { '#C7CCD1' }) 5 5 22 8))
    $ch.Controls.Add((New-Lbl $c.Nombre 33 8 8.5 $(if ($disponible) { $C.Texto } else { $C.GrisClaro }) $on))
    if ($disponible) {
      $ch.Cursor = 'Hand'
      $clic = { $a = $this.Tag.Comp
                if ($a -in $script:sel.Complementos) { $script:sel.Complementos = @($script:sel.Complementos | Where-Object { $_ -ne $a }) }
                else { $script:sel.Complementos += $a }
                Mostrar-Pantalla 'Instalar' }
      Set-ClicEnTodo $ch $clic
    }
    Set-Redondeado $ch 16
    $cont.Controls.Add($ch)
    $x += 176
  }

  # resumen a la derecha
  $r = New-Caja 520 36 300 250
  $peso = $prod.Peso
  foreach ($c in $script:sel.Complementos) { $peso += $script:PESO_COMPLEMENTO_GB }
  $lp = New-Lbl ("{0:N1} GB" -f $peso) 0 14 20 $C.Azul $true
  $lp.AutoSize = $false; $lp.Size = New-Object Drawing.Size(300, 32); $lp.TextAlign = 'MiddleCenter'
  $r.Controls.Add($lp)
  $ls = New-Lbl 'tamaño de la descarga' 0 46 8 $C.GrisClaro
  $ls.AutoSize = $false; $ls.Size = New-Object Drawing.Size(300, 14); $ls.TextAlign = 'MiddleCenter'
  $r.Controls.Add($ls)

  $filas = @(
    @('Producto', $prod.Nombre),
    @('Edición', $script:EDICIONES[$script:sel.Edicion].Nombre),
    @('Aplicaciones', $(if ($prod.Via -eq 'C2R') { 'todas' } else { "$($script:sel.Apps.Count) de $($permitidas.Count)" })),
    @('Canal', $(if ($prod.Canal) { $prod.Canal } else { "c2rsetup · $($prod.Version)" })),
    @('Origen', 'Microsoft CDN')
  )
  $yr = 72
  foreach ($f in $filas) {
    $r.Controls.Add((New-Lbl $f[0] 14 $yr 8.5 $C.Gris))
    $lv = New-Lbl $f[1] 0 $yr 8.5 $C.Texto $true
    $lv.AutoSize = $false; $lv.Size = New-Object Drawing.Size(180, 16); $lv.TextAlign = 'MiddleRight'
    $lv.Location = New-Object Drawing.Point(104, $yr)
    $r.Controls.Add($lv)
    $yr += 24
  }
  Set-Redondeado $r 9
  $cont.Controls.Add($r)

  $r2 = New-Aviso 'Al cambiar de edición se ajustan solas las aplicaciones que esa edición incluye.' 520 296 300 'info'
  $r2.Height = 52
  $cont.Controls.Add($r2)

  # botones del pie
  Set-PieBotones @(
    @{ Texto = 'Instalar Office'; Primario = $true;  Accion = { Accion-Instalar } },
    @{ Texto = 'Solo descargar';  Primario = $false; Accion = { Accion-Descargar } }
  )
}

function Ajustar-Seleccion {
  # deja marcadas solo las apps que la edición elegida trae de verdad
  $prod = Get-Producto $script:sel.Producto
  $ok = Get-AppsDeEdicion $prod $script:sel.Edicion
  $script:sel.Apps = @($script:sel.Apps | Where-Object { $_ -in $ok })
  if (-not $script:sel.Apps) { $script:sel.Apps = @($ok | Select-Object -First 3) }
  # complementos que no existan para esa versión. El nombre propio no es
  # adorno: con $_ dentro de otro Where-Object se comparaba el complemento
  # consigo mismo y se borraban todos al cambiar de versión o de edición.
  $script:sel.Complementos = @($script:sel.Complementos | Where-Object {
    $elegido = $_
    ($script:COMPLEMENTOS | Where-Object { $_.Clave -eq $elegido } | Select-Object -First 1).Ids[$prod.Clave] })
}

# ──────────────────────────────────────────────────────────── 2 · ACTIVAR
function Pantalla-Activar {
  $cont.Controls.Add((Titulo 'Estado de la licencia' 18 14))
  $lic = Get-EstadoLicencia
  $activado = $lic -and $lic.Activado

  $t = New-Caja 18 36 802 74
  # La marca de verificación se compone con su número en vez de escribirla:
  # el carácter ✓ ocupa los bytes E2 9C 93, y leído en ANSI ese 93 final es
  # una comilla tipográfica que parte el archivo en PowerShell 5.1.
  $marca = if ($activado) { [string][char]0x2713 } else { '!' }
  $t.Controls.Add((New-Icono $marca `
                   $(if ($activado) { $C.Verde } else { $C.Rojo }) 16 15 44 14))
  $t.Controls.Add((New-Lbl $(if ($activado) { 'Office está activado' } elseif ($lic) { 'Office no está activado' } else { 'No hay Office instalado' }) 74 18 12 $C.Texto $true))
  $t.Controls.Add((New-Lbl $(if ($lic) { $lic.Nombre } else { 'Instale Office desde la pantalla Instalar' }) 74 42 8.5 $C.Gris))
  Set-Redondeado $t 9
  $cont.Controls.Add($t)

  $cont.Controls.Add((Titulo 'Cómo activar' 18 126))
  $opciones = @(
    @('K', $C.Azul,  'Clave de producto', 'Si tiene una clave de 25 caracteres, introdúzcala aquí', { Accion-Clave }),
    @('M', '#7719AA', 'MAS · massgrave.dev', 'Herramienta externa. OfficeGo la ejecuta sin abrir su menú', { Accion-MAS })
  )
  $y = 148
  foreach ($o in $opciones) {
    $p = New-Caja 18 $y 802 70
    $p.Controls.Add((New-Icono $o[0] $o[1] 16 13 44 14))
    $p.Controls.Add((New-Lbl $o[2] 74 16 10.5 $C.Texto $true))
    $p.Controls.Add((New-Lbl $o[3] 74 38 8.5 $C.Gris))
    $b = New-Boton 'Usar' 690 18 96 34 $false
    $b.Add_Click($o[4])
    $p.Controls.Add($b)
    Set-Redondeado $p 9
    $cont.Controls.Add($p)
    $y += 78
  }

  if (Test-DefenderBloquea) {
    $cont.Controls.Add((New-Aviso 'Defender está encendido y marca toda herramienta de activación, por diseño. Puede que interrumpa a MAS a mitad de camino.' 18 $y 802 'warn'))
    $y += 52
  }
  $cont.Controls.Add((New-Aviso 'Activar productos sin licencia va contra los términos de Microsoft. Esta opción se ofrece a título informativo.' 18 $y 802 'info'))

  Set-PieBotones @(
    @{ Texto = 'Comprobar estado'; Primario = $false; Accion = { Mostrar-Pantalla 'Activar' } }
  )
}

# ───────────────────────────────────────────────────────────── 3 · EQUIPO
function Pantalla-Equipo {
  if (-not $script:equipo) { $script:equipo = Get-EquipoInfo }
  $eq = $script:equipo
  $cont.Controls.Add((Titulo 'Características del equipo' 18 14))

  function Tarjeta-HW($titulo, $sub, $sigla, $color, $x, $y, $datos, $barra = $null) {
    $p = New-Caja $x $y 392 132
    $p.Controls.Add((New-Icono $sigla $color 14 13 32 9))
    $p.Controls.Add((New-Lbl $titulo 56 14 10 $C.Texto $true))
    $p.Controls.Add((New-Lbl $sub 56 33 8 $C.GrisClaro))
    $yy = 58
    foreach ($d in $datos) {
      $p.Controls.Add((New-Lbl $d[0] 16 $yy 8.5 $C.Gris))
      $lv = New-Lbl $d[1] 0 $yy 8.5 $C.Texto $true
      $lv.AutoSize = $false; $lv.Size = New-Object Drawing.Size(220, 15)
      $lv.TextAlign = 'MiddleRight'; $lv.Location = New-Object Drawing.Point(156, $yy)
      $p.Controls.Add($lv); $yy += 20
    }
    if ($barra) {
      $f = New-Object Windows.Forms.Panel
      $f.Location = New-Object Drawing.Point(16, ($yy + 4)); $f.Size = New-Object Drawing.Size(360, 6)
      $f.BackColor = Hex '#E8EAED'
      $r = New-Object Windows.Forms.Panel
      $r.Location = New-Object Drawing.Point(0, 0)
      $r.Size = New-Object Drawing.Size([int](360 * $barra[0] / 100), 6)
      $r.BackColor = Hex $barra[1]
      $f.Controls.Add($r); $p.Controls.Add($f)
      $p.Controls.Add((New-Lbl $barra[2] 16 ($yy + 14) 7.5 $C.GrisClaro))
    }
    Set-Redondeado $p 9
    $p
  }

  $cont.Controls.Add((Tarjeta-HW 'Sistema operativo' $eq.SO '⊞' $C.Azul 18 36 @(
    @('Compilación', $eq.Build), @('Arquitectura', $eq.Arquitectura), @('PowerShell', $eq.PowerShell))))
  $cont.Controls.Add((Tarjeta-HW 'Procesador' $eq.CPU 'C' $C.Rojo 428 36 @(
    @('Frecuencia', "$($eq.CPUGhz) GHz"), @('Núcleos / hilos', "$($eq.Nucleos) / $($eq.Hilos)")) `
    @($eq.CPUUso, $C.Rojo, "Uso actual $($eq.CPUUso) %")))
  $cont.Controls.Add((Tarjeta-HW 'Memoria RAM' "$($eq.RamGB) GB $($eq.RamTipo)" 'R' $C.Verde 18 178 @(
    @('Módulos', "$($eq.RamModulos)"), @('Disponible', "$($eq.RamLibreGB) GB")) `
    @($eq.RamUsoPc, $C.Verde, "$([math]::Round($eq.RamGB - $eq.RamLibreGB,1)) GB en uso")))
  $cont.Controls.Add((Tarjeta-HW 'Gráficos' $eq.GPU 'G' '#7719AA' 428 178 @(
    @('Resolución', $eq.Resolucion))))

  $y = 320
  $x = 18
  foreach ($d in $eq.Discos) {
    $cont.Controls.Add((Tarjeta-HW "Disco $($d.Letra)" $(if ($d.Sistema) { 'unidad del sistema' } else { 'datos' }) `
      'D' $C.Gris $x $y @(@('Capacidad', "$($d.TotalGB) GB")) `
      @($d.UsadoPc, $(if ($d.LibreGB -lt 5) { $C.Rojo } else { $C.Azul }), "$($d.LibreGB) GB libres")))
    if ($x -eq 18) { $x = 428 } else { $x = 18; $y += 142 }
  }

  Set-PieBotones @(
    @{ Texto = 'Copiar informe'; Primario = $false; Accion = { Accion-CopiarInforme } },
    @{ Texto = 'Actualizar';     Primario = $false; Accion = { $script:equipo = $null; Mostrar-Pantalla 'Equipo' } }
  )
}

# ─────────────────────────────────────────────────────── 4 · HERRAMIENTAS
function Pantalla-Herramientas {
  $cont.Controls.Add((Titulo 'Mantenimiento' 18 14))
  $items = @(
    @('R', $C.Azul,  'Reparar instalación', 'Repara Office sin perder documentos ni licencia', { Accion-Reparar }),
    @('D', $C.Verde, 'Crear instalador sin conexión', 'Descarga los archivos a una carpeta para otros equipos', { Accion-Descargar }),
    @('L', $C.Gris,  'Abrir carpeta de trabajo', 'Donde OfficeGo deja el setup y los registros', { Start-Process $script:TRABAJO })
  )
  $y = 36
  foreach ($it in $items) {
    $p = New-Caja 18 $y 802 70
    $p.Controls.Add((New-Icono $it[0] $it[1] 16 13 44 14))
    $p.Controls.Add((New-Lbl $it[2] 74 16 10.5 $C.Texto $true))
    $p.Controls.Add((New-Lbl $it[3] 74 38 8.5 $C.Gris))
    $b = New-Boton 'Ejecutar' 676 18 110 34 $false
    $b.Add_Click($it[4]); $p.Controls.Add($b)
    Set-Redondeado $p 9
    $cont.Controls.Add($p); $y += 78
  }

  $cont.Controls.Add((Titulo 'Desinstalar' 18 ($y + 6)))
  $p = New-Caja 18 ($y + 28) 802 70 $C.Panel '#F5C9C6'
  $p.Controls.Add((New-Icono '✕' $C.Rojo 16 13 44 14))
  $p.Controls.Add((New-Lbl 'Quitar Office del equipo' 74 16 10.5 $C.Texto $true))
  $p.Controls.Add((New-Lbl 'Se eliminan los programas. Los documentos NO se borran.' 74 38 8.5 $C.Gris))
  $b = New-Boton 'Desinstalar' 676 18 110 34 $false
  $b.ForeColor = Hex $C.Rojo
  $b.Add_Click({ Accion-Desinstalar })
  $p.Controls.Add($b)
  Set-Redondeado $p 9
  $cont.Controls.Add($p)

  $cont.Controls.Add((New-Aviso 'Desinstalar pide escribir la palabra BORRAR: un clic accidental no basta.' 18 ($y + 106) 802 'error'))
  Set-PieBotones @()
}

# ────────────────────────────────────────────────────────────── 5 · AYUDA
function Pantalla-Ayuda {
  $cont.Controls.Add((Titulo 'OfficeGo' 18 14))
  $h = New-Caja 18 36 802 76 $C.Azul $C.Azul
  $h.Controls.Add((New-Icono 'O' '#3B7DD8' 18 16 44 15))
  $l1 = New-Lbl "OfficeGo $script:VERSION" 78 18 14 '#FFFFFF' $true
  $h.Controls.Add($l1)
  # a 44 rozaba el título de 14 pt en cuanto la letra era un poco mayor
  $h.Controls.Add((New-Lbl 'Instalador y activador de Microsoft Office para Windows 10 y 11' 78 48 8.5 '#D6E4F7'))
  Set-Redondeado $h 9
  $cont.Controls.Add($h)

  $cont.Controls.Add((Titulo 'Quién lo hace' 18 126))
  $autores = @(
    @('Diego Fernando Loján Tenesaca', 'Desarrollo e interfaz', 'https://github.com/DiegoFernandoLojanTenesaca'),
    @('María del Carmen Salazar Torres', 'Script base y documentación', 'https://github.com/MariaDSalazar')
  )
  $x = 18
  foreach ($a in $autores) {
    $p = New-Caja $x 148 392 92
    $p.Controls.Add((New-Lbl $a[0] 16 16 10 $C.Texto $true))
    $p.Controls.Add((New-Lbl $a[1] 16 38 8.5 $C.Azul $true))
    $lk = New-Object Windows.Forms.LinkLabel
    $lk.Text = ($a[2] -replace 'https://', ''); $lk.Location = New-Object Drawing.Point(16, 60)
    $lk.AutoSize = $true; $lk.Font = Fuente 8.5
    $lk.LinkColor = Hex $C.Gris
    $lk.Tag = $a[2]
    $lk.Add_LinkClicked({ Start-Process $this.Tag })
    $p.Controls.Add($lk)
    Set-Redondeado $p 9
    $cont.Controls.Add($p)
    $x = 428
  }

  $cont.Controls.Add((Titulo 'Problemas frecuentes' 18 256))
  $faq = @(
    @('La ejecución de scripts está deshabilitada', 'Set-ExecutionPolicy Bypass -Scope Process -Force'),
    @('«irm» no se reconoce', 'Se pegó en CMD. Hay que usar PowerShell.'),
    @('No se puede establecer conexión SSL/TLS', 'OfficeGo ya fuerza TLS 1.2 al arrancar.'),
    @('El antivirus bloquea la activación', 'Defender marca toda herramienta de activación, por diseño.')
  )
  $y = 278
  foreach ($f in $faq) {
    $p = New-Caja 18 $y 802 52
    $p.Controls.Add((New-Lbl $f[0] 16 10 9.5 $C.Texto $true))
    $p.Controls.Add((New-Lbl $f[1] 16 29 8.5 $C.Gris))
    Set-Redondeado $p 9
    $cont.Controls.Add($p); $y += 58
  }

  Set-PieBotones @(
    @{ Texto = 'Ver el código en GitHub'; Primario = $false
       Accion = { Start-Process 'https://github.com/MariaDSalazar/officego' } }
  )
}

# ─────────────────────────────────────────────────── botones del pie común
function Set-PieBotones($lista) {
  @($pie.Controls) | Where-Object { $_ -is [Windows.Forms.Button] } | ForEach-Object { $pie.Controls.Remove($_) }
  $x = 18
  foreach ($b in $lista) {
    $btn = New-Boton $b.Texto $x -14 150 34 $b.Primario
    $btn.Add_Click($b.Accion)
    $pie.Controls.Add($btn)
    $btn.BringToFront()
    $x += 158
  }
}

# ─────────────────────────────────────────────── 5-inicio.ps1
# =====================================================================
#  OfficeGo · pantalla de bienvenida
#  Lo primero que se ve no es una lista de opciones, sino qué le
#  conviene a este equipo concreto.
# =====================================================================

function Pantalla-Inicio {
  if (-not $script:equipo) { $script:equipo = Get-EquipoInfo }
  $eq  = $script:equipo
  $rec = Get-Recomendacion $eq

  # ── cabecera
  $hero = New-Caja 18 14 802 92 $C.Azul $C.Azul
  $hero.Controls.Add((New-Icono 'O' '#3B7DD8' 22 22 48 17))
  $hero.Controls.Add((New-Lbl 'Instale Office en tres pasos' 86 24 15 '#FFFFFF' $true))
  $hero.Controls.Add((New-Lbl 'Descarga directa de los servidores de Microsoft · sin páginas de terceros' 86 54 9 '#D6E4F7'))
  Set-Redondeado $hero 11
  $cont.Controls.Add($hero)

  # ── la recomendación
  $cont.Controls.Add((Titulo 'Lo que le conviene a este equipo' 18 122))
  $prod = Get-Producto $rec.Clave
  $borde = if ($rec.Clave -in @('2016','2013')) { '#E8A33D' } else { $C.Azul }

  $r = New-Caja 18 144 802 88 $C.Panel $borde
  $r.Controls.Add((New-Icono $prod.Sigla $prod.Color 18 20 48 15))
  # la primera edición del producto, que es justo la que deja marcada el
  # botón de abajo. Estaba fija a ProPlus y podía no ser la misma.
  $edRec = @($prod.Ediciones.Keys)[0]
  $r.Controls.Add((New-Lbl "$($prod.Nombre) · $($script:EDICIONES[$edRec].Nombre)" 82 20 12.5 $C.Texto $true))
  $lm = New-Lbl $rec.Motivo 82 46 8.5 $C.Gris
  $lm.AutoSize = $false; $lm.Size = New-Object Drawing.Size(540, 32)
  $r.Controls.Add($lm)

  $b = New-Boton 'Instalar esto' 640 26 140 38 $true
  # la versión recomendada viaja en el Tag y no capturada en un closure:
  # dentro de GetNewClosure() $script:sel apunta a otro sitio y el botón
  # se quedaba sin hacer nada
  $b.Tag = $rec.Clave
  $b.Add_Click({
    $script:sel.Producto = $this.Tag
    $script:sel.Edicion  = @((Get-Producto $this.Tag).Ediciones.Keys)[0]
    Ajustar-Seleccion
    Mostrar-Pantalla 'Instalar'
  })
  $r.Controls.Add($b)
  Set-Redondeado $r 11
  $cont.Controls.Add($r)

  # ── los tres pasos
  $cont.Controls.Add((Titulo 'Cómo funciona' 18 246))
  $pasos = @(
    @('1', 'Elija su versión',      'Seis versiones desde 2013 hasta Microsoft 365, con sus ediciones'),
    @('2', 'Marque lo que quiere',  'Solo Word y Excel, o la suite entera. Se descarga únicamente eso'),
    @('3', 'Active al terminar',    'Con su clave de producto, o con MAS si no la tiene')
  )
  $x = 18
  foreach ($p in $pasos) {
    $c = New-Caja $x 268 260 104
    $n = New-Icono $p[0] $C.AzulSuave 114 14 32 12
    $n.Controls[0].ForeColor = Hex $C.Azul
    $c.Controls.Add($n)
    $lt = New-Lbl $p[1] 0 52 10 $C.Texto $true
    $lt.AutoSize = $false; $lt.Size = New-Object Drawing.Size(260, 18); $lt.TextAlign = 'MiddleCenter'
    $c.Controls.Add($lt)
    $ld = New-Lbl $p[2] 14 72 8 $C.GrisClaro
    $ld.AutoSize = $false; $ld.Size = New-Object Drawing.Size(232, 28); $ld.TextAlign = 'TopCenter'
    $c.Controls.Add($ld)
    Set-Redondeado $c 10
    $cont.Controls.Add($c)
    $x += 271
  }

  # ── avisos que salgan de la revisión
  $y = 386
  if (-not $rec.Apto) {
    $cont.Controls.Add((New-Aviso 'Este equipo tiene un Windows anterior al 10. Office 2019, 2021 y 2024 no se pueden instalar aquí.' 18 $y 802 'error'))
    $y += 52
  }
  foreach ($a in $rec.Avisos) {
    $av = New-Aviso $a.Texto 18 $y 802 $a.Tipo
    $av.Height = 52
    $cont.Controls.Add($av)
    $y += 58
  }
  # Sin permisos no se puede instalar, así que eso va antes que nada. El
  # resumen verde daba los permisos por hechos y decía «listo» a alguien
  # que no iba a poder instalar nada.
  if (-not $eq.Admin) {
    $cont.Controls.Add((New-Aviso 'Faltan permisos de administrador: se pueden mirar las pantallas, pero no instalar ni activar. Cierre y vuelva a abrir con clic derecho > Ejecutar como administrador.' 18 $y 802 'error'))
    $y += 58
  }
  elseif (-not $rec.Avisos -and $rec.Apto) {
    $sis = $eq.Discos | Where-Object { $_.Sistema } | Select-Object -First 1
    $cont.Controls.Add((New-Aviso "Equipo listo. $($eq.SO) · $($eq.RamGB) GB de RAM · $($sis.LibreGB) GB libres · permisos de administrador." 18 $y 802 'ok'))
  }

  Set-PieBotones @(
    @{ Texto = 'Empezar';  Primario = $true;  Accion = { Mostrar-Pantalla 'Instalar' } },
    @{ Texto = 'Ver el equipo'; Primario = $false; Accion = { Mostrar-Pantalla 'Equipo' } }
  )
}

# ─────────────────────────────────────────────── 6-acciones.ps1
# =====================================================================
#  OfficeGo · acciones
#  Lo que pasa al pulsar cada botón. Aquí se unen interfaz y motor.
# =====================================================================

function Confirmar($titulo, $texto, $icono = 'Question') {
  [Windows.Forms.MessageBox]::Show($texto, $titulo, 'YesNo', $icono) -eq 'Yes'
}
function Avisar($titulo, $texto, $icono = 'Information') {
  [void][Windows.Forms.MessageBox]::Show($texto, $titulo, 'OK', $icono)
}

function Test-ListoParaInstalar {
  if (-not (Test-Administrador)) {
    Avisar 'Faltan permisos' "OfficeGo necesita permisos de administrador.`n`nCierre y vuelva a abrirlo con clic derecho > Ejecutar como administrador." 'Warning'
    return $false
  }
  $sis = $script:equipo.Discos | Where-Object { $_.Sistema } | Select-Object -First 1
  if ($sis -and $sis.LibreGB -lt $script:DISCO_MINIMO_GB) {
    Avisar 'Espacio insuficiente' "Quedan $($sis.LibreGB) GB libres en $($sis.Letra) y hacen falta al menos $($script:DISCO_MINIMO_GB) GB." 'Warning'
    return $false
  }
  if (-not (Test-Internet)) {
    Avisar 'Sin conexión' "No se llega a los servidores de Microsoft.`n`nRevise el cable o el WiFi." 'Warning'
    return $false
  }
  $true
}

function Seguir-Proceso($proc, $mensaje) {
  # El proceso de Office tarda entre 10 y 30 minutos. Se vigila con un
  # temporizador para que la ventana siga respondiendo mientras tanto.
  $t0 = Get-Date
  $prog.Style = 'Marquee'
  while (-not $proc.HasExited) {
    $tr = (Get-Date) - $t0
    Set-Progreso -1 ("$mensaje · transcurrido {0:mm\:ss}" -f $tr)
    Start-Sleep -Milliseconds 400
  }
  $prog.Style = 'Continuous'
  $proc.ExitCode
}

# ───────────────────────────────────────────────────────────── instalar
function Accion-Instalar {
  if (-not (Test-ListoParaInstalar)) { return }
  $prod = Get-Producto $script:sel.Producto
  $ed   = $script:EDICIONES[$script:sel.Edicion].Nombre

  $apps = if ($prod.Via -eq 'C2R') { 'la suite completa' } else { $script:sel.Apps -join ', ' }
  if (-not (Confirmar 'Confirmar instalación' @"
Se va a instalar:

  $($prod.Nombre) · $ed
  Aplicaciones: $apps
  Idioma: $($script:IDIOMAS[$script:sel.Idioma])
  Arquitectura: $($script:sel.Bits) bits

Tarda entre 10 y 30 minutos. Cierre Word, Excel y PowerPoint antes de seguir.

¿Continuar?
"@)) { return }

  try {
    if ($prod.Via -eq 'ODT') {
      Set-Progreso 0 'Descargando el instalador de Microsoft…'
      $setup = Get-SetupODT { param($pc, $hecho, $total)
        Set-Progreso $pc "Descargando el instalador: $pc % · $hecho / $total MB" }

      Set-Progreso 100 'Preparando la configuración…'
      $xml = New-ConfiguracionXml $prod $script:sel.Edicion $script:sel.Idioma `
                                  $script:sel.Bits $script:sel.Apps $script:sel.Complementos

      $p = Start-InstalacionODT $setup $xml
      $rc = Seguir-Proceso $p 'Instalando Office'
    } else {
      Set-Progreso 0 'Descargando el instalador de Microsoft…'
      $p = Start-InstalacionC2R $prod $script:sel.Edicion $script:sel.Idioma $script:sel.Bits `
             { param($pc, $hecho, $total)
               Set-Progreso $pc "Descargando: $pc % · $hecho / $total MB" }
      $rc = Seguir-Proceso $p 'Instalando Office'
    }
  } catch {
    Set-Progreso 0 ''
    Avisar 'Falló la instalación' $_.Exception.Message 'Error'
    return
  }

  Set-Progreso 100 'Comprobando…'
  if (Get-OfficeInstalado) {
    Set-Progreso 100 'Office instalado correctamente'
    if (Confirmar 'Listo' "Office quedó instalado.`n`n¿Quiere activarlo ahora?") {
      Mostrar-Pantalla 'Activar'
    }
  } else {
    Set-Progreso 0 ''
    Avisar 'No se encontró Office' "El instalador terminó con el código $rc.`n`nRevise los registros en $($script:TRABAJO)." 'Warning'
  }
}

function Accion-Descargar {
  # antes de pedir la carpeta: elegirla para luego oír que no se puede es trabajar para nada
  $prod = Get-Producto $script:sel.Producto
  if ($prod.Via -eq 'C2R') {
    Avisar 'No disponible' "Office $($prod.Clave) solo se puede instalar en línea: esa vía de Microsoft no permite descargar los archivos aparte." 'Information'
    return
  }
  if (-not (Test-Internet)) { Avisar 'Sin conexión' 'No se llega a los servidores de Microsoft.' 'Warning'; return }
  $dlg = New-Object Windows.Forms.FolderBrowserDialog
  $dlg.Description = 'Elija dónde guardar los archivos de instalación'
  if ($dlg.ShowDialog() -ne 'OK') { return }

  try {
    Set-Progreso 0 'Descargando el instalador…'
    $p = Start-DescargaSinConexion $prod $script:sel.Edicion $script:sel.Idioma $script:sel.Bits `
           $script:sel.Apps $script:sel.Complementos $dlg.SelectedPath `
           { param($pc, $h, $t) Set-Progreso $pc "Instalador: $pc %" }
    $rc = Seguir-Proceso $p 'Descargando Office'
    if ($rc -ne 0) {
      Set-Progreso 0 ''
      Avisar 'Falló la descarga' "El descargador de Microsoft terminó con el código $rc." 'Warning'
      return
    }
    Set-Progreso 100 'Descarga terminada'
    Avisar 'Listo' "Los archivos quedaron en:`n$($dlg.SelectedPath)`n`nPara instalar en otro equipo, copie esa carpeta entera y abra instalar.cmd."
  } catch {
    Set-Progreso 0 ''
    Avisar 'Falló la descarga' $_.Exception.Message 'Error'
  }
}

# ───────────────────────────────────────────────────────────── activar
function Accion-Clave {
  $clave = [Microsoft.VisualBasic.Interaction]::InputBox(
    "Escriba la clave de producto de 25 caracteres:", 'Clave de producto', '')
  if (-not $clave) { return }
  Set-Progreso -1 'Aplicando la clave…'
  $r = Set-ClaveProducto $clave
  Set-Progreso 0 ''
  switch ($r.Motivo) {
    ''            { Avisar 'Listo' 'La clave se aplicó correctamente.' }
    'invalidKey'  { Avisar 'Clave no válida' 'La clave debe tener 25 caracteres.' 'Warning' }
    'noOffice'    { Avisar 'No hay Office' 'No se encontró una instalación de Office.' 'Warning' }
    default       { Avisar 'No se pudo aplicar' $r.Salida 'Warning' }
  }
  Mostrar-Pantalla 'Activar'
}

function Accion-MAS {
  if (-not (Test-Administrador)) {
    Avisar 'Faltan permisos' 'Hacen falta permisos de administrador para activar.' 'Warning'; return }

  $texto = @"
MAS es una herramienta externa (massgrave.dev) que OfficeGo ejecutará en segundo plano,
sin abrir su menú.

Windows Defender la detecta SIEMPRE, por diseño, aunque no sea dañina. Si la protección
en tiempo real está encendida puede interrumpirla a mitad de camino.

Activar productos sin licencia va contra los términos de Microsoft.

¿Continuar?
"@
  if (-not (Confirmar 'Antes de activar' $texto 'Warning')) { return }

  try {
    Set-Progreso -1 'Descargando MAS…'
    $p = Invoke-MAS 'Ohook'
    Seguir-Proceso $p 'Activando Office' | Out-Null
    Set-Progreso 100 'Comprobando el resultado…'
    Start-Sleep -Seconds 2
    $lic = Get-EstadoLicencia
    if ($lic -and $lic.Activado) {
      Set-Progreso 100 'Office activado'
      Avisar 'Listo' 'Office quedó activado.'
    } else {
      Set-Progreso 0 ''
      Avisar 'No se pudo confirmar' "MAS terminó, pero Office sigue sin aparecer como activado.`n`nLo más probable es que Defender lo interrumpiera. Pruebe a pausar la protección en tiempo real un momento." 'Warning'
    }
  } catch {
    Set-Progreso 0 ''
    Avisar 'Falló la activación' $_.Exception.Message 'Error'
  }
  Mostrar-Pantalla 'Activar'
}

# ─────────────────────────────────────────────────────── herramientas
function Accion-Reparar {
  if (-not (Get-OfficeInstalado)) { Avisar 'No hay Office' 'No se encontró Office en este equipo.' 'Warning'; return }
  if (-not (Test-Administrador)) {
    Avisar 'Faltan permisos' 'Reparar Office necesita permisos de administrador.' 'Warning'; return }
  if (-not (Confirmar 'Reparar Office' @"
Se va a reparar la instalación de Office.

Es la reparación rápida: no descarga nada y suele bastar. Los documentos
y la licencia no se tocan, pero se cerrarán Word, Excel y PowerPoint.

¿Continuar?
"@)) { return }
  try {
    Set-Progreso -1 'Iniciando la reparación…'
    $p = Start-Reparacion 'Rapida'
    Seguir-Proceso $p 'Reparando Office' | Out-Null
    Set-Progreso 100 'Reparación terminada'
    Avisar 'Listo' "La reparación terminó.`n`nSi el problema sigue, pruebe la reparación en línea desde Configuración > Aplicaciones > Microsoft Office > Modificar."
  } catch {
    Set-Progreso 0 ''
    Avisar 'No se pudo reparar' "$($_.Exception.Message)`n`nPuede repararlo a mano desde Configuración > Aplicaciones > Microsoft Office > Modificar > Reparación en línea." 'Information'
  }
}

function Accion-Desinstalar {
  if (-not (Get-OfficeInstalado)) { Avisar 'No hay Office' 'No se encontró Office en este equipo.' 'Warning'; return }
  $r = [Microsoft.VisualBasic.Interaction]::InputBox(
    "Esto quitará Office del equipo. Los documentos NO se borran.`n`nEscriba BORRAR para confirmar:",
    'Desinstalar Office', '')
  if ($r -cne 'BORRAR') { return }
  try {
    Set-Progreso -1 'Descargando la herramienta…'
    $setup = Get-SetupODT { param($pc, $h, $t) Set-Progreso $pc "Descargando: $pc %" }
    $xml = New-XmlDesinstalar
    $p = Start-InstalacionODT $setup $xml
    Seguir-Proceso $p 'Desinstalando Office' | Out-Null
    Set-Progreso 0 ''
    if (Get-OfficeInstalado) { Avisar 'Sigue instalado' 'La desinstalación no terminó bien.' 'Warning' }
    else { Avisar 'Listo' 'Office se quitó del equipo.' }
  } catch {
    Set-Progreso 0 ''
    Avisar 'Falló la desinstalación' $_.Exception.Message 'Error'
  }
}

function Accion-CopiarInforme {
  $eq = $script:equipo
  $of = Get-OfficeInstalado
  $rec = Get-Recomendacion $eq
  $txt = @"
== OfficeGo · informe del equipo =============================
Sistema        $($eq.SO) (build $($eq.Build)) · $($eq.Arquitectura)
PowerShell     $($eq.PowerShell)
Procesador     $($eq.CPU) · $($eq.Nucleos) núcleos / $($eq.Hilos) hilos · $($eq.CPUGhz) GHz
Memoria        $($eq.RamGB) GB ($($eq.RamModulos) módulos) · $($eq.RamLibreGB) GB libres
Gráficos       $($eq.GPU) · $($eq.Resolucion)
$(($eq.Discos | ForEach-Object { "Disco $($_.Letra)        $($_.TotalGB) GB · $($_.LibreGB) GB libres" }) -join "`n")
Administrador  $($eq.Admin)
Defender       $($eq.Defender)

Office         $(if ($of) { "$($of.Productos) $($of.Version) $($of.Idioma) $($of.Arquitectura)" } else { 'no instalado' })
Recomendado    $($rec.Nombre): $($rec.Motivo)
==============================================================
"@
  Set-Clipboard -Value $txt
  Avisar 'Copiado' 'El informe está en el portapapeles. Puede pegarlo donde lo necesite.'
}
}   # fin de la interfaz

# ─────────────────────────────────────────────── 7-arranque.ps1
# =====================================================================
#  OfficeGo · arranque
#
#  Tres formas de entrar, según con qué se le llame:
#    sin nada         → la ventana de siempre
#    -Instalar 2021   → por consola, sin ventana
#    -Ayuda           → cómo se usa
# =====================================================================

# InputBox sale de aquí; es lo único que se toma de VisualBasic
try { Add-Type -AssemblyName Microsoft.VisualBasic } catch {}

# ───────────────────────────────────────────── volver a lanzarse elevado
#
# El caso difícil es cuando el script llegó por internet: entonces no hay
# ningún archivo en disco al que apuntar con -File. Se resuelve guardando
# el propio texto del script, que PowerShell deja en $MyInvocation.
#
function Get-RutaRelanzable {
  if ($PSCommandPath -and (Test-Path $PSCommandPath)) { return $PSCommandPath }

  $tmp = Join-Path $env:TEMP 'OfficeGo.ps1'
  # Esta copia solo se ejecuta con -File, nunca como texto, así que aquí
  # el BOM sí conviene: ahorra la relectura por los acentos y no puede
  # romper el param(), que es lo que pasa por la otra vía.
  $utf8 = [Text.UTF8Encoding]::new($true)

  if ($script:FUENTE -and $script:FUENTE.Length -gt 2000) {
    try { [IO.File]::WriteAllText($tmp, $script:FUENTE, $utf8); return $tmp } catch {}
  }
  try {
    $txt = Invoke-RestMethod $script:URL_SCRIPT
    [IO.File]::WriteAllText($tmp, $txt, $utf8)
    return $tmp
  } catch { return $null }
}

function Get-LineaArgumentos {
  $partes = @()
  foreach ($k in $script:INVOCADO.Keys) {
    $v = $script:INVOCADO[$k]
    if     ($v -is [switch] -or $v -is [bool]) { if ($v) { $partes += "-$k" } }
    elseif ($v -is [array])                    { $partes += "-$k $($v -join ',')" }
    else                                       { $partes += "-$k `"$v`"" }
  }
  $partes -join ' '
}

function Invoke-Elevar {
  $ruta = Get-RutaRelanzable
  if (-not $ruta) { return $false }
  try {
    Start-Process 'powershell.exe' -Verb RunAs -ArgumentList (
      "-NoProfile -ExecutionPolicy Bypass -File `"$ruta`" $(Get-LineaArgumentos)")
    $true
  } catch { $false }   # el usuario dijo que no en el aviso de Windows
}

# ─────────────────────────────────────────────────────────────── ayuda
function Show-Ayuda {
  $u = $script:URL_SCRIPT
  Write-Host ""
  Write-Host "  OfficeGo $script:VERSION" -ForegroundColor Cyan
  Write-Host "  Instalador y activador de Microsoft Office"
  Write-Host ""
  Write-Host "  CON VENTANA" -ForegroundColor Yellow
  Write-Host "    irm $u | iex"
  Write-Host ""
  Write-Host "  CON OPCIONES" -ForegroundColor Yellow
  Write-Host "    Hace falta [scriptblock]::Create: con  irm | iex  no se"
  Write-Host "    pueden pasar parámetros."
  Write-Host ""
  Write-Host "    & ([scriptblock]::Create((irm $u))) -Instalar 2021"
  Write-Host ""
  Write-Host "  OPCIONES" -ForegroundColor Yellow
  Write-Host "    -Instalar     365 2024 2021 2019 2016 2013"
  Write-Host "    -Edicion      ProPlus (por defecto), Standard, Professional…"
  Write-Host "    -Apps         Word,Excel,PowerPoint  · lo que no se nombre, no se instala"
  Write-Host "    -Complementos VisioPro, VisioStd, ProjectPro, ProjectStd"
  Write-Host "    -Idioma       es-es (por defecto), es-mx, en-us…"
  Write-Host "    -Bits         64 o 32  · por defecto, lo que sea el Windows"
  Write-Host "    -Activar      activar al terminar, o suelto para activar sin instalar"
  Write-Host "    -Desinstalar  quitar Office del equipo"
  Write-Host "    -Silencioso   sin ventanas de Microsoft ni preguntas"
  Write-Host "    -Ayuda        esto"
  Write-Host ""
  Write-Host "  EJEMPLOS" -ForegroundColor Yellow
  Write-Host "    -Instalar 2021 -Apps Word,Excel"
  Write-Host "    -Instalar 2024 -Edicion Standard -Complementos VisioPro -Activar"
  Write-Host "    -Instalar 365 -Silencioso -Activar     # despliegue desatendido"
  Write-Host "    -Activar                               # solo activar"
  Write-Host ""
}

# ────────────────────────────────────────────────────── modo sin ventana
function Write-Paso($texto) { Write-Host "  $texto" -ForegroundColor Gray }
function Write-Bien($texto) { Write-Host "  $texto" -ForegroundColor Green }
function Write-Mal($texto)  { Write-Host "  $texto" -ForegroundColor Red }

# Todo lo que se puede decir que está mal sin tocar el equipo. Se mira
# ANTES de pedir permisos: sacar el aviso de Windows para luego decir que
# la edición no existe es hacer trabajar al usuario para nada.
function Test-Peticion {
  if (-not ($Instalar -or $Activar -or $Desinstalar)) {
    return @('-Silencioso necesita saber qué hacer.',
             'Añada -Instalar, -Activar o -Desinstalar. Con -Ayuda se ven los ejemplos.')
  }
  if ($Instalar) {
    $prod = Get-Producto $Instalar
    if (-not $prod.Ediciones.Contains($Edicion)) {
      return @("$($prod.Nombre) no tiene la edición $Edicion.",
               "Tiene: $($prod.Ediciones.Keys -join ', ')")
    }
    if ($prod.Via -eq 'ODT') {
      $malas = @($Apps | Where-Object { -not $script:APLICACIONES[$_] })
      if ($malas) {
        return @("No existe$(if ($malas.Count -gt 1) { 'n' }) $($malas -join ', ').",
                 "Hay: $($script:APLICACIONES.Keys -join ', ')")
      }
    }
    foreach ($c in $Complementos) {
      $comp = $script:COMPLEMENTOS | Where-Object { $_.Clave -eq $c } | Select-Object -First 1
      if (-not $comp) {
        return @("No existe el complemento $c.",
                 "Hay: $(($script:COMPLEMENTOS.Clave) -join ', ')")
      }
      # existe, pero puede que no para esta versión de Office
      if (-not $comp.Ids[$prod.Clave]) {
        return @("$($comp.Nombre) no sale para $($prod.Nombre).",
                 "Sale para: $(($comp.Ids.Keys | Sort-Object) -join ', ')")
      }
    }
    if (-not $script:IDIOMAS[$Idioma]) {
      return @("El idioma $Idioma no está en la lista.",
               "Hay: $($script:IDIOMAS.Keys -join ', ')")
    }
  }
  $null
}

function Invoke-Consola {
  Write-Host ""
  Write-Host "  OfficeGo $script:VERSION" -ForegroundColor Cyan
  Write-Host ""

  # ── quitar
  if ($Desinstalar) {
    Write-Paso 'Quitando Office…'
    $setup = Get-SetupODT $null
    $p = Start-InstalacionODT $setup (New-XmlDesinstalar $Silencioso)
    $p.WaitForExit()
    if ($p.ExitCode -eq 0) { Write-Bien 'Office desinstalado.' }
    else { Write-Mal "El desinstalador terminó con el código $($p.ExitCode)." }
    Write-Host ""
    return $p.ExitCode
  }

  # ── instalar
  if ($Instalar) {
    $prod = Get-Producto $Instalar
    $bits = if ($Bits) { $Bits } elseif ([Environment]::Is64BitOperatingSystem) { '64' } else { '32' }

    Write-Paso "$($prod.Nombre) · $Edicion · $Idioma · $bits bits"
    if ($prod.Via -eq 'ODT') { Write-Paso "Aplicaciones: $($Apps -join ', ')" }
    else { Write-Paso 'Esta versión se instala entera: no admite elegir aplicaciones.' }
    Write-Host ""

    $avance = {
      param($pc, $hecho, $total)
      Write-Progress -Activity 'Descargando' -Status "$hecho de $total MB" -PercentComplete $pc
    }

    try {
      if ($prod.Via -eq 'ODT') {
        $xml   = New-ConfiguracionXml $prod $Edicion $Idioma $bits $Apps $Complementos $Silencioso
        $setup = Get-SetupODT $avance
        Write-Progress -Activity 'Descargando' -Completed
        Write-Paso 'Instalando… Office se descarga ahora, puede tardar un rato.'
        $p = Start-InstalacionODT $setup $xml
      } else {
        $p = Start-InstalacionC2R $prod $Edicion $Idioma $bits $avance
        Write-Progress -Activity 'Descargando' -Completed
        Write-Paso 'Instalando…'
      }
      $p.WaitForExit()
    } catch {
      Write-Progress -Activity 'Descargando' -Completed
      Write-Mal "Falló la descarga: $($_.Exception.Message)"
      return 1
    }

    if ($p.ExitCode -ne 0) {
      Write-Mal "El instalador terminó con el código $($p.ExitCode)."
      Write-Paso "Los registros de Microsoft quedan en $env:TEMP"
      return $p.ExitCode
    }
    Write-Bien 'Office instalado.'
  }

  # ── activar
  if ($Activar) {
    Write-Host ""
    if (Test-DefenderBloquea) {
      Write-Host '  Defender está encendido y marca los activadores por diseño.' -ForegroundColor Yellow
      Write-Host '  Si la activación no cuaja, pause la protección y repita.' -ForegroundColor Yellow
    }
    Write-Paso 'Activando…'
    $p = Invoke-MAS 'Ohook'
    $p.WaitForExit()
    $lic = Get-EstadoLicencia
    if ($lic -and $lic.Activado) { Write-Bien 'Office activado.' }
    elseif ($lic) { Write-Mal "No se pudo confirmar la activación: $($lic.Nombre)" }
    else { Write-Mal 'No se encontró Office para activar.' }
  }

  Write-Host ""
  return 0
}

# ──────────────────────────────────────────────────────── barra de estado
function Actualizar-BarraEstado {
  $barra.Controls.Clear()
  if (-not $script:equipo) { $script:equipo = Get-EquipoInfo }
  $eq = $script:equipo
  $sis = $eq.Discos | Where-Object { $_.Sistema } | Select-Object -First 1
  # una sola vez: sin conexión, cada intento espera 8 s a que caduque
  $red = Test-Internet

  $items = @(
    @("$($eq.SO) · $(($eq.Build -split '\.')[0])", $(if ($eq.Compatible) { $C.Verde } else { $C.Rojo })),
    @($(if ($eq.Admin) { 'Administrador' } else { 'Sin permisos' }), $(if ($eq.Admin) { $C.Verde } else { $C.Rojo })),
    @("$($sis.LibreGB) GB libres", $(if ($sis.LibreGB -ge $script:DISCO_MINIMO_GB) { $C.Verde } else { $C.Rojo })),
    @($(if ($red) { 'Conectado' } else { 'Sin internet' }), $(if ($red) { $C.Verde } else { $C.Rojo })),
    @($(if ($eq.Defender) { 'Defender activo' } else { 'Defender apagado' }), '#E8A33D')
  )
  # El ancho lo dice el propio control: al ser AutoSize, en cuanto está
  # creado su Width es lo que de verdad mide el texto. Antes se calculaba
  # a ojo con 6,1 px por letra, y en cuanto el nombre del Windows era
  # largo los estados se montaban unos encima de otros.
  $x = 18
  foreach ($it in $items) {
    $barra.Controls.Add((Punto $x $it[1]))
    $l = New-Lbl $it[0] ($x + 14) 7 8 $C.Gris
    $barra.Controls.Add($l)
    $x += 14 + $l.Width + 20
  }
  # la versión, pegada a la derecha y nunca encima de lo anterior
  $v = New-Lbl "OfficeGo $script:VERSION" 0 7 8 $C.GrisClaro
  $v.Left = [Math]::Max($x, $barra.Width - $v.Width - 18)
  $barra.Controls.Add($v)
}

# ──────────────────────────────────────────────────────────── con ventana
function Start-Ventana {
  # Sin permisos no se puede instalar nada: se avisa pero se deja mirar.
  if (-not (Test-Administrador)) {
    $r = [Windows.Forms.MessageBox]::Show(
      "OfficeGo no tiene permisos de administrador.`n`nPuede mirar las pantallas, pero no podrá instalar ni activar nada.`n`n¿Quiere reiniciarlo con permisos?",
      'OfficeGo', 'YesNoCancel', 'Warning')
    if ($r -eq 'Yes') {
      if (Invoke-Elevar) { return }
      [void][Windows.Forms.MessageBox]::Show(
        "No se pudo reiniciar con permisos.`n`nAbra PowerShell como administrador y pegue el comando otra vez.",
        'OfficeGo', 'OK', 'Information')
      return
    }
    if ($r -eq 'Cancel') { return }
  }

  Actualizar-BarraEstado
  Mostrar-Pantalla 'Inicio'
  [void]$frm.ShowDialog()
}

# ─────────────────────────────────────────────────────────────── entrada
function Start-OfficeGo {
  if ($Ayuda) { Show-Ayuda; return }

  # Sin ninguna orden se abre la ventana, que es lo que espera casi todo el mundo
  $porConsola = $Silencioso -or $Instalar -or $Desinstalar -or $Activar
  if (-not $porConsola) { Start-Ventana; return }

  $mal = Test-Peticion
  if ($mal) {
    Write-Host ""
    Write-Mal  $mal[0]
    Write-Paso $mal[1]
    Write-Host ""
    exit 1
  }

  # Por consola sí hay que elevarse antes de empezar: a medias no sirve de nada
  if (-not (Test-Administrador)) {
    Write-Host ""
    Write-Host '  OfficeGo necesita permisos de administrador. Pidiéndolos…' -ForegroundColor Yellow
    if (Invoke-Elevar) { return }
    Write-Mal 'No se concedieron los permisos.'
    exit 1
  }
  exit (Invoke-Consola)
}

Start-OfficeGo
