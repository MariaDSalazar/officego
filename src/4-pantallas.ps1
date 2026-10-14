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
