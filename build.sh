#!/usr/bin/env bash
# Junta src/*.ps1 en un único OfficeGo.ps1 portable y valida la sintaxis.
set -e
cd "$(dirname "$0")"

SALIDA=OfficeGo.ps1
PWSH=${PWSH:-/tmp/pwsh/pwsh}

{
  cat <<'CAB'
# =====================================================================
#
#   ██████  ███████ ███████ ██  ██████ ███████  ██████   ██████
#  ██    ██ ██      ██      ██ ██      ██      ██       ██    ██
#  ██    ██ █████   █████   ██ ██      █████   ██   ███ ██    ██
#  ██    ██ ██      ██      ██ ██      ██      ██    ██ ██    ██
#   ██████  ██      ██      ██  ██████ ███████  ██████   ██████
#
#  Instalador y activador de Microsoft Office para Windows 10 y 11
#  https://github.com/MariaDSalazar/officego
#
#  Diego Fernando Loján Tenesaca  · desarrollo e interfaz
#  María del Carmen Salazar Torres · script base y documentación
#
#  Licencia MIT · sin telemetría · sin publicidad
#
#  USO
#    irm https://raw.githubusercontent.com/MariaDSalazar/officego/main/OfficeGo.ps1 | iex
#    & ([scriptblock]::Create((irm ...OfficeGo.ps1))) -Instalar 2021 -Apps Word,Excel
#    .\OfficeGo.ps1 -Ayuda
#
#  Descarga Office de los servidores oficiales de Microsoft:
#    officecdn.microsoft.com   ·  c2rsetup.officeapps.live.com
#
#  ESTE ARCHIVO SE GENERA: no lo edite a mano.
#  Toque src/*.ps1 y ejecute build.sh
# =====================================================================

CAB
  # 0-parametros va primero de todo: param() tiene que ser lo primero
  # ejecutable del archivo, solo puede llevar comentarios por delante.
  for f in src/0-parametros.ps1 src/1-catalogo.ps1 src/2-motor.ps1 src/2b-recomendacion.ps1 \
           src/3-interfaz.ps1 src/4-pantallas.ps1 src/5-inicio.ps1 \
           src/6-acciones.ps1 src/7-arranque.ps1; do
    echo ""
    echo "# ─────────────────────────────────────────────── $(basename "$f")"

    # La interfaz solo se monta si se va a enseñar. En PowerShell un if no
    # abre un ámbito nuevo, así que $frm y compañía siguen siendo del script
    # igual que si no estuviera.
    case "$f" in
      src/3-interfaz.ps1) echo 'if (-not $script:SIN_INTERFAZ) {' ;;
    esac

    cat "$f"

    case "$f" in
      src/6-acciones.ps1) echo '}   # fin de la interfaz' ;;
    esac
  done
  echo ""
  echo "Start-OfficeGo"
} > "$SALIDA"

# SIN BOM, y es a propósito: con BOM, ese carácter invisible viaja dentro
# del texto que devuelve irm, param() deja de ser lo primero del bloque y
# PowerShell lo parsea como una llamada a un comando. Los acentos en
# PowerShell 5.1 los arregla la relectura de 0-parametros.ps1.
python3 - "$SALIDA" <<'PY'
import sys, pathlib
p = pathlib.Path(sys.argv[1]); d = p.read_bytes()
if d.startswith(b'\xef\xbb\xbf'):
    p.write_bytes(d[3:])
assert not p.read_bytes().startswith(b'\xef\xbb\xbf'), 'quedo BOM'
PY

echo "→ $SALIDA · $(wc -l < "$SALIDA") líneas · $(du -h "$SALIDA" | cut -f1)"

if [ -x "$PWSH" ]; then
  "$PWSH" -NoProfile -c "
    \$err = \$null
    [void][System.Management.Automation.Language.Parser]::ParseFile('$PWD/$SALIDA', [ref]\$null, [ref]\$err)
    if (\$err) {
      Write-Host 'SINTAXIS: ERROR' -ForegroundColor Red
      \$err | Select-Object -First 6 | ForEach-Object { \"  línea \$(\$_.Extent.StartLineNumber): \$(\$_.Message)\" }
      exit 1
    }
    Write-Host 'SINTAXIS: correcta' -ForegroundColor Green
  "
else
  echo "aviso: sin pwsh, no se validó la sintaxis"
fi
