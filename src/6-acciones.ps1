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
  if ($sis -and $sis.LibreGB -lt 5) {
    Avisar 'Espacio insuficiente' "Quedan $($sis.LibreGB) GB libres en $($sis.Letra) y hacen falta al menos 5 GB." 'Warning'
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
  if (-not (Test-Internet)) { Avisar 'Sin conexión' 'No se llega a los servidores de Microsoft.' 'Warning'; return }
  $dlg = New-Object Windows.Forms.FolderBrowserDialog
  $dlg.Description = 'Elija dónde guardar los archivos de instalación'
  if ($dlg.ShowDialog() -ne 'OK') { return }

  $prod = Get-Producto $script:sel.Producto
  if ($prod.Via -eq 'C2R') {
    Avisar 'No disponible' "Office $($prod.Clave) solo se puede instalar en línea: esa vía de Microsoft no permite descargar los archivos aparte." 'Information'
    return
  }
  try {
    Set-Progreso 0 'Descargando el instalador…'
    $setup = Get-SetupODT { param($pc, $h, $t) Set-Progreso $pc "Instalador: $pc %" }
    $xml = New-ConfiguracionXml $prod $script:sel.Edicion $script:sel.Idioma `
                                $script:sel.Bits $script:sel.Apps $script:sel.Complementos
    # SourcePath manda los archivos a la carpeta elegida
    (Get-Content $xml -Raw) -replace '<Add ', "<Add SourcePath=`"$($dlg.SelectedPath)`" " |
      Set-Content $xml -Encoding UTF8
    $p = Start-Process $setup -ArgumentList "/download `"$xml`"" -PassThru
    Seguir-Proceso $p 'Descargando Office' | Out-Null
    Set-Progreso 100 'Descarga terminada'
    Avisar 'Listo' "Los archivos quedaron en:`n$($dlg.SelectedPath)`n`nPara instalar en otro equipo, copie esa carpeta junto con setup.exe."
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
  $clave = ($clave -replace '[^A-Za-z0-9]', '').ToUpper()
  if ($clave.Length -ne 25) { Avisar 'Clave no válida' 'La clave debe tener 25 caracteres.' 'Warning'; return }

  $ospp = "$env:ProgramFiles\Microsoft Office\Office16\ospp.vbs",
          "${env:ProgramFiles(x86)}\Microsoft Office\Office16\ospp.vbs" |
          Where-Object { Test-Path $_ } | Select-Object -First 1
  if (-not $ospp) { Avisar 'No hay Office' 'No se encontró una instalación de Office.' 'Warning'; return }

  Set-Progreso -1 'Aplicando la clave…'
  $r = & cscript //nologo $ospp /inpkey:$clave 2>&1
  Set-Progreso 0 ''
  if ($r -match 'successful') {
    & cscript //nologo $ospp /act | Out-Null
    Avisar 'Listo' 'La clave se aplicó correctamente.'
  } else {
    Avisar 'No se pudo aplicar' ($r -join "`n") 'Warning'
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
  if (-not (Confirmar 'Reparar Office' "Se va a reparar la instalación.`n`nLos documentos y la licencia no se tocan. ¿Continuar?")) { return }
  try {
    Set-Progreso -1 'Descargando la herramienta…'
    $setup = Get-SetupODT { param($pc, $h, $t) Set-Progreso $pc "Descargando: $pc %" }
    $p = Start-Process $setup -ArgumentList '/configure repair.xml' -PassThru -ErrorAction Stop
    Seguir-Proceso $p 'Reparando Office' | Out-Null
    Set-Progreso 100 'Reparación terminada'
  } catch {
    Set-Progreso 0 ''
    Avisar 'No se pudo reparar' "Use Configuración > Aplicaciones > Microsoft Office > Modificar > Reparación en línea." 'Information'
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
