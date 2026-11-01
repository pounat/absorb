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

[Icons]
Name: "{autoprograms}\Absorb"; Filename: "{app}\absorb.exe"
Name: "{autodesktop}\Absorb"; Filename: "{app}\absorb.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\absorb.exe"; Description: "{cm:LaunchProgram,Absorb}"; Flags: nowait postinstall skipifsilent
