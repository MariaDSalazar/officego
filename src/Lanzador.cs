// =====================================================================
//  OfficeGo · lanzador del .exe
//
//  Lo único que hace: sacar OfficeGo.ps1 de dentro del propio ejecutable,
//  dejarlo en la carpeta temporal y ejecutarlo con permisos elevados.
//  Lo que le pasen por la línea de órdenes se lo reenvía al script:
//    OfficeGo.exe -Instalar 2021 -Apps Word,Excel
//
//  Se compila con el csc.exe que Windows ya trae. Ver compilar-exe.bat
// =====================================================================
using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Security.Principal;

static class Lanzador
{
    [STAThread]
    static int Main(string[] args)
    {
        try
        {
            // Un nombre por proceso: si se abren dos OfficeGo a la vez, el
            // segundo pillaría el archivo del primero a medio escribir.
            string destino = Path.Combine(Path.GetTempPath(),
                "OfficeGo-" + Process.GetCurrentProcess().Id + ".ps1");

            // y de paso se barren los de veces anteriores; el que esté en
            // uso se niega a borrarse y no pasa nada
            try
            {
                foreach (string viejo in Directory.GetFiles(Path.GetTempPath(), "OfficeGo-*.ps1"))
                    try { File.Delete(viejo); } catch { }
            }
            catch { }

            // el .ps1 viaja dentro del .exe como recurso incrustado
            using (Stream dentro = Assembly.GetExecutingAssembly()
                                           .GetManifestResourceStream("script"))
            {
                if (dentro == null)
                {
                    Error("El ejecutable no lleva el script dentro. Vuelva a compilarlo.");
                    return 1;
                }
                using (FileStream fuera = File.Create(destino))
                {
                    // BOM UTF-8 por delante. El OfficeGo.ps1 del repositorio
                    // NO lo lleva, porque llega por irm y ahí el BOM rompe el
                    // param(). Aquí es al revés: este archivo solo se ejecuta
                    // con -File, y con BOM PowerShell 5.1 lee bien los acentos
                    // a la primera, sin tener que releerse a sí mismo.
                    fuera.Write(new byte[] { 0xEF, 0xBB, 0xBF }, 0, 3);
                    dentro.CopyTo(fuera);
                }
            }

            string extra = "";
            foreach (string a in args)
                extra += " " + (a.IndexOf(' ') >= 0 ? "\"" + a + "\"" : a);

            // Sin opciones sale la ventana y la consola sobra. Con opciones
            // el resultado se escribe en la consola, así que además de dejarla
            // a la vista hay que impedir que se cierre al terminar: si no, el
            // mensaje pasa en un parpadeo y no da tiempo a leerlo.
            string modo = args.Length == 0 ? "-WindowStyle Hidden " : "-NoExit ";

            var psi = new ProcessStartInfo
            {
                FileName = "powershell.exe",
                Arguments = "-NoProfile -ExecutionPolicy Bypass " + modo + "-File \""
                            + destino + "\"" + extra,
                UseShellExecute = true
            };

            // sin permisos de administrador no se puede instalar nada
            if (!EsAdministrador()) psi.Verb = "runas";

            Process.Start(psi);
            return 0;
        }
        catch (System.ComponentModel.Win32Exception)
        {
            // el usuario dijo que no en el aviso de permisos
            return 1;
        }
        catch (Exception ex)
        {
            Error(ex.Message);
            return 1;
        }
    }

    static bool EsAdministrador()
    {
        using (var id = WindowsIdentity.GetCurrent())
            return new WindowsPrincipal(id).IsInRole(WindowsBuiltInRole.Administrator);
    }

    static void Error(string mensaje)
    {
        Process.Start(new ProcessStartInfo
        {
            FileName = "powershell.exe",
            Arguments = "-NoProfile -Command \"Add-Type -AssemblyName System.Windows.Forms;"
                      + "[void][Windows.Forms.MessageBox]::Show('" + mensaje.Replace("'", "''")
                      + "','OfficeGo','OK','Error')\"",
            UseShellExecute = true,
            WindowStyle = ProcessWindowStyle.Hidden
        });
    }
}
