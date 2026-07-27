@echo off
rem ====================================================================
rem  OfficeGo · genera OfficeGo.exe
rem
rem  No hace falta instalar nada: Windows ya trae el compilador de C#
rem  en C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe
rem
rem  El .exe resultante lleva OfficeGo.ps1 dentro y lo ejecuta al abrirse.
rem  Como lo compila usted en su propio equipo, SmartScreen no lo marca
rem  igual que a un ejecutable descargado de internet.
rem ====================================================================

setlocal
chcp 65001 >nul
cd /d "%~dp0"

set "CSC=%WINDIR%\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if not exist "%CSC%" set "CSC=%WINDIR%\Microsoft.NET\Framework\v4.0.30319\csc.exe"
if not exist "%CSC%" (
  echo  [!] No se encontro el compilador de C# de .NET Framework.
  echo      Deberia estar en %WINDIR%\Microsoft.NET\Framework64\v4.0.30319\
  echo      Instale .NET Framework 4.8 y vuelva a intentarlo.
  pause & exit /b 1
)

if not exist "OfficeGo.ps1" (
  echo  [!] Falta OfficeGo.ps1 en esta carpeta.
  pause & exit /b 1
)

echo  Compilando OfficeGo.exe...
echo.

rem El .ps1 se incrusta como recurso dentro del ejecutable
"%CSC%" /nologo /target:winexe /out:OfficeGo.exe ^
  /win32icon:assets\officego.ico ^
  /resource:OfficeGo.ps1,script ^
  /reference:System.dll ^
  src\Lanzador.cs

if errorlevel 1 (
  echo.
  echo  [!] La compilacion fallo.
  pause & exit /b 1
)

echo.
echo  Listo: OfficeGo.exe
echo  Ya puede abrirlo con doble clic.
echo.
pause
