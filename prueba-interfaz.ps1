# =====================================================================
#  Revisa el reparto de la ventana sin necesitar Windows.
#
#  Monta las seis pantallas con controles de mentira que solo guardan
#  dónde y cuánto ocupan, y busca lo que Windows Forms no avisa nunca:
#  controles encima de otros y controles que se salen de su caja.
#
#  El ancho de las etiquetas que se dimensionan solas se estima con una
#  tabla de anchos de Segoe UI, así que no es exacto al píxel. Por eso
#  está -Factor: a 1.15 simula una letra un 15 % más ancha, que es lo
#  que pasa en un equipo con otro escalado. Lo que aguanta eso, aguanta.
#
#      pwsh prueba-interfaz.ps1                 reparto tal cual
#      pwsh prueba-interfaz.ps1 -Factor 1.15    con la letra más ancha
# =====================================================================
param([double]$Factor = 1.0, [int]$Holgura = 0)

$ErrorActionPreference = 'Stop'
if (-not $env:TEMP) { $env:TEMP = '/tmp' }

# ── anchos de Segoe UI 9 pt, en píxeles y por carácter
$script:ANCHOS = @{}
function Anchos([string]$chars, [double]$px) {
  $chars.ToCharArray() | ForEach-Object { $script:ANCHOS[$_] = $px }
}
Anchos "iljI.,;:!|'$([char]34)$([char]96)()[]{}/" 3.4
Anchos ' '  3.6
Anchos 'ftr-' 4.6
Anchos 'abcdeghknopqsuvxyzáéíóúüñ0123456789%' 6.4
Anchos 'ABCDEFGHKLNOPQRSTUVXYZÁÉÍÓÚÑ·×' 8.0
Anchos 'MWmw' 10.2

function Medir([string]$t, [double]$pt = 9, [bool]$bold = $false) {
  if (-not $t) { return 0 }
  $ancho = 0.0
  foreach ($c in $t.ToCharArray()) {
    $ancho += $(if ($script:ANCHOS.ContainsKey($c)) { $script:ANCHOS[$c] } else { 6.8 })
  }
  $ancho = $ancho * ($pt / 9.0) * $Factor
  if ($bold) { $ancho *= 1.06 }
  [int][Math]::Ceiling($ancho)
}

# alto de una etiqueta AutoSize en Segoe UI: 9 pt da 15 px, 10 pt da 17,
# 11,5 da 19. Sale bastante recto a 1,67 px por punto. El factor entra
# aquí también: con la pantalla al 125 % la letra crece a lo alto igual
# que a lo ancho, y es ahí donde se acaba solapando.
function AltoLinea([double]$pt) { [int][Math]::Round($pt * 1.67 * $Factor) }

# ══════════════════════════════════════════════════ controles de mentira
class Punto2 { [int]$X; [int]$Y; Punto2([int]$x, [int]$y) { $this.X = $x; $this.Y = $y } }
class Tam2   { [int]$Width; [int]$Height; Tam2([int]$w, [int]$h) { $this.Width = $w; $this.Height = $h } }

# Controls es un Collection[object] y no un ArrayList a propósito: su
# Add devuelve void, igual que el de Windows Forms. Con ArrayList devuelve
# el índice, y ese número se cuela en lo que devuelven New-Caja y compañía.
class Falso {
  [string]$Tipo = 'Panel'
  [int]$Left; [int]$Top; [int]$Width = 100; [int]$Height = 23
  [string]$Text = ''
  [bool]$AutoSize
  [double]$Pt = 9
  [bool]$Bold
  [object]$Tag
  [object]$Padre
  [object]$Controls

  Falso() { $this.Controls = [System.Collections.ObjectModel.Collection[object]]::new() }

