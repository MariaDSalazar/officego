# =====================================================================
#  OfficeGo · interfaz (Windows Forms)
#  Solo dibuja y recoge lo que se elige. El trabajo lo hace el motor.
# =====================================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
try { [Windows.Forms.Application]::EnableVisualStyles() } catch {}
try { Add-Type -MemberDefinition '[DllImport("user32.dll")] public static extern bool SetProcessDPIAware();' `
        -Name D -Namespace W -PassThru | ForEach-Object { [void]$_::SetProcessDPIAware() } } catch {}

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
  $b.Add_Click({ Mostrar-Pantalla $this.Tag }.GetNewClosure())
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
