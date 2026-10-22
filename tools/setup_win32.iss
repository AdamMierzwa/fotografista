; ============================================================
;   Fotografista - instalator EXE (Inno Setup 6), wersja 32-bit
;   Zrodlo: Win32\Release (Fotografista.exe + sk4d.dll)
;   Wynik:  dist\Fotografista_<VER>_Win32_Setup.exe
;   UWAGA: kompilowac TYLKO po przebudowie Release Win32 w IDE.
; ============================================================

#define AppName    "Fotografista"
#define AppVersion "1.3.0"
#define Root       AddBackslash(SourcePath) + ".."
#define Release    Root + "\Win32\Release"

[Setup]
AppId={{66B7A38E-0CDB-4F05-921B-C1BF7F0B6E5C}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion} (32-bit)
AppPublisher=Adam Bogumił Mierzwa
VersionInfoVersion={#AppVersion}
DefaultDirName={autopf32}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
PrivilegesRequiredOverridesAllowed=dialog
OutputDir={#Root}\dist
OutputBaseFilename={#AppName}_{#AppVersion}_Win32_Setup
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