  # lo que Windows Forms hace con una etiqueta que se ajusta al texto
  [void] Ajustar() {
    if ($this.AutoSize -and $this.Text) {
      $this.Width  = Medir $this.Text $this.Pt $this.Bold
      # alto de una etiqueta AutoSize en Segoe UI: 9 pt da 15 px, 10 pt
      # da 17, 11,5 da 19. Sale bastante recto a 1,67 px por punto.
      # El factor también entra aquí: con la pantalla al 125 % la letra
      # crece a lo alto igual que a lo ancho, y ahí es donde se solapa.
      $this.Height = AltoLinea $this.Pt
    }
  }
  [string] Etiqueta() {
    $t = if ($this.Text) { $this.Text } else { "($($this.Tipo) sin texto)" }
    if ($t.Length -gt 32) { $t = $t.Substring(0, 30) + '…' }
    return "$($this.Tipo) «$t»"
  }
}

function Nuevo([string]$tipo) {
  $c = [Falso]::new()
  $c.Tipo = $tipo
  $c | Add-Member -MemberType ScriptProperty -Name Location `
        -Value { [Punto2]::new($this.Left, $this.Top) } `
        -SecondValue { param($v) $this.Left = $v.X; $this.Top = $v.Y } -Force
  $c | Add-Member -MemberType ScriptProperty -Name Size `
        -Value { [Tam2]::new($this.Width, $this.Height) } `
        -SecondValue { param($v) $this.Width = $v.Width; $this.Height = $v.Height } -Force
  foreach ($m in 'Add_Click','Add_Paint','Add_SelectedIndexChanged','Add_CheckedChanged',
                 'Add_MouseEnter','Add_MouseLeave','Add_TextChanged','Add_KeyDown','Add_Shown',
                 'Add_LinkClicked','Add_Scroll','Add_Tick','Add_FormClosing',
                 'BringToFront','SendToBack','Focus','Refresh','Select','ShowDialog','Close',
                 'PerformClick','ResumeLayout','SuspendLayout','Dispose','Start','Stop') {
    $c | Add-Member -MemberType ScriptMethod -Name $m -Value {} -Force
  }
  $c | Add-Member -NotePropertyMembers @{
    Items = [System.Collections.ArrayList]::new(); SelectedIndex = 0; SelectedItem = ''
    Checked = $false; Value = 0; Maximum = 100; Minimum = 0; Enabled = $true; Visible = $true
    BackColor = ''; ForeColor = ''; Font = $null; FlatStyle = ''; Cursor = ''; TextAlign = ''
    Region = $null; Style = ''; DropDownStyle = ''; AutoScroll = $false; Anchor = ''
    FormBorderStyle = ''; MaximizeBox = $true; StartPosition = ''; Icon = $null; Dock = ''
    FlatAppearance = ([pscustomobject]@{ BorderSize = 1; BorderColor = ''; MouseOverBackColor = '' })
    LinkColor = ''; ActiveLinkColor = ''; LinkBehavior = ''; UseCompatibleTextRendering = $false
    Padding = $null; Margin = $null; MinimumSize = $null; MaximumSize = $null; Multiline = $false
    Interval = 100; UseMnemonic = $false; TabIndex = 0; TabStop = $true
  } -Force
  $c
}

# ── New-Object devuelve los de mentira
function New-Object {
  param(
    [Parameter(Position = 0)][string]$TypeName,
    [Parameter(Position = 1)][object[]]$ArgumentList,
    [string]$ComObject, [switch]$Strict, [hashtable]$Property
  )
  switch -Regex ($TypeName) {
    'Drawing\.Point$' { return [Punto2]::new($ArgumentList[0], $ArgumentList[1]) }
    'Drawing\.Size$'  { return [Tam2]::new($ArgumentList[0], $ArgumentList[1]) }
    'Windows\.Forms\.(\w+)' { return (Nuevo $Matches[1]) }
    default { return [pscustomobject]@{ Tipo = $TypeName } }
  }
}

# ── y lo que no existe fuera de Windows
function Add-Type { param([Parameter(ValueFromRemainingArguments)]$r) }
function Hex($h) { $h }
function Get-CimInstance { param([Parameter(ValueFromRemainingArguments)]$r) $null }
function Get-MpComputerStatus { $null }

