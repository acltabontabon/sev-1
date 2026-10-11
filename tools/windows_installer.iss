; Per-user install: no administrator access or signing credentials needed.
#ifndef AppVersion
  #error AppVersion is required
#endif
#ifndef SourceDir
  #error SourceDir is required
#endif
#ifndef OutputDir
  #error OutputDir is required
#endif
[Setup]
AppId={{58C32F8D-5396-4A37-BFEF-5339EBB49300}
AppName=SEV-1 Friday Deployment
AppVersion={#AppVersion}
AppPublisher=MayhemProd
DefaultDirName={localappdata}\Programs\SEV-1
DefaultGroupName=SEV-1
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
OutputDir={#OutputDir}
OutputBaseFilename=SEV-1-{#AppVersion}-windows-x86_64-setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
UninstallDisplayIcon={app}\SEV-1.exe

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; Flags: unchecked

[Icons]
Name: "{group}\SEV-1"; Filename: "{app}\SEV-1.exe"
Name: "{autodesktop}\SEV-1"; Filename: "{app}\SEV-1.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\SEV-1.exe"; Description: "Play SEV-1"; Flags: nowait postinstall skipifsilent
