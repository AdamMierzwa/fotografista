; ============================================================
;   Fotografista - instalator EXE (Inno Setup 6), wersja 64-bit
;   Zrodlo: Win64\Release (Fotografista.exe + sk4d.dll)
;   Wynik:  dist\Fotografista_<VER>_Win64_Setup.exe
;   UWAGA: kompilowac TYLKO po przebudowie Release Win64 w IDE.
;   AppId inny niz w wersji 32-bit - obie instalacje sa niezalezne.
; ============================================================

#define AppName    "Fotografista"
#define AppVersion "1.5.1"
#define Root       AddBackslash(SourcePath) + ".."
#define Release    Root + "\Win64\Release"

[Setup]
AppId={{3F1C2B7A-8D64-4E2F-9A51-7C0E6B9D4A21}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion} (64-bit)
AppPublisher=Adam Bogumił Mierzwa
VersionInfoVersion={#AppVersion}
DefaultDirName={autopf}\{#AppName}
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
PrivilegesRequiredOverridesAllowed=dialog
OutputDir={#Root}\dist
OutputBaseFilename={#AppName}_{#AppVersion}_Win64_Setup
SetupIconFile={#Root}\fotografista.ico
UninstallDisplayIcon={app}\Fotografista.exe
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "polish";  MessagesFile: "compiler:Languages\Polish.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "czech";   MessagesFile: "compiler:Languages\Czech.isl"
Name: "french";  MessagesFile: "compiler:Languages\French.isl"
Name: "german";  MessagesFile: "compiler:Languages\German.isl"
Name: "italian"; MessagesFile: "compiler:Languages\Italian.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"
Name: "portuguese"; MessagesFile: "compiler:Languages\Portuguese.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#Release}\Fotografista.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#Release}\sk4d.dll";         DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\Fotografista.exe"
Name: "{autodesktop}\{#AppName}";  Filename: "{app}\Fotografista.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\Fotografista.exe"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent
