# =====================================================================
#  OfficeGo · parámetros
#
#  Con `irm URL | iex` no se pueden pasar parámetros: iex recibe el
#  texto ya montado. Por eso el arranque recomendado es
#
#     & ([scriptblock]::Create((irm URL))) -Instalar 2021 -Silencioso
#
#  que crea un bloque de script de verdad y sí los acepta. Sin ningún
#  parámetro se abre la ventana, que es lo habitual.
# =====================================================================
param(
  # Qué instalar, sin tocar la ventana
  [ValidateSet('365','2024','2021','2019','2016','2013')]
  [string]$Instalar,

  [ValidateSet('ProPlus','Standard','Professional','HomeBusiness','HomeStudent','Personal','Business')]
  [string]$Edicion = 'ProPlus',

  # Word,Excel,PowerPoint · lo que no se nombre no se instala
  [string[]]$Apps = @('Word','Excel','PowerPoint'),

  [string]$Idioma = 'es-es',

  [ValidateSet('64','32')]
  [string]$Bits,

  # VisioPro, VisioStd, ProjectPro, ProjectStd
  [string[]]$Complementos = @(),

  # Activar al terminar (o por su cuenta, sin instalar nada)
  [switch]$Activar,

  # Sin ventana: para desplegar en varios equipos o desde un script
  [switch]$Silencioso,

  # Quitar Office del equipo
  [switch]$Desinstalar,

  [switch]$Ayuda
)

$script:VERSION = '1.3'
$script:URL_SCRIPT = 'https://raw.githubusercontent.com/MariaDSalazar/officego/main/OfficeGo.ps1'

# Se guardan aquí porque hacen falta para volver a lanzarse como
# administrador, y dentro de una función ya no se ven:
#   INVOCADO · qué parámetros dio el usuario, para repetírselos
#   FUENTE   · la ruta del .ps1, o su texto entero si vino de internet
$script:INVOCADO = $PSBoundParameters
$script:FUENTE   = $MyInvocation.MyCommand.Definition

# Si viene con órdenes, no hay ventana que enseñar. Y entonces tampoco se
# monta: así el modo desatendido no depende de Windows Forms ni carga con
# el segundo largo que cuesta construirla.
$script:SIN_INTERFAZ = [bool]($Ayuda -or $Silencioso -or $Instalar -or $Desinstalar -or $Activar)