# ── carga un .ps1 quitándole los tipos que solo existen en Windows
#
# Se cambian por cadenas: al analizador le da igual el color o el estilo
# de la letra, solo le importan las coordenadas. Lo que no se toca es el
# tamaño en puntos, porque de ahí sale el ancho de cada texto.
function Preparar($ruta) {
  $t = [IO.File]::ReadAllText("$PSScriptRoot/$ruta")
  # primero las llamadas con paréntesis, que si no quedan colgando
  $t = [regex]::Replace($t, '\[(?:System\.)?(?:Windows\.Forms|Drawing)[\w.]*\]::(\w+)\((?:[^()]|\([^()]*\))*\)', '$null')
  # y luego las propiedades sueltas
  $t = [regex]::Replace($t, '\[(?:System\.)?(?:Windows\.Forms|Drawing)[\w.]*\]::(\w+)', "'`$1'")
  # "$_ -is [Windows.Forms.Button]" pasa a mirar el tipo de mentira
  $t = [regex]::Replace($t, '(\$\w+) -is \[(?:System\.)?Windows\.Forms\.(\w+)\]', "`$1.Tipo -eq '`$2'")
  # y lo que quede de esos espacios de nombres deja de ser un tipo
  $t = [regex]::Replace($t, '\[(?:System\.)?(?:Windows\.Forms|Drawing)[\w.]*\](?!::)', '[object]')
  # las esquinas redondeadas se dibujan con GDI+, que aquí no hay
  $t = $t -replace '(?s)function Set-Redondeado\(.*?\r?\n\}', 'function Set-Redondeado($ctl, $r = 8) { }'
  $t
}

$null = . ([scriptblock]::Create((Preparar 'src/1-catalogo.ps1')))
$null = . ([scriptblock]::Create((Preparar 'src/2-motor.ps1')))
$null = . ([scriptblock]::Create((Preparar 'src/2b-recomendacion.ps1')))

# ── un equipo de mentira, para que las pantallas tengan qué enseñar.
#    Los nombres son largos a propósito: los de verdad lo son, y es
#    justo ahí donde revienta un reparto apretado.
function Get-EquipoInfo {
  [pscustomobject]@{
    SO = 'Windows 11 Pro'; Build = '22631.4460'; EsWin11 = $true; Compatible = $true
    Arquitectura = '64 bits'; Bits = '64'; Instalado = '2024-01-15'; PowerShell = '5.1.22621.4391'
    CPU = 'AMD Ryzen 7 5800X 8-Core Processor'; CPUGhz = 3.8; Nucleos = 8; Hilos = 16; CPUUso = 23
    RamGB = 15.9; RamLibreGB = 9.4; RamUsoPc = 41; RamModulos = 2; RamTipo = '3200 MHz'
    GPU = 'NVIDIA GeForce RTX 4060 Laptop GPU'; Resolucion = '1920 × 1080'
    Admin = $true; Defender = $true
    Discos = @(
      [pscustomobject]@{ Letra = 'C:'; TotalGB = 476.9; LibreGB = 240.3; UsadoPc = 49; Sistema = $true }
      [pscustomobject]@{ Letra = 'D:'; TotalGB = 931.5; LibreGB = 512.8; UsadoPc = 45; Sistema = $false })
  }
}
function Test-Internet { $true }
function Test-Administrador { $true }
function Test-DefenderBloquea { $true }
function Get-OfficeInstalado {
  @{ Instalado = $true; Nombre = 'Microsoft Office LTSC Professional Plus 2021'
     Version = '16.0.14332.20255' }
}
function Get-EstadoLicencia { @{ Activado = $false; Estado = 'Sin licencia'; Cruda = '' } }

$null = . ([scriptblock]::Create((Preparar 'src/3-interfaz.ps1')))

