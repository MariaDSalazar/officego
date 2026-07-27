// =====================================================================
//  OfficeGo · lanzador del .exe
//
//  Lo único que hace: sacar OfficeGo.ps1 de dentro del propio ejecutable,
//  dejarlo en la carpeta temporal y ejecutarlo con permisos elevados.
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
    static int Main()
    {
        try
        {
            string destino = Path.Combine(Path.GetTempPath(), "OfficeGo.ps1");

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
                    dentro.CopyTo(fuera);
            }

            var psi = new ProcessStartInfo
            {
                FileName = "powershell.exe",
                Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File \""
                            + destino + "\"",
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
