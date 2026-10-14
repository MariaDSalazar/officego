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
