@echo off
setlocal

rem ============================================================
rem   Fotografista - budowa paczki ZIP dla betatesterow
rem   1) kopiuje swiezy build z Win64\Release do katalogu staging
rem   2) pakuje do dist\Fotografista_Win64.zip
rem   UWAGA: uruchamiac TYLKO po przebudowie Release w IDE.
rem ============================================================

set ROOT=C:\Fotografista\Delphi
set RELEASE=%ROOT%\Win64\Release
set DIST=%ROOT%\dist
set STAGE=%DIST%\Fotografista_Win64
set ZIP=%DIST%\Fotografista_Win64.zip

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

if exist "%STAGE%" rmdir /s /q "%STAGE%"
if exist "%ZIP%" del /q "%ZIP%"
mkdir "%STAGE%"

echo === KOPIOWANIE SWIEZEGO BUILD-U ===
copy /y "%RELEASE%\Fotografista.exe" "%STAGE%" >nul || goto :fail
copy /y "%RELEASE%\sk4d.dll" "%STAGE%" >nul || goto :fail

echo === PAKOWANIE ZIP ===
tar -a -c -f "%ZIP%" -C "%DIST%" Fotografista_Win64
if errorlevel 1 goto :fail

echo.
echo GOTOWE: %ZIP%
pause
exit /b 0

:fail
echo.
echo [BLAD] Budowa paczki ZIP nie powiodla sie.
pause
exit /b 1