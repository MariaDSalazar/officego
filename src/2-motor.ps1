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

# Windows 10 sin actualizar negocia TLS 1.0 y los CDN de Microsoft lo
# rechazan: sin esto la descarga muere con "conexión cerrada".
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

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
  $gpu  = Get-CimInstance Win32_VideoController | Select-Object -First 1
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

function Get-EstadoLicencia {
  $ospp = "$env:ProgramFiles\Microsoft Office\Office16\ospp.vbs",
          "${env:ProgramFiles(x86)}\Microsoft Office\Office16\ospp.vbs" |
          Where-Object { Test-Path $_ } | Select-Object -First 1
  if (-not $ospp) { return $null }
  $salida = & cscript //nologo $ospp /dstatus 2>$null
  [pscustomobject]@{
    Activado = [bool]($salida -match '---LICENSED---')
    Nombre   = ($salida | Select-String 'LICENSE NAME' | Select-Object -First 1) -replace '.*:\s*', ''
    Dias     = ([regex]::Match(($salida -join "`n"), 'REMAINING GRACE:\s*(\d+)').Groups[1].Value)
    Cruda    = $salida
  }
}

# ─────────────────────────────────────────────── descarga con progreso real
function Invoke-Descarga {
  param([string]$Url, [string]$Destino, [scriptblock]$AlAvanzar)

  $req = [Net.HttpWebRequest]::Create($Url); $req.Timeout = 30000
  $res = $req.GetResponse()
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
  $url = "$($script:C2R_URL)?ProductreleaseID=$id&platform=x$Bits&language=$Idioma&version=$($Producto.Version)"
  Invoke-Descarga $url $exe $AlAvanzar | Out-Null
  Start-Process $exe -PassThru
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
