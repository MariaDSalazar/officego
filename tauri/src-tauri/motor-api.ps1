# =====================================================================
#  OfficeGo · puente entre la interfaz web y el motor
#
#  Recibe una acción, devuelve JSON. Es el MISMO motor que usa la
#  versión de PowerShell: un arreglo en la lógica vale para las dos.
#
#  Uso:  motor-api.ps1 -Accion equipo
#        motor-api.ps1 -Accion instalar -Datos '{"producto":"2021",...}'
# =====================================================================
param(
  [Parameter(Mandatory)][string]$Accion,
  [string]$Datos = '{}'
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# El motor va incrustado por el compilador: aquí solo se carga.
. "$PSScriptRoot\motor\1-catalogo.ps1"
. "$PSScriptRoot\motor\2-motor.ps1"
. "$PSScriptRoot\motor\2b-recomendacion.ps1"

function Salida($obj) { $obj | ConvertTo-Json -Depth 6 -Compress }
function Error-Json($msg) { Salida @{ ok = $false; error = "$msg" } }

try {
  $d = $Datos | ConvertFrom-Json

  switch ($Accion) {

    'equipo' {
      $eq = Get-EquipoInfo
      $g  = Get-MarcaGrafica $eq.GPU
      Salida @{
        ok = $true
        equipo = $eq
        grafica = @{ marca = $g.Marca; color = $g.Color; sigla = $g.Sigla
                     antigua = (Test-GraficaAntigua $eq) }
        office = Get-OfficeInstalado
      }
    }

    'catalogo' {
      Salida @{
        ok = $true
        productos = @($script:PRODUCTOS | ForEach-Object {
          @{ clave=$_.Clave; nombre=$_.Nombre; sub=$_.Sub; sigla=$_.Sigla
             color=$_.Color; tipo=$_.Tipo; via=$_.Via; peso=$_.Peso
             canal=$_.Canal; ediciones=@($_.Ediciones.Keys) }
        })
        ediciones = $script:EDICIONES
        aplicaciones = $script:APLICACIONES
        complementos = @($script:COMPLEMENTOS | ForEach-Object {
          @{ clave=$_.Clave; nombre=$_.Nombre; sigla=$_.Sigla; color=$_.Color
             versiones=@($_.Ids.Keys) } })
        idiomas = $script:IDIOMAS
      }
    }

    'recomendar' {
      $eq = Get-EquipoInfo
      Salida @{ ok = $true; recomendacion = (Get-Recomendacion $eq) }
    }

    'licencia' {
      Salida @{ ok = $true; licencia = Get-EstadoLicencia }
    }

    'preparar-xml' {
      $prod = Get-Producto $d.producto
      $ruta = New-ConfiguracionXml $prod $d.edicion $d.idioma $d.bits `
                                   @($d.apps) @($d.complementos)
      Salida @{ ok = $true; xml = $ruta; contenido = (Get-Content $ruta -Raw) }
    }

    # La instalación escribe el progreso línea a línea para que la
    # interfaz lo lea según va saliendo, sin esperar al final.
    'instalar' {
      $prod = Get-Producto $d.producto
      if ($prod.Via -eq 'ODT') {
        Write-Host (Salida @{ evento='paso'; texto='Descargando el instalador'; pc=0 })
        $setup = Get-SetupODT { param($pc,$h,$t)
          Write-Host (Salida @{ evento='progreso'; pc=$pc; hecho=$h; total=$t }) }
        $xml = New-ConfiguracionXml $prod $d.edicion $d.idioma $d.bits @($d.apps) @($d.complementos)
        Write-Host (Salida @{ evento='paso'; texto='Instalando Office'; pc=100 })
        $p = Start-InstalacionODT $setup $xml
      } else {
        Write-Host (Salida @{ evento='paso'; texto='Descargando Office'; pc=0 })
        $p = Start-InstalacionC2R $prod $d.edicion $d.idioma $d.bits { param($pc,$h,$t)
          Write-Host (Salida @{ evento='progreso'; pc=$pc; hecho=$h; total=$t }) }
      }
      $t0 = Get-Date
      while (-not $p.HasExited) {
        Start-Sleep -Milliseconds 900
        Write-Host (Salida @{ evento='espera'; segundos=[int]((Get-Date)-$t0).TotalSeconds })
      }
      $ok = [bool](Get-OfficeInstalado)
      Write-Host (Salida @{ evento='fin'; ok=$ok; codigo=$p.ExitCode })
    }

    'activar' {
      Write-Host (Salida @{ evento='paso'; texto='Descargando MAS' })
      $p = Invoke-MAS 'Ohook'
      while (-not $p.HasExited) { Start-Sleep -Milliseconds 900
        Write-Host (Salida @{ evento='espera' }) }
      Start-Sleep -Seconds 2
      $lic = Get-EstadoLicencia
      Write-Host (Salida @{ evento='fin'; ok=[bool]($lic -and $lic.Activado); licencia=$lic })
    }

    'desinstalar' {
      $setup = Get-SetupODT { param($pc,$h,$t)
        Write-Host (Salida @{ evento='progreso'; pc=$pc }) }
      $p = Start-InstalacionODT $setup (New-XmlDesinstalar)
      while (-not $p.HasExited) { Start-Sleep -Milliseconds 900
        Write-Host (Salida @{ evento='espera' }) }
      Write-Host (Salida @{ evento='fin'; ok=(-not (Get-OfficeInstalado)) })
    }

    default { Error-Json "Acción desconocida: $Accion" }
  }
}
catch { Error-Json $_.Exception.Message }
