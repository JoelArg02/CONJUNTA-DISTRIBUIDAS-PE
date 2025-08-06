@echo off
REM Script para Windows que ejecuta init-system.sh con argumentos
REM Uso: init-system.bat --dashboard

echo Ejecutando init-system.sh con WSL/Git Bash...

REM Verificar si WSL está disponible
where wsl >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo Usando WSL...
    wsl bash ./init-system.sh %*
    goto :end
)

REM Verificar si Git Bash está disponible
where bash >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo Usando Git Bash...
    bash ./init-system.sh %*
    goto :end
)

echo ERROR: No se encontro bash ni WSL
echo Por favor instala Git Bash o WSL para ejecutar este script
echo O ejecuta manualmente: bash ./init-system.sh %*
pause

:end
