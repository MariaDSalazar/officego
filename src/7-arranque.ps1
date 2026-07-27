# =====================================================================
#  OfficeGo · arranque
# =====================================================================

# InputBox sale de aquí; es lo único que se toma de VisualBasic
try { Add-Type -AssemblyName Microsoft.VisualBasic } catch {}

function Actualizar-BarraEstado {
  $barra.Controls.Clear()
  if (-not $script:equipo) { $script:equipo = Get-EquipoInfo }
  $eq = $script:equipo
  $sis = $eq.Discos | Where-Object { $_.Sistema } | Select-Object -First 1

  $items = @(
    @("$($eq.SO) · $(($eq.Build -split '\.')[0])", $(if ($eq.Compatible) { $C.Verde } else { $C.Rojo })),
    @($(if ($eq.Admin) { 'Administrador' } else { 'Sin permisos' }), $(if ($eq.Admin) { $C.Verde } else { $C.Rojo })),
    @("$($sis.LibreGB) GB libres", $(if ($sis.LibreGB -ge 5) { $C.Verde } else { $C.Rojo })),
    @($(if (Test-Internet) { 'Conectado' } else { 'Sin internet' }), $(if (Test-Internet) { $C.Verde } else { $C.Rojo })),
    @($(if ($eq.Defender) { 'Defender activo' } else { 'Defender apagado' }), '#E8A33D')
  )
  $x = 18
  foreach ($it in $items) {
    $barra.Controls.Add((Punto $x $it[1]))
    $l = New-Lbl $it[0] ($x + 14) 7 8 $C.Gris
    $barra.Controls.Add($l)
    $x += 16 + [int]($it[0].Length * 6.1) + 18
  }
  $v = New-Lbl 'OfficeGo 1.2' 920 7 8 $C.GrisClaro
  $barra.Controls.Add($v)
}

function Start-OfficeGo {
  # Sin permisos no se puede instalar nada: se avisa pero se deja mirar.
  if (-not (Test-Administrador)) {
    $r = [Windows.Forms.MessageBox]::Show(
      "OfficeGo no tiene permisos de administrador.`n`nPuede mirar las pantallas, pero no podrá instalar ni activar nada.`n`n¿Quiere reiniciarlo con permisos?",
      'OfficeGo', 'YesNoCancel', 'Warning')
    if ($r -eq 'Yes') {
      $ruta = $PSCommandPath
      if ($ruta) {
        Start-Process 'powershell.exe' -Verb RunAs `
          -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$ruta`""
        return
      }
      # lanzado con irm|iex: no hay archivo que relanzar
      [void][Windows.Forms.MessageBox]::Show(
        "Como se ejecutó desde internet no hay archivo que relanzar.`n`nAbra PowerShell como administrador y pegue el comando otra vez.",
        'OfficeGo', 'OK', 'Information')
      return
    }
    if ($r -eq 'Cancel') { return }
  }

  Actualizar-BarraEstado
  Mostrar-Pantalla 'Inicio'
  [void]$frm.ShowDialog()
}