# New-Lbl se vuelve a definir para quedarse con el tamaño de letra: sin
# él no se puede medir cuánto ocupa cada texto, que es de lo que va esto.
function New-Lbl($txt, $x, $y, $tam = 9, $col = '#000', $bold = $false, $ancho = 0) {
  $l = Nuevo 'Label'
  $l.Text = "$txt"; $l.Left = $x; $l.Top = $y; $l.Pt = $tam; $l.Bold = $bold
  if ($ancho) { $l.AutoSize = $false; $l.Width = $ancho; $l.Height = 40 }
  else { $l.AutoSize = $true; $l.Ajustar() }
  $l
}

$null = . ([scriptblock]::Create((Preparar 'src/4-pantallas.ps1')))
$null = . ([scriptblock]::Create((Preparar 'src/5-inicio.ps1')))
$null = . ([scriptblock]::Create((Preparar 'src/6-acciones.ps1')))
$null = . ([scriptblock]::Create((Preparar 'src/7-arranque.ps1')))

# ══════════════════════════════════════════════════════════════ análisis
function Recorrer($ctl, $ox, $oy) {
  $r = @()
  foreach ($h in $ctl.Controls) {
    $r += [pscustomobject]@{
      Ctl = $h; Padre = $ctl
      X1 = $ox + $h.Left;            Y1 = $oy + $h.Top
      X2 = $ox + $h.Left + $h.Width; Y2 = $oy + $h.Top + $h.Height
    }
    if ($h.Controls.Count) { $r += Recorrer $h ($ox + $h.Left) ($oy + $h.Top) }
  }
  $r
}

$script:problemas = 0

