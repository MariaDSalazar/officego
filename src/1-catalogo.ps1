# =====================================================================
#  OfficeGo · catálogo de productos
#
#  Dos vías, y no son intercambiables:
#    ODT  -> setup.exe /configure con un configuration.xml. Productos de
#            volumen y suscripción. Permite excluir aplicaciones.
#    C2R  -> c2rsetup.officeapps.live.com. Productos retail (2016 y 2013).
#            NO admite excluir aplicaciones: instala la suite entera.
# =====================================================================

# Aplicaciones que el ODT sabe excluir (ExcludeApp ID)
$script:APLICACIONES = [ordered]@{
  Word       = @{ Nombre='Word';       Color='#2B579A'; Sigla='W'  }
  Excel      = @{ Nombre='Excel';      Color='#217346'; Sigla='X'  }
  PowerPoint = @{ Nombre='PowerPoint'; Color='#D24726'; Sigla='P'  }
  Outlook    = @{ Nombre='Outlook';    Color='#0F6CBD'; Sigla='O'  }
  Access     = @{ Nombre='Access';     Color='#A4373A'; Sigla='A'  }
  Publisher  = @{ Nombre='Publisher';  Color='#077568'; Sigla='Pb' }
  OneNote    = @{ Nombre='OneNote';    Color='#7719AA'; Sigla='N'  }
}

# Qué trae realmente cada edición. De aquí sale que al elegir Standard
# se apague Access: esa edición no lo incluye.
$script:EDICIONES = @{
  ProPlus       = @{ Nombre='Professional Plus'; Apps=@('Word','Excel','PowerPoint','Outlook','Access','Publisher','OneNote') }
  Standard      = @{ Nombre='Standard';          Apps=@('Word','Excel','PowerPoint','Outlook','Publisher','OneNote') }
  Professional  = @{ Nombre='Professional';      Apps=@('Word','Excel','PowerPoint','Outlook','Access','Publisher','OneNote') }
  HomeBusiness  = @{ Nombre='Home & Business';   Apps=@('Word','Excel','PowerPoint','Outlook','OneNote') }
  HomeStudent   = @{ Nombre='Home & Student';    Apps=@('Word','Excel','PowerPoint','OneNote') }
  Personal      = @{ Nombre='Personal';          Apps=@('Word','Excel','PowerPoint','OneNote') }
  Business      = @{ Nombre='Business';          Apps=@('Word','Excel','PowerPoint','Outlook','OneNote') }
}

# Catálogo. Id = Product ID que entiende Microsoft.
$script:PRODUCTOS = @(
  @{ Clave='365';  Nombre='Microsoft 365';   Sub='siempre al día'; Sigla='365'; Color='#D83B01'
     Tipo='suscripción'; Via='ODT'; Canal='Current'; Peso=1.9
     Ediciones=[ordered]@{ ProPlus='O365ProPlusRetail'; Business='O365BusinessRetail' } }

  @{ Clave='2024'; Nombre='Office 2024';     Sub='LTSC';           Sigla='24';  Color='#B7472A'
     Tipo='volumen'; Via='ODT'; Canal='PerpetualVL2024'; Peso=2.1
     Ediciones=[ordered]@{ ProPlus='ProPlus2024Volume'; Standard='Standard2024Volume' } }

  @{ Clave='2021'; Nombre='Office 2021';     Sub='LTSC · recomendada'; Sigla='21'; Color='#C43E1C'
     Tipo='volumen'; Via='ODT'; Canal='PerpetualVL2021'; Peso=1.9; Recomendado=$true
     Ediciones=[ordered]@{ ProPlus='ProPlus2021Volume'; Standard='Standard2021Volume' } }

  @{ Clave='2019'; Nombre='Office 2019';     Sub='perpetua';       Sigla='19';  Color='#D24726'
     Tipo='volumen'; Via='ODT'; Canal='PerpetualVL2019'; Peso=1.8
     Ediciones=[ordered]@{ ProPlus='ProPlus2019Volume'; Standard='Standard2019Volume' } }

  # 2016 y 2013 van por c2rsetup: la suite entera, sin poder excluir nada.
  @{ Clave='2016'; Nombre='Office 2016';     Sub='clásica';        Sigla='16';  Color='#E8590C'
     Tipo='retail'; Via='C2R'; Version='O16GA'; Peso=2.5
     Ediciones=[ordered]@{ ProPlus='ProPlusRetail'; Standard='StandardRetail'
                           Professional='ProfessionalRetail'; HomeBusiness='HomeBusinessRetail'
                           HomeStudent='HomeStudentRetail' } }

  @{ Clave='2013'; Nombre='Office 2013';     Sub='antigua';        Sigla='13';  Color='#F08C00'
     Tipo='retail'; Via='C2R'; Version='O15GA'; Peso=1.5
     Ediciones=[ordered]@{ ProPlus='ProPlusRetail'; Standard='StandardRetail'
                           Professional='ProfessionalRetail'; HomeBusiness='HomeBusinessRetail' } }
)

# Complementos: productos aparte que se añaden al mismo configuration.xml
$script:COMPLEMENTOS = @(
  @{ Clave='VisioPro';   Nombre='Visio Professional';   Sigla='V';  Color='#3955A3'
     Ids=@{ '2024'='VisioPro2024Volume'; '2021'='VisioPro2021Volume'; '2019'='VisioPro2019Volume'
            '365'='VisioProRetail' } }
  @{ Clave='VisioStd';   Nombre='Visio Standard';       Sigla='Vs'; Color='#5B76C4'
     Ids=@{ '2024'='VisioStd2024Volume'; '2021'='VisioStd2021Volume'; '2019'='VisioStd2019Volume' } }
  @{ Clave='ProjectPro'; Nombre='Project Professional'; Sigla='Pj'; Color='#31752F'
     Ids=@{ '2024'='ProjectPro2024Volume'; '2021'='ProjectPro2021Volume'; '2019'='ProjectPro2019Volume'
            '365'='ProjectProRetail' } }
  @{ Clave='ProjectStd'; Nombre='Project Standard';     Sigla='Ps'; Color='#5B9E59'
     Ids=@{ '2024'='ProjectStd2024Volume'; '2021'='ProjectStd2021Volume'; '2019'='ProjectStd2019Volume' } }
)

$script:IDIOMAS = [ordered]@{
  'es-es' = 'Español (España)';    'es-mx' = 'Español (México)'
  'en-us' = 'English (US)';        'pt-br' = 'Português (Brasil)'
  'fr-fr' = 'Français';            'de-de' = 'Deutsch';  'it-it' = 'Italiano'
}

function Get-Producto($clave) { $script:PRODUCTOS | Where-Object { $_.Clave -eq $clave } | Select-Object -First 1 }

function Get-AppsDeEdicion($producto, $edicion) {
  # Qué aplicaciones se pueden marcar. Por C2R no se puede elegir: van todas.
  if ($producto.Via -eq 'C2R') { return @() }
  $script:EDICIONES[$edicion].Apps
}
