; Inno Setup script for the Windows desktop app. CI passes the version and
; the output name: iscc /DAppVersion=1.11.1.286 /DOutputBase=... absorb.iss
; Paths are relative to this file.

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#ifndef OutputBase
  #define OutputBase "absorb-windows-setup"
#endif
#define SourceDir "..\..\build\windows\x64\runner\Release"
; The Visual C++ runtime the Flutter build links against but does not copy.
; A fresh Windows install can lack it and the app then fails to launch with
; "VCRUNTIME140.dll was not found". CI copies the three DLLs into the Release
; folder before packaging; a local build passes the redistributable folder
; instead, e.g. iscc /DCrtDir="C:\...\VC\Redist\MSVC\<ver>\x64\Microsoft.VC143.CRT"

[Setup]
; Never change the AppId: it's how an update finds the installed copy.
AppId={{3229A98C-AAE4-4106-8B9B-4778E2C857E9}
AppName=Absorb
AppVersion={#AppVersion}
AppVerName=Absorb {#AppVersion}
AppPublisher=Barnabas
AppPublisherURL=https://github.com/pounat/absorb
AppSupportURL=https://github.com/pounat/absorb/issues
; Per-user install into %LOCALAPPDATA%\Programs\Absorb, no admin prompt.
; Per-user only: the reader's WebView2 keeps its data folder next to the
; exe, which Program Files wouldn't let it write.
DefaultDirName={autopf}\Absorb
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
; The Flutter runtime needs Windows 10; without this the installer would
; happily install on 7 or 8 and the app would fail at launch.
MinVersion=10.0
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=..\..\build\installer
OutputBaseFilename={#OutputBase}
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\absorb.exe
UninstallDisplayName=Absorb
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[InstallDelete]
; Flutter's asset bundle changes every build; clear the old one so stale
; assets from a previous version don't linger after an update.
Type: filesandordirs; Name: "{app}\data"

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
#ifdef CrtDir
Source: "{#CrtDir}\msvcp140.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#CrtDir}\vcruntime140.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#CrtDir}\vcruntime140_1.dll"; DestDir: "{app}"; Flags: ignoreversion
#endif

[Icons]
Name: "{autoprograms}\Absorb"; Filename: "{app}\absorb.exe"
Name: "{autodesktop}\Absorb"; Filename: "{app}\absorb.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\absorb.exe"; Description: "{cm:LaunchProgram,Absorb}"; Flags: nowait postinstall skipifsilent
