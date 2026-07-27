# Guía rápida de OfficeGo

Para quien solo quiere instalar Office y seguir con su vida. Si busca el paso a paso
completo, con las dos versiones y todos los errores, está en el
**[tutorial](TUTORIAL.md)**.

---

## Instalar Office en cinco minutos

1. Pulse la tecla <kbd>Windows</kbd> y escriba `PowerShell`.
2. En el panel de la derecha, elija **Ejecutar como administrador**.
   Es importante que sea esa opción y no «Abrir»: sin permisos el instalador se detiene.
3. Cuando Windows pregunte si permite cambios, pulse **Sí**.
4. Pegue esta línea con **clic derecho** dentro de la ventana azul y pulse <kbd>Enter</kbd>:

   ```powershell
   irm https://raw.githubusercontent.com/MariaDSalazar/officego/main/OfficeGo.ps1 | iex
   ```

5. Se abre la ventana de OfficeGo. En la pantalla de inicio ya aparece qué versión le
   conviene a su equipo: pulse **Instalar esto** y confirme.
6. Espere. Tarda entre 10 y 30 minutos según la conexión. **No cierre la ventana.**

Cuando termine, OfficeGo pregunta si quiere activarlo.

---

## Qué versión elegir

Si la recomendación no le convence, esta es la regla corta:

| Su situación | Elija |
|---|---|
| Windows 11, o Windows 10 al día | **Office 2024** |
| Windows 10 normal | **Office 2021** |
| Windows 10 de los primeros | **Office 2019** |
| Windows 7 u 8, o menos de 4 GB de RAM | **Office 2016** |
| Un equipo muy viejo | **Office 2013** |

Y sobre la edición:

| Edición | Trae |
|---|---|
| **Professional Plus** | Todo: Word, Excel, PowerPoint, Outlook, Access, Publisher, OneNote |
| **Standard** | Lo mismo sin Access |
| **Home & Business** | Word, Excel, PowerPoint, Outlook, OneNote |
| **Personal** | Word, Excel, PowerPoint, OneNote |

> Con Office **2016** y **2013** no se pueden elegir aplicaciones sueltas: se instala la
> suite entera. No es cosa del programa, es que Microsoft no lo permite por esa vía.

---

## Activar

En la pantalla **Activar** hay dos caminos:

- **Clave de producto.** Si tiene una clave de 25 caracteres, es lo correcto y lo legal.
- **MAS.** Herramienta externa que OfficeGo ejecuta sin abrir su menú.

Sobre MAS conviene saber dos cosas. La primera: **Windows Defender lo detecta siempre**,
por diseño, aunque no sea dañino; lo advierte la propia web de massgrave.dev. Habrá que
pausar la protección en tiempo real un momento y **volver a encenderla al terminar**.
La segunda: activar productos sin licencia va contra los términos de Microsoft.

---

## Si algo sale mal

**«No se puede cargar el archivo… la ejecución de scripts está deshabilitada»**

Windows bloquea los scripts por seguridad. Escriba esto y pulse <kbd>Enter</kbd>:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
```

Solo afecta a esa ventana; al cerrarla todo vuelve a su sitio. Después pegue de nuevo
el comando de OfficeGo.

**«'irm' no se reconoce como un comando…»**

Pegó el comando en el *Símbolo del sistema* (CMD), que es otra ventana parecida.
Tiene que ser **PowerShell**: fondo azul oscuro y el texto empieza por `PS C:\...`.

**«FALTAN PERMISOS DE ADMINISTRADOR»**

Abrió PowerShell con «Abrir» en vez de «Ejecutar como administrador». Ciérrelo y repita
desde el paso 2.

**La ventana parece congelada**

Mire el reloj de la parte de abajo. Si el número avanza, está trabajando. Descomprimir
Office tarda varios minutos sin que la barra se mueva.

**El antivirus borró algo**

Solo pasa con MAS, nunca con el instalador. Está explicado en la pantalla Activar.

---

## Preguntas que salen siempre

**¿Esto de dónde baja Office?**
De `officecdn.microsoft.com` y `c2rsetup.officeapps.live.com`, los servidores de
Microsoft. OfficeGo no aloja ni modifica ningún archivo.

**¿Borra mis documentos?**
No. Ni instalando ni desinstalando. La opción de desinstalar quita los programas y deja
los archivos donde estén.

**¿Necesito internet?**
Para descargar Office, sí. Después Office funciona sin conexión con normalidad.

**¿Puedo instalarlo en varios equipos sin bajarlo cada vez?**
Sí. En **Herramientas → Crear instalador sin conexión** se descarga todo a una carpeta
que puede copiar a un USB.

**¿Y sin tener que ir eligiendo en cada equipo?**
Sí, dándole las opciones por escrito. Deja todos los equipos igual sin tocar nada:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/MariaDSalazar/officego/main/OfficeGo.ps1))) -Instalar 2021 -Apps Word,Excel -Silencioso -Activar
```

La lista completa de opciones está en el [tutorial](TUTORIAL.md#8--sin-tocar-la-ventana-opciones-por-escrito).

**¿Deja rastro en mi equipo?**
El programa es portable: no se instala, no toca el registro. Los archivos temporales
quedan en `%TEMP%\OfficeGo` y se pueden borrar.
