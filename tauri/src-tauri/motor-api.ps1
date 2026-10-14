# =====================================================================
#  OfficeGo · puente entre la versión de escritorio y el motor
#
#  Es el MISMO motor que usa la versión de PowerShell: un arreglo en la
#  lógica vale para las dos. Aquí solo se traduce: la petición llega en
#  la variable OFFICEGO_PAYLOAD como JSON ({"action":"machine",...}) y la
#  respuesta sale en JSON con los nombres que espera Rust (model.rs).
#
#  Consultas: una línea {"data":...} o {"error":"..."}.
#  Tareas:    una línea por evento (step, progress, waiting) y al final
#             {"event":"done",...} o {"event":"failed","error":"..."}.
# =====================================================================
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
# Sin esto la salida va en la página de códigos OEM y Rust, que lee UTF-8,
# recibía «versi�n».
[Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)

. "$PSScriptRoot\motor\1-catalogo.ps1"
. "$PSScriptRoot\motor\2-motor.ps1"
. "$PSScriptRoot\motor\2b-recomendacion.ps1"

function Json($obj) { $obj | ConvertTo-Json -Depth 8 -Compress }
function Responder($data) { Write-Host (Json @{ data = $data }) }
function Evento($obj) { Write-Host (Json $obj) }
function Fin($ok, $extra = @{}) { Evento (@{ event = 'done'; ok = [bool]$ok } + $extra) }

function Esperar($p) {
  $t0 = Get-Date
  while (-not $p.HasExited) {
    Start-Sleep -Milliseconds 900
    Evento @{ event = 'waiting'; seconds = [int]((Get-Date) - $t0).TotalSeconds }
  }
  $p.ExitCode
}

$alAvanzar = { param($pc, $h, $t)
  Evento @{ event = 'progress'; percent = [int]$pc; doneMb = [double]$h; totalMb = [double]$t } }

$MARCAS = @{ 'NVIDIA' = 'nvidia'; 'AMD' = 'amd'; 'Intel' = 'intel'; 'Sin controlador' = 'noDriver'
             'Otra' = 'other'; 'Desconocida' = 'unknown' }

function Get-Seleccion($s) {
  [pscustomobject]@{
    Producto = Get-Producto $s.product; Edicion = [string]$s.edition; Idioma = [string]$s.language
    Bits = [string]$s.bits; Apps = @($s.apps); Complementos = @($s.addOns)
  }
}

function Get-MotivoNoListo {
  if (-not (Test-Administrador)) { return 'notAdmin' }
  $sis = (Get-EquipoInfo).Discos | Where-Object { $_.Sistema } | Select-Object -First 1
  if ($sis -and $sis.LibreGB -lt $script:DISCO_MINIMO_GB) { return 'lowDisk' }
  if (-not (Test-Internet)) { return 'offline' }
  $null
}

function Get-Licencia {
  $lic = Get-EstadoLicencia
  if (-not $lic) { return $null }
  @{ activated = [bool]$lic.Activado; name = [string]$lic.Nombre }
}

