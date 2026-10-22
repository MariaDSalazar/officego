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

# Qué es lo instalado según el catálogo: versión, edición, aplicaciones sueltas
# y complementos. Los Retail sin año (2016 y 2013) se separan por la versión:
# la 15.x es 2013.
function Get-OfficeDescrito([string]$Productos, [string]$Version) {
  $ids = @($Productos -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
  $vieja = $Version -like '15.*'
  $r = @{ Producto = $null; Edicion = $null; Apps = @(); Complementos = @() }
  foreach ($id in $ids) {
    $suites = @($script:PRODUCTOS | Where-Object { $_.Ediciones.Values -contains $id })
    $suite = $suites | Where-Object { ($_.Clave -eq '2013') -eq $vieja } | Select-Object -First 1
    if (-not $suite) { $suite = $suites | Select-Object -First 1 }
    $extra = $script:COMPLEMENTOS | Where-Object { $_.Ids.Values -contains $id } | Select-Object -First 1
    $app = @($script:APLICACIONES.Keys) | Where-Object { $id -like "$_*" } | Select-Object -First 1
    if ($suite -and -not $r.Edicion) {
      $r.Producto = $suite.Clave
      $r.Edicion = @($suite.Ediciones.Keys) | Where-Object { $suite.Ediciones[$_] -eq $id } | Select-Object -First 1
    } elseif ($extra) {
      $r.Complementos += $extra.Clave
      if (-not $r.Producto) { $r.Producto = @($extra.Ids.Keys) | Where-Object { $extra.Ids[$_] -eq $id } | Select-Object -First 1 }
    } elseif ($app) {
      $r.Apps += $app
    }
  }
  if (-not $r.Producto) {
    if ($ids | Where-Object { $_ -like 'O365*' }) { $r.Producto = '365' }
    elseif ($Productos -match '20\d\d' -and ($script:PRODUCTOS.Clave -contains $Matches[0])) { $r.Producto = $Matches[0] }
    elseif ($vieja) { $r.Producto = '2013' }
  }
  $r
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

# La instalación por ODT va en dos tiempos: primero setup.exe /download
# deja Office en esta carpeta (se puede cortar y retomar) y después
# /configure instala desde ahí sin volver a internet.
function Get-CarpetaDescarga($Producto, [string]$Bits) {
  Join-Path $script:TRABAJO "Office-$($Producto.Clave)-$Bits"
}

# Hace que el XML tome Office de esa carpeta. Va escapado: una ruta con &
# rompía el XML.
function Add-OrigenAlXml([string]$Xml, [string]$Carpeta) {
  $ruta = [Security.SecurityElement]::Escape($Carpeta)
  $conRuta = (Get-Content $Xml -Raw).Replace('<Add ', "<Add SourcePath=`"$ruta`" ")
  [IO.File]::WriteAllText($Xml, $conRuta, [Text.UTF8Encoding]::new($false))
}

function Start-DescargaODT([string]$Setup, [string]$Xml) {
  Start-Process $Setup -ArgumentList "/download `"$Xml`"" -PassThru
}

# Cuánto de una descarga de Office ya está en el disco. setup.exe crea los
# .dat dispersos con su tamaño final desde el principio, así que su tamaño
# no dice nada: lo que ya bajó es lo que ocupan de verdad.
function Get-DescargaEnDisco([string]$Carpeta) {
  if (-not ('OfficeGo.Disco' -as [type])) {
    Add-Type -Namespace OfficeGo -Name Disco -MemberDefinition @'
[DllImport("kernel32.dll", CharSet = CharSet.Unicode)]
public static extern uint GetCompressedFileSizeW(string nombre, out uint alto);
'@
  }
  $hecho = [uint64]0; $total = [uint64]0
  foreach ($f in Get-ChildItem -LiteralPath $Carpeta -Recurse -File -ErrorAction SilentlyContinue) {
    $alto = [uint32]0
    $bajo = [OfficeGo.Disco]::GetCompressedFileSizeW($f.FullName, [ref]$alto)
    $hecho += [math]::Min([uint64]$f.Length, ([uint64]$alto -shl 32) + $bajo)
    $total += $f.Length
  }
  [pscustomobject]@{ Hecho = $hecho; Total = $total }
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
function New-CarpetaSinConexion {
  param($Producto, [string]$Edicion, [string]$Idioma, [string]$Bits,
        [string[]]$AppsQueSi, [string[]]$Complementos, [string]$Destino, [scriptblock]$AlAvanzar)

  New-Item -ItemType Directory -Force -Path $Destino | Out-Null
  $setup = Get-SetupODT $AlAvanzar
  $xml = New-ConfiguracionXml $Producto $Edicion $Idioma $Bits $AppsQueSi $Complementos

  Copy-Item $setup (Join-Path $Destino 'setup.exe') -Force
  Copy-Item $xml (Join-Path $Destino 'configuration.xml') -Force
  [IO.File]::WriteAllText((Join-Path $Destino 'instalar.cmd'),
    "@echo off`r`ncd /d `"%~dp0`"`r`nsetup.exe /configure configuration.xml`r`n", [Text.Encoding]::ASCII)

  Add-OrigenAlXml $xml $Destino
  [pscustomobject]@{ Setup = $setup; Xml = $xml }
}

function Start-DescargaSinConexion {
  param($Producto, [string]$Edicion, [string]$Idioma, [string]$Bits,
        [string[]]$AppsQueSi, [string[]]$Complementos, [string]$Destino, [scriptblock]$AlAvanzar)
  $c = New-CarpetaSinConexion @PSBoundParameters
  Start-DescargaODT $c.Setup $c.Xml
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
