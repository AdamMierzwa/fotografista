@echo off
setlocal

rem ============================================================
rem   Fotografista - budowa i podpisanie paczki MSIX
rem   1) kopiuje swiezy build z Win64\Release do packaging\x64
rem   2) pakuje makeappx do dist\Fotografista_<VER>_x64.msix
rem   3) podpisuje signtool (certyfikat\fotografista.pfx)
rem   4) weryfikuje podpis przez makeappx unpack (tools\tmp)
rem   UWAGA: uruchamiac TYLKO po przebudowie Release w IDE.
rem ============================================================

set VER=1.1.1.0

set ROOT=C:\Fotografista\Delphi
set RELEASE=%ROOT%\Win64\Release
set STAGE=%ROOT%\packaging\x64
set OUTDIR=%ROOT%\dist
set MSIX=%OUTDIR%\Fotografista_%VER%_x64.msix
set PFX=%ROOT%\certyfikat\fotografista.pfx
set CERTPASS=fotografista
set TMPV=%ROOT%\tools\tmp\msix_verify

rem ---- znajdz najnowszy Windows Kits zawierajacy makeappx.exe ----
set WINKIT=
for /f "delims=" %%i in ('dir /b /ad /o-n "C:\Program Files (x86)\Windows Kits\10\Bin" 2^>nul') do (
    if not defined WINKIT if exist "C:\Program Files (x86)\Windows Kits\10\Bin\%%i\x64\makeappx.exe" (
        set "WINKIT=C:\Program Files (x86)\Windows Kits\10\Bin\%%i\x64"
    )
)
if not defined WINKIT (
    echo [BLAD] Nie znaleziono makeappx.exe w drzewie "C:\Program Files (x86)\Windows Kits\10\Bin".
    pause
    exit /b 1
)
if not exist "%WINKIT%\signtool.exe" (
    echo [BLAD] Nie znaleziono signtool.exe w "%WINKIT%".
    pause
    exit /b 1
)
set MAKEPP="%WINKIT%\makeappx.exe"
set SIGNTOOL="%WINKIT%\signtool.exe"

rem ---- kontrola wejscia ----
if not exist "%RELEASE%\Fotografista.exe" (
    echo [BLAD] Brak %RELEASE%\Fotografista.exe - przebuduj Release w IDE.
    pause
    exit /b 1
)
if not exist "%RELEASE%\sk4d.dll" (
    echo [BLAD] Brak %RELEASE%\sk4d.dll.
    pause
    exit /b 1
)
if not exist "%STAGE%\AppxManifest.xml" (
    echo [BLAD] Brak %STAGE%\AppxManifest.xml.
    pause
    exit /b 1
)
if not exist "%PFX%" (
    echo [BLAD] Brak certyfikatu %PFX%.
    pause
    exit /b 1
)
if not exist "%OUTDIR%" mkdir "%OUTDIR%"

echo === KOPIOWANIE SWIEZEGO BUILD-U (%RELEASE%) ===
copy /y "%RELEASE%\Fotografista.exe" "%STAGE%\Fotografista.exe" >nul || goto :fail
copy /y "%RELEASE%\sk4d.dll" "%STAGE%\sk4d.dll" >nul || goto :fail

echo === PAKOWANIE MSIX ===
if exist "%MSIX%" del /q "%MSIX%"
%MAKEPP% pack /o /d "%STAGE%" /p "%MSIX%" /l
if errorlevel 1 goto :fail

echo === PODPISYWANIE ===
%SIGNTOOL% sign /f "%PFX%" /p "%CERTPASS%" /fd SHA256 /v "%MSIX%"
if errorlevel 1 goto :fail

echo === WERYFIKACJA (unpack sprawdza sygnature) ===
if exist "%TMPV%" rmdir /s /q "%TMPV%"
%MAKEPP% unpack /p "%MSIX%" /d "%TMPV%" /o /l >nul
if errorlevel 1 goto :fail
rmdir /s /q "%TMPV%"

echo.
echo GOTOWE: %MSIX%
pause
exit /b 0

:fail
echo.
echo [BLAD] Budowa MSIX nie powiodla sie - patrz komunikaty powyzej.
pause
exit /b 1