function Analizar($pantalla) {
  Write-Host "`n$($pantalla.ToUpper())" -ForegroundColor Cyan
  $cont.Controls.Clear()
  $null = Mostrar-Pantalla $pantalla
  $todos = @(Recorrer $cont 0 0)
  $malos = 0

  # ── 1 · controles encima de otros, entre hermanos
  foreach ($g in ($todos | Group-Object { $_.Padre.GetHashCode() })) {
    $l = @($g.Group)
    for ($i = 0; $i -lt $l.Count; $i++) {
      for ($j = $i + 1; $j -lt $l.Count; $j++) {
        $a = $l[$i]; $b = $l[$j]
        if (($a.X1 - $Holgura) -lt $b.X2 -and ($b.X1 - $Holgura) -lt $a.X2 -and
            ($a.Y1 - $Holgura) -lt $b.Y2 -and ($b.Y1 - $Holgura) -lt $a.Y2) {
          $px = [Math]::Min($a.X2, $b.X2) - [Math]::Max($a.X1, $b.X1)
          $py = [Math]::Min($a.Y2, $b.Y2) - [Math]::Max($a.Y1, $b.Y1)
          Write-Host ("  ENCIMA   {0}  en ({1},{2}) de {3}x{4}`n           {5}  en ({6},{7}) de {8}x{9}`n           se pisan {10}x{11} px" -f `
            $a.Ctl.Etiqueta(), $a.X1, $a.Y1, $a.Ctl.Width, $a.Ctl.Height,
            $b.Ctl.Etiqueta(), $b.X1, $b.Y1, $b.Ctl.Width, $b.Ctl.Height,
            $px, $py) -ForegroundColor Red
          $malos++; $script:problemas++
        }
      }
    }
  }

  # ── 2 · controles que se salen de su caja
  foreach ($t in $todos) {
    $p = $t.Padre
    if ($p -eq $cont -or $p.AutoScroll) { continue }
    $dx = ($t.Ctl.Left + $t.Ctl.Width)  - $p.Width
    $dy = ($t.Ctl.Top  + $t.Ctl.Height) - $p.Height
    if ($dx -gt 2 -or $dy -gt 2) {
      Write-Host ("  SE SALE  {0}`n           de {1}: {2} px por la derecha, {3} por abajo" -f `
        $t.Ctl.Etiqueta(), $p.Etiqueta(), [Math]::Max(0,$dx), [Math]::Max(0,$dy)) -ForegroundColor Yellow
      $malos++; $script:problemas++
    }
  }

  # ── 3 · lo que se sale de la ventana por la derecha
  foreach ($t in ($todos | Where-Object { $_.X2 -gt $cont.Width + 2 })) {
    Write-Host ("  FUERA    {0}`n           llega a x={1} y el ancho útil es {2}" -f `
      $t.Ctl.Etiqueta(), $t.X2, $cont.Width) -ForegroundColor Yellow
    $malos++; $script:problemas++
  }

  if (-not $malos) {
    $hasta = ($todos | Measure-Object Y2 -Maximum).Maximum
    Write-Host ("  limpia · {0} controles · baja hasta y={1} de {2}" -f `
      $todos.Count, $hasta, $cont.Height) -ForegroundColor Green
  }
}

# ── lo primero, un vistazo al código: dentro de un GetNewClosure() las
#    variables $script: apuntan al módulo del closure y no al script, así
#    que cualquier asignación se pierde y el botón se queda mudo. Es el
#    fallo que dejaba la pantalla Instalar sin responder a nada.
Write-Host "`nCLOSURES QUE SE COMEN EL ESTADO" -ForegroundColor Cyan
$sospechosos = 0
foreach ($f in (Get-ChildItem "$PSScriptRoot/src" -Filter '*.ps1')) {
  $ast = [System.Management.Automation.Language.Parser]::ParseFile($f.FullName, [ref]$null, [ref]$null)
  $llamadas = $ast.FindAll({ param($n)
    $n -is [System.Management.Automation.Language.InvokeMemberExpressionAst] -and
    $n.Member.Value -eq 'GetNewClosure' }, $true)
  foreach ($ll in $llamadas) {
    $vars = $ll.Expression.FindAll({ param($n)
      $n -is [System.Management.Automation.Language.VariableExpressionAst] -and
      $n.VariablePath.IsScript }, $true)
    if ($vars) {
      $nombres = (($vars.VariablePath.UserPath -replace '^script:') | Sort-Object -Unique) -join ', '
      Write-Host ("  ROTO   {0}:{1}  usa `$script:{2} dentro de un GetNewClosure()" -f `
        $f.Name, $ll.Extent.StartLineNumber, $nombres) -ForegroundColor Red
      $sospechosos++; $script:problemas++
    }
  }
}
if (-not $sospechosos) { Write-Host "  ninguno" -ForegroundColor Green }

Write-Host "`nLetra al $([int]($Factor*100)) % · holgura exigida $Holgura px" -ForegroundColor DarkGray
foreach ($p in $script:PANTALLAS) { Analizar $p }

# ── la barra de estado se pinta aparte, con textos que dependen del
#    equipo: un nombre de Windows largo empujaba lo demás fuera
Write-Host "`nBARRA DE ESTADO" -ForegroundColor Cyan
foreach ($so in @('Windows 11 Pro', 'Windows 10 Enterprise LTSC 2021', 'Windows Server 2022 Datacenter')) {
  $script:equipo = Get-EquipoInfo
  $script:equipo.SO = $so
  $barra.Controls.Clear()
  $null = Actualizar-BarraEstado
  $items = @(Recorrer $barra 0 0)
  $choque = $false
  for ($i = 0; $i -lt $items.Count; $i++) {
    for ($j = $i + 1; $j -lt $items.Count; $j++) {
      $a = $items[$i]; $b = $items[$j]
      if ($a.X1 -lt $b.X2 -and $b.X1 -lt $a.X2 -and $a.Y1 -lt $b.Y2 -and $b.Y1 -lt $a.Y2) {
        Write-Host ("  ENCIMA  [{0}]  {1} × {2}" -f $so, $a.Ctl.Etiqueta(), $b.Ctl.Etiqueta()) -ForegroundColor Red
        $choque = $true; $script:problemas++
      }
    }
  }
  $ultimo = ($items | Measure-Object X2 -Maximum).Maximum
  if ($ultimo -gt $barra.Width) {
    Write-Host ("  FUERA   [{0}]  llega a x={1} y la barra mide {2}" -f $so, $ultimo, $barra.Width) -ForegroundColor Yellow
    $choque = $true; $script:problemas++
  }
  if (-not $choque) { Write-Host ("  ok   {0,-32} termina en x={1} de {2}" -f $so, $ultimo, $barra.Width) -ForegroundColor Green }
}
$script:equipo = $null

# ── Instalar cambia entera según lo elegido, así que se recorre todo el
#    catálogo. El fallo de la sexta tarjeta solo salía con seis productos.
Write-Host "`nINSTALAR, VERSIÓN POR VERSIÓN" -ForegroundColor Cyan
foreach ($prod in $script:PRODUCTOS) {
  foreach ($ed in $prod.Ediciones.Keys) {
    $script:sel.Producto = $prod.Clave
    $script:sel.Edicion  = $ed
    $script:sel.Complementos = @($script:COMPLEMENTOS | Where-Object { $_.Ids[$prod.Clave] } | ForEach-Object { $_.Clave })
    $antes = $script:problemas
    $cont.Controls.Clear()
    $null = Mostrar-Pantalla 'Instalar'
    $todos = @(Recorrer $cont 0 0)
    $etiqueta = "{0} · {1}" -f $prod.Nombre, $ed

    foreach ($g in ($todos | Group-Object { $_.Padre.GetHashCode() })) {
      $l = @($g.Group)
      for ($i = 0; $i -lt $l.Count; $i++) {
        for ($j = $i + 1; $j -lt $l.Count; $j++) {
          $a = $l[$i]; $b = $l[$j]
          if (($a.X1 - $Holgura) -lt $b.X2 -and ($b.X1 - $Holgura) -lt $a.X2 -and
              ($a.Y1 - $Holgura) -lt $b.Y2 -and ($b.Y1 - $Holgura) -lt $a.Y2) {
            Write-Host ("  ENCIMA  [{0}]  {1} en ({2},{3})  ×  {4} en ({5},{6})" -f `
              $etiqueta, $a.Ctl.Etiqueta(), $a.X1, $a.Y1, $b.Ctl.Etiqueta(), $b.X1, $b.Y1) -ForegroundColor Red
            $script:problemas++
          }
        }
      }
    }
    foreach ($x in $todos) {
      $pa = $x.Padre
      if ($pa -eq $cont -or $pa.AutoScroll) { continue }
      if (($x.Ctl.Left + $x.Ctl.Width) - $pa.Width -gt 2 -or ($x.Ctl.Top + $x.Ctl.Height) - $pa.Height -gt 2) {
        Write-Host ("  SE SALE [{0}]  {1} de {2}" -f $etiqueta, $x.Ctl.Etiqueta(), $pa.Etiqueta()) -ForegroundColor Yellow
        $script:problemas++
      }
    }
    foreach ($x in ($todos | Where-Object { $_.X2 -gt $cont.Width + 2 })) {
      Write-Host ("  FUERA   [{0}]  {1} llega a x={2}" -f $etiqueta, $x.Ctl.Etiqueta(), $x.X2) -ForegroundColor Yellow
      $script:problemas++
    }
    if ($script:problemas -eq $antes) {
      $hasta = ($todos | Measure-Object Y2 -Maximum).Maximum
      Write-Host ("  ok   {0,-42} baja hasta y={1}" -f $etiqueta, $hasta) -ForegroundColor Green
    }
  }
}

Write-Host ""
if ($script:problemas) { Write-Host "$script:problemas problema(s) de reparto" -ForegroundColor Red; exit 1 }
Write-Host "El reparto de las seis pantallas está limpio" -ForegroundColor Green
exit 0
