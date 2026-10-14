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
