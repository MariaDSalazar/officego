@echo off
rem ====================================================================
rem  OfficeGo · lanzador
rem  Doble clic aqui. Pide permisos de administrador y abre la ventana.
rem  Este archivo y OfficeGo.ps1 van SIEMPRE juntos, en la misma carpeta.
rem ====================================================================

chcp 65001 >nul
title OfficeGo

net session >nul 2>&1
if errorlevel 1 (
  powershell -NoProfile -Command "Start-Process '%~f0' -Verb RunAs"
  exit /b
)

if not exist "%~dp0OfficeGo.ps1" (
  echo.
  echo  [!] Falta OfficeGo.ps1 en esta misma carpeta.
  echo      Los dos archivos van juntos.
  echo.
  pause
  exit /b 1
)

rem Unblock-File quita la marca de "bajado de internet" que si no
rem hace que PowerShell se niegue a abrirlo.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Unblock-File -LiteralPath '%~dp0OfficeGo.ps1'; & '%~dp0OfficeGo.ps1'"

if errorlevel 1 pause
