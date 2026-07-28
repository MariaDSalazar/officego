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
#
#  ESTE ARCHIVO NO LLEVA BOM, y es a propósito. Con BOM, el carácter
#  invisible del principio se cuela en el texto que devuelve irm, param
#  deja de ser lo primero del bloque y PowerShell lo toma por una llamada
#  a un comando: "The assignment expression is not valid". Como sin BOM
#  PowerShell 5.1 lee el archivo en ANSI y parte los acentos, más abajo
#  hay una relectura que lo arregla.
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

# ── acentos
#
# PowerShell 5.1 lee en ANSI todo archivo que no lleve BOM, y entonces
# cada acento llega partido en dos caracteres: 'á' mide 2 en vez de 1.
# Cuando pasa, el archivo se relee diciéndole que es UTF-8 y se ejecuta
# esa versión. No hay vuelta atrás posible: el texto releído ya trae los
# acentos enteros, así que la condición no se cumple una segunda vez.
if ($PSCommandPath -and 'á'.Length -ne 1 -and (Test-Path $PSCommandPath)) {
  $bien = [IO.File]::ReadAllText($PSCommandPath, [Text.UTF8Encoding]::new($false))
  & ([scriptblock]::Create($bien)) @PSBoundParameters
  return
}

$script:VERSION = '1.4'
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
