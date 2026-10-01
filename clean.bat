@echo off
echo Czyszczenie smietnika z projektu Delphi...

del /s /q *.dcu
del /s /q *.rsm
del /s /q *.map
del /s /q *.local
del /s /q *.identcache
del /s /q *.otares
del /s /q *.~*
del /s /q *.stat
del /s /q *.dsk
del /s /q *.cfg
del /s /q *.otl
del /s /q *.tvsconfig

for /d /r %%i in (__history) do @if exist "%%i" rd /s /q "%%i"

echo Gotowe! Wszystkie pliki tymczasowe zostaly usuniete.
pause