try {
  $d = $env:OFFICEGO_PAYLOAD | ConvertFrom-Json

  switch ($d.action) {

    'catalog' {
      Responder @{
        products = @($script:PRODUCTOS | ForEach-Object {
          @{ key = $_.Clave; name = $_.Nombre; abbreviation = $_.Sigla; color = $_.Color
             route = $_.Via.ToLower(); channel = [string]$_.Canal; weightGb = [double]$_.Peso
             minimumBuild = [int]$_.BuildMinimo; editions = @($_.Ediciones.Keys) } })
        editions = @($script:EDICIONES.Keys | ForEach-Object {
          @{ key = $_; name = $script:EDICIONES[$_].Nombre; apps = @($script:EDICIONES[$_].Apps) } })
        apps = @($script:APLICACIONES.Keys | ForEach-Object {
          $a = $script:APLICACIONES[$_]
          @{ key = $_; name = $a.Nombre; abbreviation = $a.Sigla; color = $a.Color } })
        addOns = @($script:COMPLEMENTOS | ForEach-Object {
          @{ key = $_.Clave; name = $_.Nombre; abbreviation = $_.Sigla; color = $_.Color
             products = @($_.Ids.Keys) } })
        languages = @($script:IDIOMAS.Keys)
        addOnWeightGb = [double]$script:PESO_COMPLEMENTO_GB
        minimumFreeGb = [double]$script:DISCO_MINIMO_GB
        workFolder = $script:TRABAJO
      }
    }

    'machine' {
      $eq  = Get-EquipoInfo
      $g   = Get-MarcaGrafica $eq.GPU
      $rec = Get-Recomendacion $eq
      $of  = Get-OfficeInstalado
      Responder @{
        machine = @{
          os = [string]$eq.SO; build = [string]$eq.Build; supported = [bool]$eq.Compatible
          architecture = [string]$eq.Arquitectura; bits = [string]$eq.Bits; powershell = [string]$eq.PowerShell
          cpu = [string]$eq.CPU; cpuGhz = [double]$eq.CPUGhz; cores = [int]$eq.Nucleos; threads = [int]$eq.Hilos
          cpuLoad = [int]$eq.CPUUso; ramGb = [double]$eq.RamGB; ramFreeGb = [double]$eq.RamLibreGB
          ramLoad = [int]$eq.RamUsoPc; ramModules = [int]$eq.RamModulos; ramSpeed = [string]$eq.RamTipo
          gpu = [string]$eq.GPU; resolution = [string]$eq.Resolucion; admin = [bool]$eq.Admin
          defender = $eq.Defender
          disks = @($eq.Discos | ForEach-Object {
            @{ letter = [string]$_.Letra; totalGb = [double]$_.TotalGB; freeGb = [double]$_.LibreGB
               usedPercent = [int]$_.UsadoPc; system = [bool]$_.Sistema } })
        }
        graphics = @{ brand = $MARCAS[$g.Marca]; color = $g.Color; abbreviation = $g.Sigla
                      old = [bool](Test-GraficaAntigua $eq) }
        office = $(if ($of) { @{ products = [string]$of.Productos; version = [string]$of.Version
                                 language = [string]$of.Idioma; architecture = [string]$of.Arquitectura } })
        recommendation = @{
          product = $rec.Clave; reason = $rec.Codigo; supported = [bool]$rec.Apto
          warnings = @($rec.Avisos | ForEach-Object { @{ level = $_.Tipo; code = $_.Codigo; values = $_.Datos } })
        }
      }
    }

    'license' { Responder (Get-Licencia) }

    'configuration' {
      $s = Get-Seleccion $d.selection
      $ruta = New-ConfiguracionXml $s.Producto $s.Edicion $s.Idioma $s.Bits $s.Apps $s.Complementos
      # Get-Content no: en 5.1 su texto lleva PSDrive y PSProvider colgando
      # y ConvertTo-Json se queda recorriéndolos sin terminar nunca
      Responder ([IO.File]::ReadAllText($ruta))
    }

    'install' {
      $no = Get-MotivoNoListo
      if ($no) { Fin $false @{ reason = $no }; break }
      $s = Get-Seleccion $d.selection
      $habia = [bool](Get-OfficeInstalado)
      if ($s.Producto.Via -eq 'ODT') {
        Evento @{ event = 'step'; step = 'downloadSetup' }
        $setup = Get-SetupODT $alAvanzar
        $xml = New-ConfiguracionXml $s.Producto $s.Edicion $s.Idioma $s.Bits $s.Apps $s.Complementos
        Evento @{ event = 'step'; step = 'install' }
        $p = Start-InstalacionODT $setup $xml
      } else {
        Evento @{ event = 'step'; step = 'downloadOffice' }
        $p = Start-InstalacionC2R $s.Producto $s.Edicion $s.Idioma $s.Bits $alAvanzar
        Evento @{ event = 'step'; step = 'install' }
      }
      $rc = Esperar $p
      # Si ya había Office, que siga estando no prueba nada: manda el código
      $ok = [bool](Get-OfficeInstalado) -and ($rc -eq 0 -or -not $habia)
      Fin $ok @{ exitCode = $rc; reason = $(if (-not $ok) { 'installerFailed' }) }
    }

    'download' {
      $s = Get-Seleccion $d.selection
      if ($s.Producto.Via -eq 'C2R') { Fin $false @{ reason = 'onlineOnly' }; break }
      if (-not (Test-Internet)) { Fin $false @{ reason = 'offline' }; break }
      Evento @{ event = 'step'; step = 'downloadSetup' }
      $p = Start-DescargaSinConexion $s.Producto $s.Edicion $s.Idioma $s.Bits $s.Apps $s.Complementos `
             ([string]$d.folder) $alAvanzar
      Evento @{ event = 'step'; step = 'downloadOffice' }
      $rc = Esperar $p
      Fin ($rc -eq 0) @{ exitCode = $rc; folder = [string]$d.folder; reason = $(if ($rc) { 'installerFailed' }) }
    }

    'activate' {
      if (-not (Test-Administrador)) { Fin $false @{ reason = 'notAdmin' }; break }
      Evento @{ event = 'step'; step = 'activate' }
      $p = Invoke-MAS 'Ohook'
      Esperar $p | Out-Null
      Start-Sleep -Seconds 2
      $lic = Get-Licencia
      Fin ($lic -and $lic.activated) @{ reason = $(if (-not ($lic -and $lic.activated)) { 'notActivated' }) }
    }

    'apply-key' {
      if (-not (Test-Administrador)) { Fin $false @{ reason = 'notAdmin' }; break }
      Evento @{ event = 'step'; step = 'applyKey' }
      $r = Set-ClaveProducto ([string]$d.key)
      Fin $r.Ok @{ reason = $(if ($r.Motivo) { $r.Motivo }); detail = $r.Salida }
    }

    'repair' {
      if (-not (Get-OfficeInstalado)) { Fin $false @{ reason = 'noOffice' }; break }
      if (-not (Test-Administrador)) { Fin $false @{ reason = 'notAdmin' }; break }
      Evento @{ event = 'step'; step = 'repair' }
      $rc = Esperar (Start-Reparacion 'Rapida')
      Fin ($rc -eq 0) @{ exitCode = $rc; reason = $(if ($rc) { 'installerFailed' }) }
    }

    'uninstall' {
      if (-not (Get-OfficeInstalado)) { Fin $false @{ reason = 'noOffice' }; break }
      if (-not (Test-Administrador)) { Fin $false @{ reason = 'notAdmin' }; break }
      Evento @{ event = 'step'; step = 'downloadSetup' }
      $setup = Get-SetupODT $alAvanzar
      Evento @{ event = 'step'; step = 'uninstall' }
      $rc = Esperar (Start-InstalacionODT $setup (New-XmlDesinstalar))
      $ok = -not (Get-OfficeInstalado)
      Fin $ok @{ exitCode = $rc; reason = $(if (-not $ok) { 'stillInstalled' }) }
    }

    default { throw "Acción desconocida: $($d.action)" }
  }
}
catch {
  Write-Host (Json @{ event = 'failed'; error = $_.Exception.Message })
}
