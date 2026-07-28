# =====================================================================
#  OfficeGo · pantalla de bienvenida
#  Lo primero que se ve no es una lista de opciones, sino qué le
#  conviene a este equipo concreto.
# =====================================================================

function Pantalla-Inicio {
  if (-not $script:equipo) { $script:equipo = Get-EquipoInfo }
  $eq  = $script:equipo
  $rec = Get-Recomendacion $eq

  # ── cabecera
  $hero = New-Caja 18 14 802 92 $C.Azul $C.Azul
  $hero.Controls.Add((New-Icono 'O' '#3B7DD8' 22 22 48 17))
  $hero.Controls.Add((New-Lbl 'Instale Office en tres pasos' 86 24 15 '#FFFFFF' $true))
  $hero.Controls.Add((New-Lbl 'Descarga directa de los servidores de Microsoft · sin páginas de terceros' 86 54 9 '#D6E4F7'))
  Set-Redondeado $hero 11
  $cont.Controls.Add($hero)

  # ── la recomendación
  $cont.Controls.Add((Titulo 'Lo que le conviene a este equipo' 18 122))
  $prod = Get-Producto $rec.Clave
  $borde = if ($rec.Clave -in @('2016','2013')) { '#E8A33D' } else { $C.Azul }

  $r = New-Caja 18 144 802 88 $C.Panel $borde
  $r.Controls.Add((New-Icono $prod.Sigla $prod.Color 18 20 48 15))
  # la primera edición del producto, que es justo la que deja marcada el
  # botón de abajo. Estaba fija a ProPlus y podía no ser la misma.
  $edRec = @($prod.Ediciones.Keys)[0]
  $r.Controls.Add((New-Lbl "$($prod.Nombre) · $($script:EDICIONES[$edRec].Nombre)" 82 20 12.5 $C.Texto $true))
  $lm = New-Lbl $rec.Motivo 82 46 8.5 $C.Gris
  $lm.AutoSize = $false; $lm.Size = New-Object Drawing.Size(540, 32)
  $r.Controls.Add($lm)

  $b = New-Boton 'Instalar esto' 640 26 140 38 $true
  # la versión recomendada viaja en el Tag y no capturada en un closure:
  # dentro de GetNewClosure() $script:sel apunta a otro sitio y el botón
  # se quedaba sin hacer nada
  $b.Tag = $rec.Clave
  $b.Add_Click({
    $script:sel.Producto = $this.Tag
    $script:sel.Edicion  = @((Get-Producto $this.Tag).Ediciones.Keys)[0]
    Ajustar-Seleccion
    Mostrar-Pantalla 'Instalar'
  })
  $r.Controls.Add($b)
  Set-Redondeado $r 11
  $cont.Controls.Add($r)

  # ── los tres pasos
  $cont.Controls.Add((Titulo 'Cómo funciona' 18 246))
  $pasos = @(
    @('1', 'Elija su versión',      'Seis versiones desde 2013 hasta Microsoft 365, con sus ediciones'),
    @('2', 'Marque lo que quiere',  'Solo Word y Excel, o la suite entera. Se descarga únicamente eso'),
    @('3', 'Active al terminar',    'Con su clave de producto, o con MAS si no la tiene')
  )
  $x = 18
  foreach ($p in $pasos) {
    $c = New-Caja $x 268 260 104
    $n = New-Icono $p[0] $C.AzulSuave 114 14 32 12
    $n.Controls[0].ForeColor = Hex $C.Azul
    $c.Controls.Add($n)
    $lt = New-Lbl $p[1] 0 52 10 $C.Texto $true
    $lt.AutoSize = $false; $lt.Size = New-Object Drawing.Size(260, 18); $lt.TextAlign = 'MiddleCenter'
    $c.Controls.Add($lt)
    $ld = New-Lbl $p[2] 14 72 8 $C.GrisClaro
    $ld.AutoSize = $false; $ld.Size = New-Object Drawing.Size(232, 28); $ld.TextAlign = 'TopCenter'
    $c.Controls.Add($ld)
    Set-Redondeado $c 10
    $cont.Controls.Add($c)
    $x += 271
  }

  # ── avisos que salgan de la revisión
  $y = 386
  if (-not $rec.Apto) {
    $cont.Controls.Add((New-Aviso 'Este equipo tiene un Windows anterior al 10. Office 2019, 2021 y 2024 no se pueden instalar aquí.' 18 $y 802 'error'))
    $y += 52
  }
  foreach ($a in $rec.Avisos) {
    $av = New-Aviso $a.Texto 18 $y 802 $a.Tipo
    $av.Height = 52
    $cont.Controls.Add($av)
    $y += 58
  }
  # Sin permisos no se puede instalar, así que eso va antes que nada. El
  # resumen verde daba los permisos por hechos y decía «listo» a alguien
  # que no iba a poder instalar nada.
  if (-not $eq.Admin) {
    $cont.Controls.Add((New-Aviso 'Faltan permisos de administrador: se pueden mirar las pantallas, pero no instalar ni activar. Cierre y vuelva a abrir con clic derecho > Ejecutar como administrador.' 18 $y 802 'error'))
    $y += 58
  }
  elseif (-not $rec.Avisos -and $rec.Apto) {
    $sis = $eq.Discos | Where-Object { $_.Sistema } | Select-Object -First 1
    $cont.Controls.Add((New-Aviso "Equipo listo. $($eq.SO) · $($eq.RamGB) GB de RAM · $($sis.LibreGB) GB libres · permisos de administrador." 18 $y 802 'ok'))
  }

  Set-PieBotones @(
    @{ Texto = 'Empezar';  Primario = $true;  Accion = { Mostrar-Pantalla 'Instalar' } },
    @{ Texto = 'Ver el equipo'; Primario = $false; Accion = { Mostrar-Pantalla 'Equipo' } }
  )
}
