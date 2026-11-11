[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}


$gCheck=[string][char]0x2713; $gChev=[string][char]0x203A; $gDot=[string][char]0x00B7; $gWarn=[string][char]0x25B2
$gCross=[string][char]0x2717; $gDiamond=[string][char]0x25C6; $gH=[string][char]0x2500; $gTL=[string][char]0x256D
$gTR=[string][char]0x256E; $gV=[string][char]0x2502; $gBL=[string][char]0x2570; $gBR=[string][char]0x256F
$gPrompt=[string][char]0x276F; $gArrow=[string][char]0x2192; $gDash=[string][char]0x2013; $gBar=[string][char]0x2501
$gTri=[string][char]0x25B8

$script:W = 76
$script:SectionNo = 0
$script:ToolVersion = '1.3.0'

function Write-Line([string]$glyph, [string]$gc, [string]$msg, [string]$mc = 'Gray', [int]$indent = 2) {
    Write-Host ((' ' * $indent) + $glyph + ' ') -NoNewline -ForegroundColor $gc
    Write-Host $msg -ForegroundColor $mc
}
function Write-Ok([string]$m, [int]$i = 2)   { Write-Line $gCheck 'Green'    $m 'White'    $i }
function Write-Info([string]$m, [int]$i = 2) { Write-Line $gChev 'DarkCyan' $m 'Gray'     $i }
function Write-Dim([string]$m, [int]$i = 2)  { Write-Line $gDot 'DarkGray' $m 'DarkGray' $i }
function Write-Warn([string]$m, [int]$i = 2) { Write-Line $gWarn 'Yellow'   $m 'Yellow'   $i }
function Write-Fail([string]$m, [int]$i = 2) { Write-Line $gCross 'Red'      $m 'Red'      $i }
function Write-Note([string]$m, [int]$i = 2) { Write-Line $gDiamond 'Magenta'  $m 'Magenta'  $i }

function Write-Section([string]$title) {
    $script:SectionNo++
    $label = $title.ToUpper()
    $fill = $script:W - 8 - $label.Length
    if ($fill -lt 3) { $fill = 3 }
    Write-Host ""
    Write-Host ("  {0:00}" -f $script:SectionNo) -NoNewline -ForegroundColor Cyan
    Write-Host "  $label " -NoNewline -ForegroundColor White
    Write-Host ($gH * $fill) -ForegroundColor DarkGray
}

function Write-Box([string[]]$lines, [string]$color = 'Cyan', [string[]]$colors = $null) {
    $inner = $script:W - 4
    Write-Host ($gTL + ($gH * ($script:W - 2)) + $gTR) -ForegroundColor $color
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $c = if ($colors -and $i -lt $colors.Count) { $colors[$i] } else { 'White' }
        Write-Host ($gV + ' ') -NoNewline -ForegroundColor $color
        Write-Host ([string]$lines[$i]).PadRight($inner) -NoNewline -ForegroundColor $c
        Write-Host (' ' + $gV) -ForegroundColor $color
    }
    Write-Host ($gBL + ($gH * ($script:W - 2)) + $gBR) -ForegroundColor $color
}

Clear-Host
Write-Host ""
Write-Box @(
    "C L A S S L O A D E R   D U M P",
    "v$($script:ToolVersion)",
    "",
    "Dm .p1ae for Questions or Bugs"
) 'Cyan' @('Cyan', 'DarkGray', 'White', 'Gray', 'Gray')

Write-Host ""
Write-Host "  Select an action" -ForegroundColor White
Write-Host ("  " + ($gH * ($script:W - 4))) -ForegroundColor DarkGray
Write-Host "   [1]" -NoNewline -ForegroundColor Cyan;  Write-Host "  Start" -ForegroundColor White
Write-Host "   [2]" -NoNewline -ForegroundColor Cyan;  Write-Host "  Exit" -ForegroundColor White
Write-Host ""
Write-Host "  press 1 or 2 $gPrompt " -NoNewline -ForegroundColor DarkGray
$key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
$choice = $key.Character.ToString()
Write-Host $choice -ForegroundColor Cyan
if ($choice -eq "2") {
    Write-Host ""
    Write-Dim "Exiting..."
    exit
}
if ($choice -ne "1") {
    Write-Host ""
    Write-Fail "Invalid choice. Exiting."
    exit
}

if (-not ('ProcessHelper' -as [type])) {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class ProcessHelper
{
    [DllImport("ntdll.dll", SetLastError = true)]
    private static extern int NtQueryInformationProcess(IntPtr ProcessHandle, int ProcessInformationClass, IntPtr ProcessInformation, int ProcessInformationLength, out int ReturnLength);
    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool ReadProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, IntPtr lpBuffer, int dwSize, out int lpNumberOfBytesRead);
    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern IntPtr OpenProcess(int dwDesiredAccess, bool bInheritHandle, int dwProcessId);
    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool CloseHandle(IntPtr hObject);
    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool IsWow64Process(IntPtr hProcess, out bool wow64Process);
    private const int PROCESS_QUERY_INFORMATION = 0x0400;
    private const int PROCESS_VM_READ = 0x0010;
    private static string ReadRemoteUnicodeString(IntPtr hProcess, IntPtr addr)
    {
        IntPtr ustrBuf = Marshal.AllocHGlobal(16);
        try
        {
            int br;
            if (!ReadProcessMemory(hProcess, addr, ustrBuf, 16, out br) || br != 16) return null;
            short length = Marshal.ReadInt16(ustrBuf, 0);
            if (length <= 0) return null;
            IntPtr bufPtr = Marshal.ReadIntPtr(ustrBuf, 8);
            if (bufPtr == IntPtr.Zero) return null;
            IntPtr strBuf = Marshal.AllocHGlobal(length);
            try
            {
                if (!ReadProcessMemory(hProcess, bufPtr, strBuf, length, out br) || br != length) return null;
                return Marshal.PtrToStringUni(strBuf, length / 2);
            }
            finally { Marshal.FreeHGlobal(strBuf); }
        }
        finally { Marshal.FreeHGlobal(ustrBuf); }
    }
    public static string GetCurrentDirectory(int pid)
    {
        IntPtr hProcess = OpenProcess(PROCESS_QUERY_INFORMATION | PROCESS_VM_READ, false, pid);
        if (hProcess == IntPtr.Zero) return null;
        try
        {
            bool wow64;
            if (!IsWow64Process(hProcess, out wow64) || wow64) return null;
            IntPtr pbi = Marshal.AllocHGlobal(48);
            try
            {
                int retLen;
                if (NtQueryInformationProcess(hProcess, 0, pbi, 48, out retLen) != 0) return null;
                IntPtr pebAddr = Marshal.ReadIntPtr(pbi, 8);
                if (pebAddr == IntPtr.Zero) return null;
                IntPtr paramPtrBuf = Marshal.AllocHGlobal(8);
                try
                {
                    int br;
                    if (!ReadProcessMemory(hProcess, pebAddr + 0x20, paramPtrBuf, 8, out br) || br != 8) return null;
                    IntPtr procParams = Marshal.ReadIntPtr(paramPtrBuf);
                    if (procParams == IntPtr.Zero) return null;
                    return ReadRemoteUnicodeString(hProcess, procParams + 0x38);
                }
                finally { Marshal.FreeHGlobal(paramPtrBuf); }
            }
            finally { Marshal.FreeHGlobal(pbi); }
        }
        finally { CloseHandle(hProcess); }
    }
}
"@
}

Add-Type -AssemblyName System.IO.Compression -ErrorAction SilentlyContinue
Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue

function Get-ProcessCurrentDirectory([int]$processId) {
    try { return [ProcessHelper]::GetCurrentDirectory($processId) } catch { return $null }
}
function Get-LayoutBases([string]$path) {
    return @($path, (Join-Path $path ".minecraft"), (Join-Path $path "game"))
}

$RemapCacheFolderNames = @(".fabric", ".quilt")
function Get-RemapCacheFolders([string]$base) {
    $found = New-Object System.Collections.Generic.List[string]
    foreach ($name in $RemapCacheFolderNames) {
        $candidate = Join-Path $base $name
        if (Test-Path $candidate -ErrorAction SilentlyContinue) { [void]$found.Add($candidate) }
    }
    return $found
}

function Find-UpwardFolders([string]$startDir, [string]$folderName, [int]$maxDepth = 6) {
    $found = New-Object System.Collections.Generic.List[string]
    $current = $startDir
    for ($i = 0; $i -lt $maxDepth; $i++) {
        if (-not $current) { break }
        $direct = Join-Path $current $folderName
        if (Test-Path $direct -ErrorAction SilentlyContinue) { [void]$found.Add($direct) }
        $metaVariant = Join-Path $current "meta\$folderName"
        if (Test-Path $metaVariant -ErrorAction SilentlyContinue) { [void]$found.Add($metaVariant) }
        $parent = Split-Path $current -Parent
        if (-not $parent -or $parent -eq $current) { break }
        $current = $parent
    }
    return $found
}

function New-InstanceInfo([string]$base, [string]$modsPath) {
    return @{
        Mods      = $modsPath
        Versions  = (Find-UpwardFolders $base "versions")
        Remapped  = (Get-RemapCacheFolders $base)
        Base      = $base
    }
}

function Resolve-InstanceFolders([string]$cwd) {
    if (-not $cwd -or -not (Test-Path $cwd -ErrorAction SilentlyContinue)) { return $null }
    foreach ($base in (Get-LayoutBases $cwd)) {
        $modsPath = Join-Path $base "mods"
        if (Test-Path $modsPath -ErrorAction SilentlyContinue) { return (New-InstanceInfo $base $modsPath) }
    }
    try {
        foreach ($entry in (Get-ChildItem -LiteralPath $cwd -Directory -ErrorAction SilentlyContinue)) {
            foreach ($base in (Get-LayoutBases $entry.FullName)) {
                $modsPath = Join-Path $base "mods"
                if (Test-Path $modsPath -ErrorAction SilentlyContinue) { return (New-InstanceInfo $base $modsPath) }
            }
        }
    } catch {}
    return $null
}

function Get-ProcessInstanceBase($proc) {
    $cwd = Get-ProcessCurrentDirectory -processId $proc.Id
    if (-not $cwd) {
        try {
            $info = Get-CimInstance -ClassName Win32_Process -Filter "ProcessId = $($proc.Id)" -ErrorAction Stop
            if ($info -and $info.CurrentDirectory) { $cwd = $info.CurrentDirectory }
        } catch {}
    }
    if (-not $cwd) { return $null }
    $resolved = Resolve-InstanceFolders $cwd
    if ($resolved) { return $resolved.Base }
    return $null
}

function Get-KnownLauncherRoots {
    $appData = $env:APPDATA
    $userProfile = $env:USERPROFILE
    $roots = [System.Collections.Generic.List[string]]::new()
    if ($appData) {
        $roots.Add("$appData\.minecraft")
        $roots.Add("$appData\ModrinthApp\profiles")
        $roots.Add("$appData\PrismLauncher\instances")
        $roots.Add("$appData\MultiMC\instances")
        $roots.Add("$appData\ATLauncher\instances")
        $roots.Add("$appData\.feather\profiles")
        $roots.Add("$appData\.dawn\profiles")
        $roots.Add("$appData\gdlauncher_next\instances")
        $roots.Add("$appData\.technic\modpacks")
        $roots.Add("$appData\.ftba\instances")
        $roots.Add("$appData\PolyMC\instances")
    }
    if ($userProfile) {
        $roots.Add("$userProfile\curseforge\minecraft\Instances")
        $roots.Add("$userProfile\.lunarclient")
    }
    return $roots
}
function Find-CandidateInstanceBases {
    $bases = New-Object System.Collections.Generic.List[string]
    foreach ($root in (Get-KnownLauncherRoots)) {
        if (-not (Test-Path $root -ErrorAction SilentlyContinue)) { continue }
        foreach ($b in (Get-LayoutBases $root)) { $bases.Add($b) }
        foreach ($entry in (Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue)) {
            foreach ($b in (Get-LayoutBases $entry.FullName)) { $bases.Add($b) }
        }
    }
    return $bases
}
function Find-LatestInstanceByLog {
    $bestBase = $null
    $bestTime = [datetime]::MinValue
    $checked = 0
    foreach ($base in (Find-CandidateInstanceBases)) {
        $logPath = Join-Path $base "logs\latest.log"
        if (-not (Test-Path $logPath -ErrorAction SilentlyContinue)) { continue }
        $checked++
        try {
            $t = (Get-Item -LiteralPath $logPath -ErrorAction Stop).LastWriteTime
            if ($t -gt $bestTime) { $bestTime = $t; $bestBase = $base }
        } catch {}
    }
    Write-Dim "Checked $checked instance log(s) across all known launchers" 4
    if ($bestBase) { Write-Dim "Newest latest.log: $bestTime  $gArrow  $bestBase" 4 }
    return $bestBase
}

$instanceFolders = $null
$modsFolder = $null
Write-Section "Detect instance"
Write-Info "Looking for the mods folder of the running Minecraft instance..."
$javaProcs = Get-Process -Name javaw -ErrorAction SilentlyContinue
if ($javaProcs) {
    foreach ($proc in $javaProcs) {
        $cwd = Get-ProcessCurrentDirectory -processId $proc.Id
        if ($cwd) {
            $candidate = Resolve-InstanceFolders $cwd
            if ($candidate) {
                $instanceFolders = $candidate
                $modsFolder = $candidate.Mods
                Write-Ok "mods  $modsFolder"
                break
            }
        }
    }
}
if (-not $modsFolder) {
    Write-Dim "PEB path found no mods folder $gDash scanning every launcher's instances for the newest logs\latest.log..."
    $latestBase = Find-LatestInstanceByLog
    if ($latestBase) {
        $candidate = Resolve-InstanceFolders $latestBase
        if ($candidate) {
            $instanceFolders = $candidate
            $modsFolder = $candidate.Mods
            Write-Ok "mods (via newest latest.log)  $modsFolder"
        } else {
            Write-Warn "Newest latest.log found at $latestBase but no matching mods folder next to it"
        }
    }
}
if (-not $modsFolder -and $javaProcs) {
    Write-Dim "Trying Win32_Process CWD fallback..."
    foreach ($proc in $javaProcs) {
        try {
            $info = Get-CimInstance -ClassName Win32_Process -Filter "ProcessId = $($proc.Id)" -ErrorAction Stop
            if ($info -and $info.CurrentDirectory) {
                $cwd = $info.CurrentDirectory
                Write-Dim "Win32_Process CWD for PID $($proc.Id): $cwd" 4
                $candidate = Resolve-InstanceFolders $cwd
                if ($candidate) {
                    $instanceFolders = $candidate
                    $modsFolder = $candidate.Mods
                    Write-Ok "mods (via Win32_Process)  $modsFolder"
                    break
                }
            }
        } catch {}
    }
}
if (-not $modsFolder) {
    Write-Warn "Could not detect the mods folder. Mod jars will only be checked if the JVM loaded classes from them."
}

$MsiUrl = "https://github.com/adoptium/temurin25-binaries/releases/download/jdk-25.0.3%2B9/OpenJDK25U-jdk_x64_windows_hotspot_25.0.3_9.msi"
$MsiName = "OpenJDK25U-jdk_x64_windows_hotspot_25.0.3_9.msi"

function Find-AllJdkToolCandidates([string]$toolExeName, $proc, [bool]$firstOnly = $false) {
    $candidates = New-Object System.Collections.Generic.List[string]
    $direct = New-Object System.Collections.Generic.List[string]
    if ($PSScriptRoot) { $direct.Add((Join-Path $PSScriptRoot $toolExeName)) }
    try { if ($proc -and $proc.Path) { $direct.Add((Join-Path (Split-Path $proc.Path) $toolExeName)) } } catch {}
    if ($env:JAVA_HOME) { $direct.Add((Join-Path $env:JAVA_HOME "bin\$toolExeName")) }
    $onPath = Get-Command $toolExeName -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($onPath -and $onPath.Source) { $direct.Add($onPath.Source) }
    foreach ($c in $direct) {
        if ((Test-Path $c -ErrorAction SilentlyContinue) -and -not $candidates.Contains($c)) {
            $candidates.Add($c)
            if ($firstOnly) { return $candidates }
        }
    }
    $roots = @(
        "C:\Program Files\Eclipse Adoptium",
        "C:\Program Files\Java",
        "C:\Program Files\Microsoft",
        "C:\Program Files\Zulu",
        "C:\Program Files\Amazon Corretto",
        "$env:LOCALAPPDATA\Programs\Java"
    )
    foreach ($r in $roots) {
        if ($firstOnly) {
            $hit = Get-ChildItem -Path $r -Filter $toolExeName -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($hit) { $candidates.Add($hit.FullName); return $candidates }
            continue
        }
        Get-ChildItem -Path $r -Filter $toolExeName -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
            if (-not $candidates.Contains($_.FullName)) { $candidates.Add($_.FullName) }
        }
    }
    return $candidates
}
function Find-JdkTool([string]$toolExeName, $proc) {
    return (@(Find-AllJdkToolCandidates $toolExeName $proc $true) | Select-Object -First 1)
}
function Find-Jcmd($proc) { return Find-JdkTool "jcmd.exe" $proc }
function Find-Jimage($proc) { return Find-JdkTool "jimage.exe" $proc }
function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal $id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
function Install-Temurin {
    if (-not (Test-Admin)) {
        Write-Info "Need admin to install the JDK $gDash relaunching elevated..."
        Start-Process powershell.exe -Verb RunAs -ArgumentList @("-ExecutionPolicy","Bypass","-File","`"$PSCommandPath`"")
        exit
    }
    $msiPath = Join-Path $env:TEMP $MsiName
    Write-Info "Downloading Temurin 25 JDK (~180 MB)..."
    try {
        Invoke-WebRequest -Uri $MsiUrl -OutFile $msiPath -UseBasicParsing
    } catch {
        Write-Fail "Download failed: $($_.Exception.Message)"
        return $null
    }
    Write-Info "Installing silently..."
    Start-Process msiexec.exe -ArgumentList "/i `"$msiPath`" /qn /norestart" -Wait | Out-Null
    Remove-Item $msiPath -ErrorAction SilentlyContinue
    return (Find-Jcmd $null)
}

function Test-JavaSupportsAttach([string]$javaPath) {
    $ErrorActionPreference = 'Continue'
    if (-not $javaPath -or -not (Test-Path $javaPath -ErrorAction SilentlyContinue)) { return $false }
    try {
        $out = & $javaPath --add-modules jdk.attach -version 2>&1
        if ($LASTEXITCODE -ne 0) { return $false }
        if (("$out") -match "jdk\.attach|FindException") { return $false }
        return $true
    } catch {
        return $false
    }
}

function Find-AttachCapableJdk($proc) {
    foreach ($javaCandidate in (Find-AllJdkToolCandidates "java.exe" $proc)) {
        if (-not (Test-JavaSupportsAttach $javaCandidate)) { continue }
        $bin = Split-Path $javaCandidate -Parent
        $javacCandidate = Join-Path $bin "javac.exe"
        $jarCandidate = Join-Path $bin "jar.exe"
        if ((Test-Path $javacCandidate -ErrorAction SilentlyContinue) -and (Test-Path $jarCandidate -ErrorAction SilentlyContinue)) {
            return @{ Java = $javaCandidate; Javac = $javacCandidate; Jar = $jarCandidate }
        }
    }
    return $null
}

Write-Section "Locate JDK"
Write-Info "Searching for jcmd + jimage + javac + jar + java..."
$firstJavaProc = if ($javaProcs) { $javaProcs[0] } else { $null }
$jcmd = Find-Jcmd $firstJavaProc
if (-not $jcmd) {
    Write-Warn "jcmd not found locally"
    $jcmd = Install-Temurin
}
$jimage = $null
$javacExe = $null
$jarExe = $null
$javaExe = $null
if ($jcmd) {
    Write-Ok "jcmd    $jcmd"
    $jimage = Find-Jimage $firstJavaProc
    if ($jimage) {
        Write-Ok "jimage  $jimage"
    } else {
        Write-Warn "jimage.exe not found next to jcmd - JDK platform classes can't be indexed and will be reported as unverified."
    }
    $javacExe = Find-JdkTool "javac.exe" $firstJavaProc
    $jarExe   = Find-JdkTool "jar.exe" $firstJavaProc
    $javaExe  = Find-JdkTool "java.exe" $firstJavaProc

    if ($javaExe -and -not (Test-JavaSupportsAttach $javaExe)) {
        Write-Dim "$javaExe can't resolve the jdk.attach module - probing other JDKs for one that can..." 4
        $attachCapable = Find-AttachCapableJdk $firstJavaProc
        if ($attachCapable) {
            $javaExe = $attachCapable.Java
            $javacExe = $attachCapable.Javac
            $jarExe = $attachCapable.Jar
            Write-Ok "attach-capable JDK  $javaExe"
        } else {
            Write-Warn "No attach-capable JDK found on this machine - provenance mode will fail to attach; the name-based fallback will still run."
        }
    }
} else {
    Write-Fail "Could not obtain a JDK. Classloader dumps require jcmd - aborting."
    exit
}

$script:Verified = @{}
$script:AnalysisCache = @{}
$script:StateCache = @{}
$script:VerifiedClasses = New-Object System.Collections.Generic.HashSet[string]
$script:JdkClasses = New-Object System.Collections.Generic.HashSet[string]
$script:HttpHeaders = @{ 'User-Agent' = "p1ae-classloader-dump/$($script:ToolVersion) (screenshare tool)" }
$script:JvmStartUtc = [datetime]::MaxValue
$script:OnlineOK = $false

$JdkSpunPattern  = '^java\.lang\.invoke\.(LambdaForm\$[A-Za-z0-9_]+|BoundMethodHandle\$Species_[A-Za-z0-9_]+|(DirectMethodHandle|DelegatingMethodHandle|Invokers)\$Holder)$'
$ProxyPattern    = '^(com\.sun\.proxy\.)?jdk\.proxy\d+\.\$Proxy\d+$|^com\.sun\.proxy\.\$Proxy\d+$|^\$Proxy\d+$'
$AccessorPattern = '^(jdk\.internal|sun)\.reflect\.Generated(Method|Constructor|SerializationConstructor)Accessor\d+$'

$P1Build = '2026-11-10.10'
$fastSource = @'
using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Net;
using System.Net.Http;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;

public class P1JarInfo
{
    public bool Exists;
    public bool Parsed;
    public string Error;
    public string Sha1, Sha256, Sha512;
    public HashSet<string> Classes = new HashSet<string>();
    public List<string[]> Nested = new List<string[]>();
}

public class P1Ctx
{
    public string Kind = "NONE";
    public string Path;
    public bool IsDir, Missing, Late, Reparse;
    public string Stamp;
    public bool AExists, AParsed, AExempt, Derived;
    public string AError, ATier, AReason;
    public string DState = "", DKey = "";
    public HashSet<string> Classes;
}
public class P1Records { public string[] Name, Loader, CodeSource, Hidden, Proxy; }
public class P1Result { public string[] Tier, Reason, Jar; }

public static class P1Fast
{
    public const string Build = "__P1BUILD__";
    const RegexOptions Ro = RegexOptions.IgnoreCase | RegexOptions.Compiled;
    static readonly Regex VerRx = new Regex(@"^META-INF/versions/\d+/", Ro);
    static readonly Regex SkipRx = new Regex(@"unique loaded classes|^COMMAND|^PROCESS|^EXE|^\u2501+$", Ro);
    static readonly Regex AtRx = new Regex(@"@[0-9a-fA-F]+", Ro);
    static readonly Regex ArrRx = new Regex(@"\[+L([a-zA-Z_$][a-zA-Z0-9_$.-]*);", Ro);
    static readonly Regex NameRx = new Regex(@"(?:[a-zA-Z_$][a-zA-Z0-9_$-]*\.)+[a-zA-Z_$-][a-zA-Z0-9_$-]*", Ro);
    static readonly Regex HexSuffixRx = new Regex(@"/(0x)?[0-9a-fA-F]+$", Ro);
    static readonly Regex LambdaRx = new Regex(@"\$\$(Lambda|InjectedInvoker).*$", Ro);
    static readonly Regex ArrayWrapRx = new Regex(@"^\[+L(.+);$", Ro);

    const RegexOptions Rs = RegexOptions.Compiled;
    static readonly Regex AnonRx = new Regex(@"\$Anonymous\$[0-9a-f]{32}$", Rs);
    static readonly Regex FillerRx = new Regex(@"^jdk\.internal\.vm\.Filler(Object|Element)$", Rs);
    static readonly Regex MxGenRx = new Regex(@"^com\.llamalad7\.mixinextras\.sugar\.impl\.ref\.generated\.[A-Za-z0-9_]+$", Rs);

    static readonly Regex JdkProxyRx = new Regex(@"jdk\.proxy\d+\.", Rs);
    public static HashSet<string> Intermediary = new HashSet<string>();

    static readonly Regex MixinArgsRx = new Regex(@"^org\.spongepowered\.asm\.synthetic\.args\.Args\$\d+$", Rs);
    static bool IsMixinArgs(string b, HashSet<string> verified)
    {
        return MixinArgsRx.IsMatch(b) && verified.Contains("org.spongepowered.asm.mixin.injection.invoke.arg.Args");
    }

    public static bool IsGeneratedOrIntermediary(string b, HashSet<string> verified, HashSet<string> jdk, bool mxOk)
    {
        if (FillerRx.IsMatch(b)) { return true; }
        if (IsMixinArgs(b, verified)) { return true; }
        if (mxOk && MxGenRx.IsMatch(b)) { return true; }
        if (Intermediary != null && Intermediary.Contains(b)) { return true; }
        string outer = AnonRx.Replace(b, "");
        if (outer != b && (verified.Contains(outer) || jdk.Contains(outer) || (Intermediary != null && Intermediary.Contains(outer)))) { return true; }
        return false;
    }

    static string Hex(byte[] h)
    {
        StringBuilder sb = new StringBuilder(h.Length * 2);
        for (int i = 0; i < h.Length; i++) { sb.Append(h[i].ToString("x2")); }
        return sb.ToString();
    }

    static void HashAll(byte[] b, out string s1, out string s2, out string s3)
    {
        using (SHA1 a = SHA1.Create()) { s1 = Hex(a.ComputeHash(b)); }
        using (SHA256 a = SHA256.Create()) { s2 = Hex(a.ComputeHash(b)); }
        using (SHA512 a = SHA512.Create()) { s3 = Hex(a.ComputeHash(b)); }
    }

    static void ReadEntries(ZipArchive zip, int depth, P1JarInfo a)
    {
        foreach (ZipArchiveEntry e in zip.Entries)
        {
            string n = e.FullName;
            if (n.EndsWith(".class", StringComparison.Ordinal))
            {
                if (n == "module-info.class" || n.EndsWith("/module-info.class", StringComparison.Ordinal)) { continue; }
                if (n.StartsWith("META-INF/versions/", StringComparison.Ordinal)) { n = VerRx.Replace(n, ""); }
                else if (n.StartsWith("META-INF/", StringComparison.Ordinal)) { continue; }
                a.Classes.Add(n.Substring(0, n.Length - 6).Replace('/', '.'));
            }
            else if (n.EndsWith(".jar", StringComparison.Ordinal) && depth < 5 && e.Length < 104857600L)
            {
                try
                {
                    byte[] nb;
                    using (Stream es = e.Open())
                    using (MemoryStream ms = new MemoryStream())
                    {
                        es.CopyTo(ms);
                        nb = ms.ToArray();
                    }
                    string s1, s2, s3;
                    HashAll(nb, out s1, out s2, out s3);
                    a.Nested.Add(new string[] { n, s1, s2, s3 });
                    using (ZipArchive nz = new ZipArchive(new MemoryStream(nb), ZipArchiveMode.Read))
                    {
                        ReadEntries(nz, depth + 1, a);
                    }
                }
                catch (Exception) { }
            }
        }
    }

    public static P1JarInfo AnalyzeJar(string path)
    {
        P1JarInfo a = new P1JarInfo();
        try
        {
            byte[] bytes;
            using (FileStream fs = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete))
            using (MemoryStream ms0 = new MemoryStream())
            {
                fs.CopyTo(ms0);
                bytes = ms0.ToArray();
            }
            a.Exists = true;
            string s1, s2, s3;
            HashAll(bytes, out s1, out s2, out s3);
            a.Sha1 = s1; a.Sha256 = s2; a.Sha512 = s3;
            try
            {
                using (ZipArchive z = new ZipArchive(new MemoryStream(bytes), ZipArchiveMode.Read))
                {
                    ReadEntries(z, 0, a);
                }
                a.Parsed = true;
            }
            catch (Exception ex) { a.Error = "not parseable by strict zip reader: " + ex.Message; }
        }
        catch (Exception ex) { a.Error = ex.Message; }
        return a;
    }

    public static string[] GetMany(string[] urls, int threads, int timeoutSec, string ua)
    {
        try { ServicePointManager.DefaultConnectionLimit = Math.Max(ServicePointManager.DefaultConnectionLimit, threads * 2); } catch (Exception) { }
        string[] res = new string[urls.Length];
        using (HttpClient c = new HttpClient())
        {
            c.Timeout = TimeSpan.FromSeconds(timeoutSec);
            c.DefaultRequestHeaders.TryAddWithoutValidation("User-Agent", ua);
            ParallelOptions po = new ParallelOptions();
            po.MaxDegreeOfParallelism = threads < 1 ? 1 : threads;
            Parallel.For(0, urls.Length, po, delegate(int i)
            {
                try
                {
                    using (HttpResponseMessage r = c.GetAsync(urls[i]).Result)
                    {
                        if (r.IsSuccessStatusCode) { res[i] = r.Content.ReadAsStringAsync().Result; }
                    }
                }
                catch (Exception) { }
            });
        }
        return res;
    }

    static readonly Regex PrimRx = new Regex(@"^\[+[BCDFIJSZ]$", Ro);
    static readonly Regex PlatLoaderRx = new Regex(@"ClassLoaders\$PlatformClassLoader", Ro);
    static readonly Regex DelegRx = new Regex(@"(jdk\.internal|sun)\.reflect\.DelegatingClassLoader", Ro);
    static readonly Regex AnonAnyRx = new Regex(@"\$Anonymous\$[0-9a-fA-F]{32}$", Ro);
    static readonly Regex MxPrefixRx = new Regex(@"^com\.llamalad7\.mixinextras\.sugar\.impl\.ref\.generated\.", Ro);
    const string MxDone = "Mixin/MixinExtras runtime-generated class (library jar is verified)";

    static string BaseName(string n) { return LambdaRx.Replace(HexSuffixRx.Replace(n, ""), ""); }

    static bool LoaderHas(Dictionary<string, HashSet<string>> lbn, string cls, string loader)
    {
        HashSet<string> ls;
        return lbn.TryGetValue(cls, out ls) && ls.Contains(loader);
    }

    static void One(string rawName, string loader, string cs, Dictionary<string, P1Ctx> map,
        HashSet<string> verified, HashSet<string> jdk, Regex pr, Regex ac, Regex sp, bool mxOk,
        bool hid, bool hidSupported, Dictionary<string, HashSet<string>> lbn, string prx,
        out string tier, out string reason, out string jar)
    {
        jar = "";
        string name = rawName;
        if (PrimRx.IsMatch(name)) { tier = "Generated"; reason = "primitive array type (JVM-synthesized)"; return; }
        Match am = ArrayWrapRx.Match(name);
        if (am.Success) { name = am.Groups[1].Value; }
        bool hidOk = hidSupported ? hid : HexSuffixRx.IsMatch(name);
        string b = BaseName(name);
        bool stripped = b != name;
        P1Ctx c = null;
        if (cs != null) { map.TryGetValue(cs, out c); }
        string kind = c == null ? "NONE" : c.Kind;
        bool isBoot = string.Equals(loader, "BOOTSTRAP", StringComparison.OrdinalIgnoreCase) || PlatLoaderRx.IsMatch(loader);
        bool trustedLoader = verified.Contains(loader) || jdk.Contains(loader);
        bool mxLdOk = LoaderHas(lbn, "com.llamalad7.mixinextras.MixinExtrasBootstrap", loader);
        bool argsLdOk = LoaderHas(lbn, "org.spongepowered.asm.mixin.injection.invoke.arg.Args", loader) || trustedLoader;
        bool isMxGen = (mxOk && mxLdOk && MxPrefixRx.IsMatch(b)) || (argsLdOk && IsMixinArgs(b, verified));

        if (isBoot || kind == "JRT")
        {
            if (jdk.Count == 0) { tier = "Unverified"; reason = "JDK runtime image could not be indexed (jimage/rt.jar unavailable)"; return; }
            if (jdk.Contains(b) && (!stripped || hidOk || jdk.Contains(name))) { tier = "Verified"; reason = "present in this JVM runtime image"; return; }
            if (sp.IsMatch(b)) { tier = "Generated"; reason = "JDK-spun invoke class"; return; }
            if (pr.IsMatch(b) || ac.IsMatch(b)) { tier = "Generated"; reason = "JDK-generated class"; return; }
            if (FillerRx.IsMatch(b)) { tier = "Generated"; reason = "JVM-internal heap filler class"; return; }
            tier = "Suspicious"; reason = "loaded by bootstrap/platform loader but NOT present in the JDK runtime image (bootclasspath injection?)"; return;
        }

        if (kind != "FILE")
        {
            if (kind == "OTHER") { tier = "Unverified"; reason = "codesource is not a local file: " + cs; return; }
            if (string.Equals(cs, "ERROR", StringComparison.OrdinalIgnoreCase)) { tier = "Suspicious"; reason = "codesource lookup threw an error"; return; }
            if (pr.IsMatch(b))
            {
                if (prx == "true") { tier = "Generated"; reason = "dynamic proxy, confirmed by the JVM (its handler classes are checked on their own)"; return; }
                if (prx == "false") { tier = "Suspicious"; reason = "named like a dynamic proxy but the JVM says it is not a proxy class - spoofed name"; return; }
                if (!JdkProxyRx.IsMatch(b) || jdk.Contains(loader) || verified.Contains(loader)) { tier = "Generated"; reason = "dynamic proxy (its handler classes are checked on their own)"; return; }
                tier = "Unverified"; reason = "named like a JDK dynamic proxy (jdk.proxyN) but defined by unverified loader " + loader + " - staff review"; return;
            }
            if (ac.IsMatch(b) && DelegRx.IsMatch(loader)) { tier = "Generated"; reason = "reflection accessor"; return; }
            if (stripped && (verified.Contains(b) || jdk.Contains(b)))
            {
                HashSet<string> bl;
                bool ldOk = lbn.TryGetValue(b, out bl) && bl.Contains(loader);
                if (hidOk && ldOk) { tier = "Generated"; reason = "generated from verified class " + b; return; }
                tier = "Unverified";
                reason = "named like a class generated from " + b + " but " + (!hidOk ? "it is not a hidden/VM-anonymous class" : "it was defined by a different loader than " + b) + " - staff review";
                return;
            }
            string anonOuter = AnonAnyRx.Replace(b, "");
            if (anonOuter != b && (verified.Contains(anonOuter) || IsGeneratedOrIntermediary(anonOuter, verified, jdk, mxOk)))
            {
                if (LoaderHas(lbn, anonOuter, loader)) { tier = "Generated"; reason = "Mixin-generated inner class of " + anonOuter; return; }
                tier = "Unverified"; reason = "named like a Mixin-generated inner class of " + anonOuter + " but it was defined by a different loader - staff review"; return;
            }
            if (isMxGen) { tier = "Generated"; reason = MxDone; return; }
            if (MxPrefixRx.IsMatch(b) || IsMixinArgs(b, verified)) { tier = "Unverified"; reason = "named like a Mixin/MixinExtras generated class but defined by a loader that did not load that library (" + loader + ") - staff review"; return; }
            tier = "Unverified"; reason = "in-memory class with no backing file - cannot be verified, staff review"; return;
        }

        string path = c.Path;
        jar = path;
        if (c.IsDir) { tier = "Unverified"; reason = "loaded from a directory (cannot be hash-verified): " + path; return; }
        if (c.Missing) { tier = "Suspicious"; reason = "codesource file no longer exists (deleted after load?): " + path; return; }
        if (!c.AExists) { tier = "Unverified"; reason = "codesource file unreadable: " + path + " (" + c.AError + ")"; return; }

        HashSet<string> cls = c.Classes ?? new HashSet<string>();
        bool derived = c.Derived;
        if (!c.AExempt && c.Late)
        {
            tier = "Suspicious";
            reason = (derived ? "launcher cache jar was created/modified well AFTER the JVM finished starting (" : "jar was created/modified AFTER the JVM started (") + c.Stamp + " UTC) - replaced or altered at runtime: " + path;
            return;
        }
        if (stripped && !hidOk && !cls.Contains(name))
        { tier = "Unverified"; reason = "named like a lambda/hidden class of " + b + " but it is not a hidden class - staff review: " + path; return; }
        string note = c.Reparse ? " [file is a symlink/reparse point]" : "";

        if (c.ATier == "BADLOCAL") { tier = "Suspicious"; reason = c.AReason + ": " + path + note; return; }

        if (c.ATier == "OFFICIAL" || c.ATier == "LOCAL")
        {
            string tn = c.ATier == "OFFICIAL" ? "Verified" : "Weak";
            if (!c.AParsed) { tier = tn; reason = c.AReason + " (jar not strict-parseable; class presence unchecked)" + note; return; }
            if (!cls.Contains(b) && isMxGen) { tier = "Generated"; reason = MxDone; return; }
            if (!cls.Contains(b))
            { tier = "Suspicious"; reason = "claims to come from verified jar (" + c.AReason + ") but that jar does not contain this class - forged codesource or jar swapped: " + path; return; }
            tier = tn; reason = c.AReason + note; return;
        }

        if (derived)
        {
            if (!c.AParsed) { tier = "Unverified"; reason = "launcher-cache jar not strict-parseable: " + path; return; }
            if (c.DState == "mismatch") { tier = "Suspicious"; reason = "launcher cache jar content does NOT match the built-in known-good digest for " + c.DKey + " - its classes were altered: " + path; return; }
            if (!cls.Contains(b) && isMxGen) { tier = "Generated"; reason = MxDone; return; }
            if (!cls.Contains(b)) { tier = "Suspicious"; reason = "class not present in the launcher-cache jar it claims to come from: " + path; return; }
            if (verified.Contains(b) || (Intermediary != null && Intermediary.Contains(b)))
            {
                if (c.DState == "match") { tier = "Verified"; reason = "launcher cache jar content matches the built-in known-good digest (" + c.DKey + ")" + note; return; }
                tier = "Derived"; reason = "launcher cache jar; exact class name is in the verified intermediary mappings or a verified jar (bytes NOT hash-verifiable)" + note; return;
            }
            tier = "Unverified"; reason = "class sits in a launcher cache jar but its exact name is not in the verified mappings or any verified jar: " + path; return;
        }

        string why = !string.IsNullOrEmpty(c.AError) ? "jar hash not in any database; " + c.AError : "jar hash not found in Mojang / Fabric / Quilt / Modrinth / Maven Central / staff list";
        tier = "Unverified"; reason = why + ": " + path + note;
    }

    public static P1Result Classify(string[] names, string[] loaders, string[] codesources, string[] hidden, string[] isProxy, string[] ctxKeys, P1Ctx[] ctxs,
        HashSet<string> verified, HashSet<string> jdk, string proxy, string accessor, string spun, bool mxOk)
    {
        Regex pr = new Regex(proxy, RegexOptions.IgnoreCase);
        Regex ac = new Regex(accessor, RegexOptions.IgnoreCase);
        Regex sp = new Regex(spun, RegexOptions.IgnoreCase);
        Dictionary<string, P1Ctx> map = new Dictionary<string, P1Ctx>();
        for (int i = 0; i < ctxKeys.Length; i++) { map[ctxKeys[i]] = ctxs[i]; }
        int n = names.Length;
        P1Result r = new P1Result();
        r.Tier = new string[n]; r.Reason = new string[n]; r.Jar = new string[n];
        bool hidSupported = false;
        Dictionary<string, HashSet<string>> lbn = new Dictionary<string, HashSet<string>>();
        for (int i = 0; i < n; i++)
        {
            if (hidden != null && i < hidden.Length && hidden[i] == "true") { hidSupported = true; }
            HashSet<string> ls;
            if (!lbn.TryGetValue(names[i], out ls)) { ls = new HashSet<string>(); lbn[names[i]] = ls; }
            ls.Add(loaders[i]);
        }
        for (int i = 0; i < n; i++)
        {
            string t, re, j;
            bool hid = hidden != null && i < hidden.Length && hidden[i] == "true";
            string prx = (isProxy != null && i < isProxy.Length && isProxy[i] != null) ? isProxy[i] : "";
            One(names[i], loaders[i], codesources[i], map, verified, jdk, pr, ac, sp, mxOk, hid, hidSupported, lbn, prx, out t, out re, out j);
            r.Tier[i] = t; r.Reason[i] = re; r.Jar[i] = j;
        }

        return r;
    }

    public static P1Records ParseReport(string path)
    {
        List<string> n = new List<string>(), l = new List<string>(), c = new List<string>(), h = new List<string>(), x = new List<string>();
        if (File.Exists(path))
        {
            foreach (string line in File.ReadAllLines(path, Encoding.UTF8))
            {
                if (line.Length == 0) { continue; }
                string[] p = line.Split('\t');
                if (p.Length < 6) { continue; }
                n.Add(p[0]); l.Add(p[1]); c.Add(p[2]); h.Add(p[3]); x.Add(p.Length > 6 ? p[6] : "");
            }
        }
        P1Records r = new P1Records();
        r.Name = n.ToArray(); r.Loader = l.ToArray(); r.CodeSource = c.ToArray(); r.Hidden = h.ToArray(); r.Proxy = x.ToArray();
        return r;
    }

    public static string ContentDigest(string path)
    {
        try
        {
            List<string> items = new List<string>();
            using (FileStream fs = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete))
            using (ZipArchive z = new ZipArchive(fs, ZipArchiveMode.Read))
            using (SHA256 sha = SHA256.Create())
            {
                foreach (ZipArchiveEntry e in z.Entries)
                {
                    if (!e.FullName.EndsWith(".class", StringComparison.Ordinal)) { continue; }
                    using (Stream es = e.Open()) { items.Add(e.FullName + ":" + Hex(sha.ComputeHash(es))); }
                }
                items.Sort(StringComparer.Ordinal);
                return Hex(sha.ComputeHash(Encoding.UTF8.GetBytes(string.Join("\n", items.ToArray()))));
            }
        }
        catch (Exception) { return null; }
    }

    public static string[] Distinct(string[] items)
    {
        HashSet<string> seen = new HashSet<string>();
        List<string> o = new List<string>();
        foreach (string s in items) { if (seen.Add(s)) { o.Add(s); } }
        return o.ToArray();
    }

    public static string[] MissingNames(string[] jcmdNames, string[] agentNames)
    {
        HashSet<string> set = new HashSet<string>();
        foreach (string raw in agentNames)
        {
            string nm = raw;
            Match m = ArrayWrapRx.Match(nm);
            if (m.Success) { nm = m.Groups[1].Value; }
            set.Add(nm); set.Add(BaseName(nm));
        }
        List<string> miss = new List<string>();
        foreach (string x in jcmdNames) { if (!set.Contains(x) && !set.Contains(BaseName(x))) { miss.Add(x); } }
        miss.Sort(StringComparer.OrdinalIgnoreCase);
        return miss.ToArray();
    }

    public static P1JarInfo[] AnalyzeMany(string[] paths, int threads)
    {
        P1JarInfo[] res = new P1JarInfo[paths.Length];
        ParallelOptions po = new ParallelOptions();
        po.MaxDegreeOfParallelism = threads < 1 ? 1 : threads;
        Parallel.For(0, paths.Length, po, delegate(int i) { res[i] = AnalyzeJar(paths[i]); });
        return res;
    }

    public static HashSet<string> ExtractClassNames(string raw)
    {
        HashSet<string> found = new HashSet<string>();
        if (raw == null) { return found; }
        foreach (string l0 in raw.Split('\n'))
        {
            string line = l0.TrimEnd('\r');
            if (line.Length == 0 || SkipRx.IsMatch(line)) { continue; }
            string clean = AtRx.Replace(line, "");
            clean = ArrRx.Replace(clean, "$1");
            foreach (Match m in NameRx.Matches(clean)) { found.Add(m.Value); }
        }
        return found;
    }

    public static List<string> FilterUnknown(string[] names, HashSet<string> verified, HashSet<string> jdk, string proxy, string accessor, string spun, bool mxOk)
    {
        Regex pr = new Regex(proxy, RegexOptions.IgnoreCase);
        Regex ac = new Regex(accessor, RegexOptions.IgnoreCase);
        Regex sp = new Regex(spun, RegexOptions.IgnoreCase);
        List<string> unknown = new List<string>();
        foreach (string orig in names)
        {
            string name = orig;
            Match am = ArrayWrapRx.Match(name);
            if (am.Success) { name = am.Groups[1].Value; }
            string b = LambdaRx.Replace(HexSuffixRx.Replace(name, ""), "");
            if (verified.Contains(b) || jdk.Contains(b)) { continue; }
            if (pr.IsMatch(b) || ac.IsMatch(b) || sp.IsMatch(b)) { continue; }
            if (IsGeneratedOrIntermediary(b, verified, jdk, mxOk)) { continue; }
            unknown.Add(orig);
        }
        return unknown;
    }

    public static int ParseJimage(string[] lines, HashSet<string> target)
    {
        int count = 0;
        foreach (string line in lines)
        {
            string t = line == null ? "" : line.Trim();
            if (t.Length == 0 || t.StartsWith("Module:", StringComparison.Ordinal) || !t.EndsWith(".class", StringComparison.Ordinal)) { continue; }
            if (t == "module-info.class") { continue; }
            target.Add(t.Substring(0, t.Length - 6).Replace('/', '.'));
            count++;
        }
        return count;
    }
}
'@.Replace('__P1BUILD__', $P1Build)

$script:FastOK = $false
$script:FastErr = ''
try {
    $needCompile = $true
    if ('P1Fast' -as [type]) {
        $loadedFast = try { [P1Fast]::Build } catch { $null }
        if ($loadedFast -eq $P1Build) { $needCompile = $false } else { throw 'an older build of the engine is already loaded in this PowerShell window' }
    }
    if ($needCompile) {
        if ($PSVersionTable.PSVersion.Major -ge 6) { Add-Type -TypeDefinition $fastSource }
        else { Add-Type -TypeDefinition $fastSource -ReferencedAssemblies 'System.IO.Compression','System.IO.Compression.FileSystem','System.Net.Http' }
    }
    $script:FastOK = $true
} catch { $script:FastOK = $false; $script:FastErr = ("$($_.Exception.Message)" -split "`r?`n")[0] }
if (-not $script:FastOK) {
    Write-Warn "Fast C# engine unavailable ($($script:FastErr))"
    Write-Warn "Using the slower PowerShell fallback - if this keeps happening, close this window and run again in a new one." 4
}
$EngineLine = if ($script:FastOK) { "Engine   : fast C# (build $P1Build)" } else { "Engine   : FALLBACK PowerShell engine ($($script:FastErr)) - launcher cache jars cannot be content-checked and are reported Unverified; rerun in a new PowerShell window" }

$script:LocCache = @{}
$script:RemapCache = @{}
$script:PathKeyCache = @{}
$script:RxBaseHex = New-Object System.Text.RegularExpressions.Regex -ArgumentList '/(0x)?[0-9a-fA-F]+$', ([System.Text.RegularExpressions.RegexOptions]'IgnoreCase, Compiled')
$script:RxBaseLam = New-Object System.Text.RegularExpressions.Regex -ArgumentList '\$\$(Lambda|InjectedInvoker).*$', ([System.Text.RegularExpressions.RegexOptions]'IgnoreCase, Compiled')
$script:LapSw = [Diagnostics.Stopwatch]::StartNew()
function Lap([string]$l) {
    if ($env:CLD_TIMING) { Write-Dim ("timing  {0,-24}{1,7:N1}s" -f $l, $script:LapSw.Elapsed.TotalSeconds) 4 }
    $script:LapSw.Restart()
}

function Add-Lines([string]$path, $lines) {
    try { [IO.File]::AppendAllLines($path, [string[]]@($lines), (New-Object System.Text.UTF8Encoding($false))) }
    catch { Add-Content -LiteralPath $path $lines }
}

function Register-Hash([string]$hash, [string]$tier, [string]$reason, [bool]$exempt = $false) {
    if (-not $hash) { return }
    $k = $hash.ToLower()
    $cur = $script:Verified[$k]
    if ($cur -and $cur.Tier -eq 'OFFICIAL') { return }
    if ($cur -and $cur.Tier -eq 'BADLOCAL' -and $tier -eq 'LOCAL') { return }
    $script:Verified[$k] = @{ Tier = $tier; Reason = $reason; Exempt = $exempt }
}
function Register-AllHashes($hashes, [string]$tier, [string]$reason, [bool]$exempt = $false) {
    foreach ($a in 'SHA1','SHA256','SHA512') { Register-Hash $hashes[$a] $tier $reason $exempt }
}

function Get-BytesHashes([byte[]]$bytes) {
    $out = @{}
    foreach ($a in 'SHA1','SHA256','SHA512') {
        $h = [System.Security.Cryptography.HashAlgorithm]::Create($a)
        $out[$a] = ([BitConverter]::ToString($h.ComputeHash($bytes)) -replace '-', '').ToLower()
        $h.Dispose()
    }
    return $out
}

function Get-PathKey([string]$p) {
    $hit = $script:PathKeyCache[$p]
    if ($hit) { return $hit }
    try { $k = ([IO.Path]::GetFullPath($p)).ToLower() } catch { $k = $p.ToLower() }
    $script:PathKeyCache[$p] = $k
    return $k
}

function Invoke-Json([string]$uri) {
    try { return Invoke-RestMethod -Uri $uri -Headers $script:HttpHeaders -TimeoutSec 30 -ErrorAction Stop } catch { return $null }
}

function Read-ZipEntries($zip, [int]$depth, $a) {
    foreach ($e in $zip.Entries) {
        $n = $e.FullName
        if ($n.EndsWith(".class")) {
            if ($n -eq "module-info.class" -or $n.EndsWith("/module-info.class")) { continue }
            if ($n.StartsWith("META-INF/versions/")) {
                $n = $n -replace '^META-INF/versions/\d+/', ''
            } elseif ($n.StartsWith("META-INF/")) { continue }
            [void]$a.Classes.Add(($n.Substring(0, $n.Length - 6) -replace '/', '.'))
        }
        elseif ($n.EndsWith(".jar") -and $depth -lt 5 -and $e.Length -lt 100MB) {
            try {
                $ms = New-Object System.IO.MemoryStream
                $es = $e.Open()
                $es.CopyTo($ms)
                $es.Dispose()
                $nb = $ms.ToArray()
                $ms.Dispose()
                [void]$a.Nested.Add(@{ Name = $n; Hashes = (Get-BytesHashes $nb) })
                $nz = New-Object System.IO.Compression.ZipArchive((New-Object System.IO.MemoryStream(,$nb)), [System.IO.Compression.ZipArchiveMode]::Read)
                Read-ZipEntries $nz ($depth + 1) $a
                $nz.Dispose()
            } catch {}
        }
    }
}

function Register-FastAnalysis([string]$path, [string]$key, $fi) {
    $a = [PSCustomObject]@{
        Path = $path; Exists = [bool]$fi.Exists; Hashes = $null; Parsed = [bool]$fi.Parsed; Error = $fi.Error
        Classes = $fi.Classes
        Nested = (New-Object System.Collections.Generic.List[object])
        Tier = 'NONE'; Reason = ''; Exempt = $false
    }
    if ($fi.Exists) { $a.Hashes = @{ SHA1 = $fi.Sha1; SHA256 = $fi.Sha256; SHA512 = $fi.Sha512 } }
    foreach ($n in $fi.Nested) { [void]$a.Nested.Add(@{ Name = $n[0]; Hashes = @{ SHA1 = $n[1]; SHA256 = $n[2]; SHA512 = $n[3] } }) }
    $script:AnalysisCache[$key] = $a
    return $a
}

function Invoke-JarPrefetch($paths) {
    if (-not $script:FastOK) { return }
    $todo = New-Object System.Collections.Generic.List[string]
    $keys = New-Object System.Collections.Generic.List[string]
    $seen = New-Object System.Collections.Generic.HashSet[string]
    foreach ($p in $paths) {
        if (-not $p) { continue }
        $k = Get-PathKey $p
        if ($script:AnalysisCache.ContainsKey($k) -or -not $seen.Add($k)) { continue }
        $todo.Add([string]$p); $keys.Add($k)
    }
    if ($todo.Count -eq 0) { return }
    $res = [P1Fast]::AnalyzeMany([string[]]$todo.ToArray(), 4)
    for ($i = 0; $i -lt $todo.Count; $i++) { [void](Register-FastAnalysis $todo[$i] $keys[$i] $res[$i]) }
}

function Get-JarAnalysis([string]$path) {
    $key = Get-PathKey $path
    if ($script:AnalysisCache.ContainsKey($key)) { return $script:AnalysisCache[$key] }
    if ($script:FastOK) { return (Register-FastAnalysis $path $key ([P1Fast]::AnalyzeJar($path))) }
    $a = [PSCustomObject]@{
        Path = $path; Exists = $false; Hashes = $null; Parsed = $false; Error = $null
        Classes = (New-Object System.Collections.Generic.HashSet[string])
        Nested = (New-Object System.Collections.Generic.List[object])
        Tier = 'NONE'; Reason = ''; Exempt = $false
    }
    try {
        $fs = [IO.File]::Open($path, [IO.FileMode]::Open, [IO.FileAccess]::Read, ([IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete))
        try {
            $ms0 = New-Object System.IO.MemoryStream
            $fs.CopyTo($ms0)
            $bytes = $ms0.ToArray()
            $ms0.Dispose()
        } finally { $fs.Dispose() }
        $a.Exists = $true
        $a.Hashes = Get-BytesHashes $bytes
        try {
            $zip = New-Object System.IO.Compression.ZipArchive((New-Object System.IO.MemoryStream(,$bytes)), [System.IO.Compression.ZipArchiveMode]::Read)
            Read-ZipEntries $zip 0 $a
            $zip.Dispose()
            $a.Parsed = $true
        } catch { $a.Error = "not parseable by strict zip reader: $($_.Exception.Message)" }
    } catch { $a.Error = $_.Exception.Message }
    $script:AnalysisCache[$key] = $a
    return $a
}

function Find-HashHit($hashes) {
    if (-not $hashes) { return $null }
    $best = $null
    foreach ($alg in 'SHA1','SHA256','SHA512') {
        $e = $script:Verified[$hashes[$alg]]
        if ($e) {
            if ($e.Tier -eq 'OFFICIAL') { return $e }
            if (-not $best -or ($best.Tier -eq 'LOCAL' -and $e.Tier -eq 'BADLOCAL')) { $best = $e }
        }
    }
    return $best
}

function Resolve-JarTiers {
    $changed = $true
    $rounds = 0
    while ($changed -and $rounds -lt 5) {
        $changed = $false
        $rounds++
        foreach ($a in @($script:AnalysisCache.Values)) {
            if (-not $a.Exists -or $a.Tier -eq 'OFFICIAL') { continue }
            $hit = Find-HashHit $a.Hashes
            if ($hit -and $hit.Tier -ne $a.Tier) {
                $a.Tier = $hit.Tier
                $a.Reason = $hit.Reason
                $a.Exempt = [bool]$hit.Exempt
                $changed = $true
                $leaf = Split-Path $a.Path -Leaf
                $nestWhy = if ($a.Tier -eq 'OFFICIAL') { "embedded in verified jar $leaf" } else { "embedded in $leaf ($($a.Reason))" }
                foreach ($n in $a.Nested) { Register-AllHashes $n.Hashes $a.Tier $nestWhy $true }
            }
        }
    }
}

function Update-VerifiedClasses {
    foreach ($a in @($script:AnalysisCache.Values)) {
        if ($a.Tier -eq 'OFFICIAL') {
            $script:VerifiedClasses.UnionWith($a.Classes)
        }
    }
}

function Get-VersionJsonHashes($j, [string]$label) {
    $out = New-Object System.Collections.Generic.List[object]
    if (-not $j) { return ,$out }
    if ($j.downloads -and $j.downloads.client -and $j.downloads.client.sha1) {
        $out.Add(@{ Hash = "$($j.downloads.client.sha1)"; What = "$label client jar" })
    }
    foreach ($l in @($j.libraries)) {
        if (-not $l) { continue }
        $nm = "$($l.name)"
        if ($l.downloads -and $l.downloads.artifact -and $l.downloads.artifact.sha1) {
            $out.Add(@{ Hash = "$($l.downloads.artifact.sha1)"; What = "$label library $nm" })
        }
        if ($l.downloads -and $l.downloads.classifiers) {
            foreach ($p in $l.downloads.classifiers.PSObject.Properties) {
                if ($p.Value -and $p.Value.sha1) { $out.Add(@{ Hash = "$($p.Value.sha1)"; What = "$label library $nm ($($p.Name))" }) }
            }
        }
        foreach ($f in 'sha1','sha256','sha512') {
            if ($l.PSObject.Properties[$f] -and $l.$f) { $out.Add(@{ Hash = "$($l.$f)"; What = "$label library $nm" }) }
        }
    }
    return ,$out
}

function Add-VersionJsonHashes($j, [string]$tier, [string]$label) {
    foreach ($h in (Get-VersionJsonHashes $j $label)) { Register-Hash $h.Hash $tier $h.What }
}

function Get-VersionChain([string]$versionId, $versionFolders) {
    $chain = @()
    $seen = @{}
    $cur = $versionId
    while ($cur -and -not $seen[$cur]) {
        $seen[$cur] = $true
        $found = $null
        foreach ($vf in $versionFolders) {
            $p = Join-Path $vf "$cur\$cur.json"
            if (Test-Path -LiteralPath $p -ErrorAction SilentlyContinue) { $found = $p; break }
        }
        if (-not $found) { break }
        try { $j = Get-Content -Raw -LiteralPath $found | ConvertFrom-Json } catch { break }
        $chain += @{ Id = $cur; Json = $j; Path = $found }
        $cur = $j.inheritsFrom
    }
    return $chain
}

function Get-McVersionCandidates([string]$cmdText, $cpEntries) {
    $c = New-Object System.Collections.Generic.List[string]
    if ($cmdText -match '--version\s+"?([^\s"]+)') { $c.Add($Matches[1]) }
    foreach ($e in $cpEntries) {
        if ($e -match '[\\/]versions[\\/]([^\\/]+)[\\/]\1\.jar$') { $c.Add($Matches[1]) }
        if ($e -match 'minecraft-(\d[^\\/]*?)-client\.jar$') { $c.Add($Matches[1]) }
        if ($e -match '[\\/]com[\\/]mojang[\\/]minecraft[\\/]([^\\/]+)[\\/]') { $c.Add($Matches[1]) }
    }
    return @($c | Select-Object -Unique)
}

$StaffTrustedHashes = @(
    'f292d43848e7aa09963dff0946cd1e0edbd778a6a0aa759bf4b387749a631712'
)

function Import-StaffHashFile {
    $dir = if ($PSScriptRoot) { $PSScriptRoot } else { $env:TEMP }
    $p = Join-Path $dir "trusted-hashes.txt"
    if (Test-Path -LiteralPath $p -ErrorAction SilentlyContinue) {
        Write-Warn "Ignoring a pre-existing trusted-hashes.txt - only the list built into this script is trusted"
        Remove-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue
    }
    if (@($StaffTrustedHashes).Count -eq 0) { return 0 }
    $n = 0
    try {
        [IO.File]::WriteAllLines($p, [string[]]@($StaffTrustedHashes), (New-Object System.Text.UTF8Encoding($false)))
        foreach ($line in [IO.File]::ReadAllLines($p)) {
            $t = ($line -replace '#.*$', '').Trim()
            if ($t -match '^[0-9a-fA-F]{40,128}$') { Register-Hash $t 'OFFICIAL' 'staff allow-list (built into this script)'; $n++ }
        }
    } catch {
        Write-Warn "Could not write/read trusted-hashes.txt: $($_.Exception.Message)"
    } finally {
        Remove-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue
    }
    return $n
}

$script:IntermediaryClasses = New-Object System.Collections.Generic.HashSet[string]
$script:IntermediaryLoaded = New-Object System.Collections.Generic.HashSet[string]
function Import-IntermediaryMappings {
    foreach ($a in @($script:AnalysisCache.Values)) {
        if (-not $a.Exists -or $a.Tier -ne 'OFFICIAL' -or $a.Reason -like 'mods folder jar*') { continue }
        if ((Split-Path $a.Path -Leaf) -notmatch '^intermediary-.+\.jar$') { continue }
        if (-not $script:IntermediaryLoaded.Add((Get-PathKey $a.Path))) { continue }
        try {
            $zip = [IO.Compression.ZipFile]::OpenRead($a.Path)
            try {
                $e = $zip.GetEntry('mappings/mappings.tiny')
                if ($e) {
                    $sr = New-Object IO.StreamReader($e.Open())
                    try {
                        while ($null -ne ($l = $sr.ReadLine())) {
                            if ($l.StartsWith("CLASS`t") -or $l.StartsWith("c`t")) {
                                $parts = $l.Split([char]9)
                                if ($parts.Length -ge 3) { [void]$script:IntermediaryClasses.Add($parts[2].Replace('/', '.')) }
                            }
                        }
                    } finally { $sr.Dispose() }
                }
            } finally { $zip.Dispose() }
        } catch {}
    }
    if ($script:FastOK) { [P1Fast]::Intermediary = $script:IntermediaryClasses }
}

$KnownRemapDigests = @{
}
$script:RemapDigestCache = @{}
function Get-RemapDigestInfo([string]$path) {
    $k = Get-PathKey $path
    if ($script:RemapDigestCache.ContainsKey($k)) { return $script:RemapDigestCache[$k] }
    $key = ((Split-Path (Split-Path $path -Parent) -Leaf) -replace '^(minecraft-.+)-[^-]+$', '$1') + '/' + (Split-Path $path -Leaf)
    $info = @{ Key = $key; Digest = $null; State = '' }
    if ($script:FastOK) {
        try { $info.Digest = [P1Fast]::ContentDigest($path) } catch { $info.Digest = $null }
        if ($info.Digest -and $KnownRemapDigests.ContainsKey($key)) {
            $info.State = if (@($KnownRemapDigests[$key]) -contains $info.Digest) { 'match' } else { 'mismatch' }
        }
    }
    $script:RemapDigestCache[$k] = $info
    return $info
}

$DerivedGraceSec = 180
function Test-LateDerived($st) {
    if (-not $st.Stamp -or $script:JvmStartUtc -eq [datetime]::MaxValue) { return $false }
    return ($st.Stamp -gt $script:JvmStartUtc.AddSeconds($DerivedGraceSec))
}

function Import-MetadataForProcess($cmdText, $cpEntries, $versionFolders) {
    $mcCands = New-Object System.Collections.Generic.List[string]
    foreach ($c in (Get-McVersionCandidates $cmdText $cpEntries)) { $mcCands.Add($c) }
    $clientJars = New-Object System.Collections.Generic.List[string]

    $chainAll = New-Object System.Collections.Generic.List[object]
    $officialById = @{}
    foreach ($id in @($mcCands)) {
        foreach ($c in (Get-VersionChain $id $versionFolders)) {
            $chainAll.Add($c)
            if (-not $mcCands.Contains($c.Id)) { $mcCands.Add($c.Id) }
            $jp = Join-Path (Split-Path $c.Path -Parent) "$($c.Id).jar"
            if (Test-Path -LiteralPath $jp -ErrorAction SilentlyContinue) { $clientJars.Add($jp) }
        }
    }

    $man = Invoke-Json "https://piston-meta.mojang.com/mc/game/version_manifest_v2.json"
    $okIds = @()
    if ($man) {
        $script:OnlineOK = $true
        foreach ($id in $mcCands) {
            $entry = $man.versions | Where-Object { $_.id -eq $id } | Select-Object -First 1
            if (-not $entry) { continue }
            $vj = Invoke-Json $entry.url
            if ($vj) { Add-VersionJsonHashes $vj 'OFFICIAL' "mojang $id"; $okIds += $id; $officialById[$id] = $vj }
        }
        foreach ($e in $cpEntries) {
            $leaf = Split-Path $e -Leaf
            if ($leaf -match '^(fabric|quilt)-loader-(.+)\.jar$') {
                $kind = $Matches[1]; $lv = $Matches[2]
                foreach ($mc in $okIds) {
                    $u = if ($kind -eq 'fabric') { "https://meta.fabricmc.net/v2/versions/loader/$mc/$lv/profile/json" } else { "https://meta.quiltmc.org/v3/versions/loader/$mc/$lv/profile/json" }
                    $pj = Invoke-Json $u
                    if ($pj) {
                        Add-VersionJsonHashes $pj 'OFFICIAL' "$kind meta (loader $lv)"
                        if ($pj.id) { $officialById["$($pj.id)"] = $pj }
                        break
                    }
                }
            }
        }
    }
    $chainSeen = @{}
    foreach ($c in $chainAll) {
        if ($chainSeen[$c.Path]) { continue }
        $chainSeen[$c.Path] = $true
        $localHashes = Get-VersionJsonHashes $c.Json "local launcher metadata ($($c.Id))"
        $off = $officialById[$c.Id]
        if ($off) {
            $offSet = New-Object System.Collections.Generic.HashSet[string]
            foreach ($h in (Get-VersionJsonHashes $off '')) { [void]$offSet.Add($h.Hash.ToLower()) }
            foreach ($h in $localHashes) {
                if (-not $offSet.Contains($h.Hash.ToLower())) {
                    Register-Hash $h.Hash 'BADLOCAL' "local metadata lists an entry the official $($c.Id) metadata does not ($($h.What)) - attested only by $($c.Path)"
                }
            }
        } else {
            foreach ($h in $localHashes) { Register-Hash $h.Hash 'LOCAL' "$($h.What) - attested only by $($c.Path)" }
        }
    }
    return @{ ClientJars = @($clientJars | Select-Object -Unique); OfficialIds = $okIds }
}

$script:LookupTried = New-Object System.Collections.Generic.HashSet[string]

function Get-ManyText([string[]]$urls, [int]$timeout = 10) {
    $out = New-Object 'string[]' $urls.Count
    if ($urls.Count -eq 0) { return ,$out }
    if ($script:FastOK) {
        try { $fast = [P1Fast]::GetMany($urls, 24, $timeout, [string]$script:HttpHeaders['User-Agent']); return ,$fast } catch {}
    }
    for ($i = 0; $i -lt $urls.Count; $i++) {
        try {
            $r = Invoke-WebRequest -Uri $urls[$i] -Headers $script:HttpHeaders -TimeoutSec $timeout -UseBasicParsing -ErrorAction Stop
            $c = $r.Content
            if ($c -is [byte[]]) { $c = [Text.Encoding]::ASCII.GetString($c) }
            $out[$i] = [string]$c
        } catch {}
    }
    return ,$out
}

function Invoke-ModrinthLookup {
    $pending = @($script:AnalysisCache.Values | Where-Object { $_.Exists -and $_.Tier -ne 'OFFICIAL' -and $_.Hashes -and $script:LookupTried.Add("mr:" + $_.Hashes.SHA512) })
    if ($pending.Count -eq 0) { return }
    for ($i = 0; $i -lt $pending.Count; $i += 100) {
        $chunk = @($pending[$i..([Math]::Min($i + 99, $pending.Count - 1))])
        $body = ConvertTo-Json -InputObject @{ hashes = @($chunk | ForEach-Object { $_.Hashes.SHA512 }); algorithm = 'sha512' } -Depth 3
        try {
            $res = Invoke-RestMethod -Method Post -Uri "https://api.modrinth.com/v2/version_files" -ContentType "application/json" -Body $body -Headers $script:HttpHeaders -TimeoutSec 20 -ErrorAction Stop
        } catch { continue }
        if (-not $res) { continue }
        foreach ($prop in $res.PSObject.Properties) {
            $h = $prop.Name.ToLower()
            $ver = $prop.Value
            $ok = $false
            foreach ($f in @($ver.files)) { if ($f.hashes.sha512 -and $f.hashes.sha512.ToLower() -eq $h) { $ok = $true } }
            if ($ok) { Register-Hash $h 'OFFICIAL' "modrinth (project $($ver.project_id), version $($ver.version_number))" }
        }
    }
}

function Invoke-RepoSha1Lookup {
    $pending = @($script:AnalysisCache.Values | Where-Object { $_.Exists -and $_.Tier -ne 'OFFICIAL' -and $_.Hashes })
    $urls = New-Object System.Collections.Generic.List[string]
    foreach ($a in $pending) {
        $p = $a.Path -replace '\\', '/'
        $i = $p.IndexOf('/libraries/')
        if ($i -lt 0) { continue }
        $segs = $p.Substring($i + 11).Split('/')
        if ($segs.Count -lt 4) { continue }
        $leaf = $segs[$segs.Count - 1]; $ver = $segs[$segs.Count - 2]; $artifact = $segs[$segs.Count - 3]
        $groupPath = ($segs[0..($segs.Count - 4)]) -join '/'
        if ($leaf -notlike "$artifact-$ver*.jar") { continue }
        $repos = New-Object System.Collections.Generic.List[string]
        $repos.Add('https://repo1.maven.org/maven2')
        if ($groupPath -like 'net/fabricmc*') { $repos.Add('https://maven.fabricmc.net') }
        if ($groupPath -like 'org/quiltmc*') { $repos.Add('https://maven.quiltmc.org/repository/release') }
        foreach ($r in $repos) {
            $u = "$r/$groupPath/$artifact/$ver/$leaf.sha1"
            if ($script:LookupTried.Add("repo:$u")) { $urls.Add($u) }
        }
    }
    if ($urls.Count -eq 0) { return }
    $res = Get-ManyText ([string[]]$urls.ToArray()) 10
    for ($k = 0; $k -lt $urls.Count; $k++) {
        if ($k -ge $res.Count -or -not $res[$k]) { continue }
        $h = ("$($res[$k])").Trim()
        if ($h.Length -ge 40) { $h = $h.Substring(0, 40) }
        if ($h -match '^[0-9a-fA-F]{40}$') {
            $coord = $urls[$k] -replace '^https://[^/]+/(maven2/|repository/release/)?', ''
            Register-Hash $h 'OFFICIAL' "maven repo ($coord)"
        }
    }
}

function Invoke-MavenLookup {
    $modsKey = $null
    if ($instanceFolders -and $instanceFolders.Mods) { $modsKey = (Get-PathKey $instanceFolders.Mods).TrimEnd('\') + '\' }
    $pending = @($script:AnalysisCache.Values | Where-Object {
        $_.Exists -and $_.Tier -ne 'OFFICIAL' -and $_.Hashes -and
        ($_.Path -notmatch '[\\/]\.(fabric|quilt)[\\/]') -and
        ($_.Path -notmatch 'NewLaunch\.jar$') -and
        (-not $modsKey -or -not (Get-PathKey $_.Path).StartsWith($modsKey)) -and
        $script:LookupTried.Add("mvn:" + $_.Hashes.SHA1)
    })
    $pending = @($pending | Select-Object -First 30)
    if ($pending.Count -eq 0) { return }
    $urls = [string[]]@($pending | ForEach-Object { "https://search.maven.org/solrsearch/select?q=1:%22{0}%22&rows=1&wt=json" -f $_.Hashes.SHA1 })
    $res = Get-ManyText $urls 12
    for ($i = 0; $i -lt $pending.Count; $i++) {
        if ($i -ge $res.Count -or -not $res[$i]) { continue }
        try { $r = $res[$i] | ConvertFrom-Json } catch { continue }
        if ($r -and $r.response -and $r.response.numFound -gt 0) {
            Register-Hash $pending[$i].Hashes.SHA1 'OFFICIAL' "maven central ($($r.response.docs[0].id))"
        }
    }
}

function Get-ProcJavaHome($proc) {
    $javaHome = $null
    try {
        $jvmDll = $proc.Modules | Where-Object { $_.ModuleName -ieq 'jvm.dll' } | Select-Object -First 1
        if ($jvmDll -and $jvmDll.FileName) {
            $c = Split-Path (Split-Path (Split-Path $jvmDll.FileName -Parent) -Parent) -Parent
            if (Test-Path (Join-Path $c "lib") -ErrorAction SilentlyContinue) { $javaHome = $c }
        }
    } catch {}
    if (-not $javaHome) {
        try { if ($proc -and $proc.Path) { $javaHome = Split-Path (Split-Path $proc.Path -Parent) -Parent } } catch {}
    }
    return $javaHome
}

function Import-JdkClasses([string]$jimagePath, [string]$javaHome) {
    $count = 0
    $modulesImage = $null
    if ($javaHome) { $c = Join-Path $javaHome "lib\modules"; if (Test-Path $c -ErrorAction SilentlyContinue) { $modulesImage = $c } }
    if (-not $modulesImage -and $jimagePath) {
        $jh = Split-Path (Split-Path $jimagePath -Parent) -Parent
        $c = Join-Path $jh "lib\modules"
        if (Test-Path $c -ErrorAction SilentlyContinue) { $modulesImage = $c }
    }
    if ($modulesImage -and $jimagePath -and (Test-Path $jimagePath -ErrorAction SilentlyContinue)) {
        $prev = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
        try { $raw = & $jimagePath list $modulesImage 2>&1 } catch { $raw = @() } finally { $ErrorActionPreference = $prev }
        $jimDone = $false
        if ($script:FastOK) {
            try { $count += [P1Fast]::ParseJimage([string[]]@($raw), $script:JdkClasses); $jimDone = $true } catch { $jimDone = $false }
        }
        if (-not $jimDone) {
            foreach ($line in $raw) {
                $t = "$line".Trim()
                if (-not $t -or $t.StartsWith("Module:") -or -not $t.EndsWith(".class")) { continue }
                if ($t -eq "module-info.class") { continue }
                [void]$script:JdkClasses.Add((($t.Substring(0, $t.Length - 6)) -replace '/', '.'))
                $count++
            }
        }
    }

    if ($javaHome) {
        $jars = @()
        foreach ($d in @((Join-Path $javaHome "lib"), (Join-Path $javaHome "jre\lib"))) {
            if (Test-Path $d -ErrorAction SilentlyContinue) {
                $jars += Get-ChildItem -LiteralPath $d -Filter "*.jar" -File -ErrorAction SilentlyContinue
                $ext = Join-Path $d "ext"
                if (Test-Path $ext -ErrorAction SilentlyContinue) { $jars += Get-ChildItem -LiteralPath $ext -Filter "*.jar" -File -ErrorAction SilentlyContinue }
            }
        }
        foreach ($j in ($jars | Where-Object { $_.Name -match '^(rt|jce|jsse|charsets|resources|jfr|jfxrt|nashorn|sunjce_provider|sunec|localedata|cldrdata|dnsns|zipfs)\.jar$' })) {
            $a = Get-JarAnalysis $j.FullName
            $script:JdkClasses.UnionWith($a.Classes); $count += $a.Classes.Count
        }
    }
    return $count
}

$script:JdkSets = @{}
$script:JdkKey = ''
function Select-JdkClasses($proc) {
    $jh = Get-ProcJavaHome $proc
    $key = if ($jh) { $jh.TrimEnd('\').ToLower() } else { '(unknown java home)' }
    if (-not $script:JdkSets.ContainsKey($key)) {
        $script:JdkClasses = New-Object System.Collections.Generic.HashSet[string]
        [void](Import-JdkClasses $jimage $jh)
        $script:JdkSets[$key] = $script:JdkClasses
    }
    $script:JdkClasses = $script:JdkSets[$key]
    $script:JdkKey = $key
    return $script:JdkClasses.Count
}

function Get-JcmdText([string]$jcmdPath, [int]$pidNum, [string]$command) {
    $prev = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    try {
        $raw = & $jcmdPath $pidNum $command 2>&1
        return (($raw | ForEach-Object { "$_" }) -join "`n")
    } catch { return "" } finally { $ErrorActionPreference = $prev }
}

function Get-JvmPropertyValue([string]$propsText, [string]$key) {
    if (-not $propsText) { return $null }
    $lines = $propsText -split "`r?`n"
    $joined = New-Object System.Collections.Generic.List[string]
    $buffer = $null
    foreach ($line in $lines) {
        $buffer = if ($null -ne $buffer) { $buffer + $line } else { $line }
        if ($buffer -match '(?<!\\)(\\\\)*\\$') { $buffer = $buffer.Substring(0, $buffer.Length - 1); continue }
        $joined.Add($buffer)
        $buffer = $null
    }
    if ($buffer) { $joined.Add($buffer) }
    $pat = '^\s*' + [regex]::Escape($key) + '\s*='
    $l = $joined | Where-Object { $_ -match $pat } | Select-Object -First 1
    if (-not $l) { return $null }
    $v = $l -replace $pat, ''
    return ($v -replace '\\:', ':' -replace '\\=', '=' -replace '\\\\', '\')
}

function Split-PathList([string]$value) {
    if (-not $value) { return @() }
    return @(($value -split [regex]::Escape([IO.Path]::PathSeparator)) | Where-Object { $_ -and $_.Trim() -ne '' })
}

$JvmFlagPatterns = @(
    @('-javaagent:',                         'java agent loaded at startup'),
    @('-agentlib:',                          'native/JVMTI agent (agentlib)'),
    @('-agentpath:',                         'native/JVMTI agent (agentpath)'),
    @('Xbootclasspath',                      'bootclasspath modified'),
    @('jdk\.boot\.class\.path\.append',      'bootstrap classpath appended'),
    @('--patch-module',                      'module patching'),
    @('DisableAttachMechanism',              'attach mechanism disabled'),
    @('Xverify:none|BytecodeVerification|noverify', 'bytecode verification disabled'),
    @('jdk\.attach\.allowAttachSelf',        'self-attach allowed')
)
function Get-JvmFlagFindings([string]$cmdText, [string]$propsText) {
    $f = New-Object System.Collections.Generic.List[string]
    foreach ($p in $JvmFlagPatterns) {
        if ($cmdText -match $p[0] -or $propsText -match $p[0]) { $f.Add("$($p[1])  (matched: $($p[0]))") }
    }
    return $f
}
function Get-JavaAgentPaths([string]$cmdText) {
    $paths = New-Object System.Collections.Generic.List[string]
    foreach ($m in [regex]::Matches($cmdText, '-javaagent:(?:"([^"]+)"|((?:(?! -).)+?\.jar(?=[=\s"]|$))|([^\s=]+))', 'IgnoreCase')) {
        $p = ($m.Groups[1].Value + $m.Groups[2].Value + $m.Groups[3].Value).Trim('"')
        if ($p -and -not $paths.Contains($p)) { $paths.Add($p) }
    }
    return $paths
}

function Extract-ClassNames($rawText) {
    if ($script:FastOK) { return [P1Fast]::ExtractClassNames([string]$rawText) }
    $found = New-Object System.Collections.Generic.HashSet[string]
    $pattern = '(?:[a-zA-Z_$][a-zA-Z0-9_$-]*\.)+[a-zA-Z_$-][a-zA-Z0-9_$-]*'
    foreach ($line in ($rawText -split "`r?`n")) {
        if ($line -match 'unique loaded classes' -or $line -match '^COMMAND' -or
            $line -match '^PROCESS' -or $line -match '^EXE' -or $line -match '^\u2501+$') { continue }
        $clean = $line -replace '@[0-9a-fA-F]+', ''
        $clean = $clean -replace '\[+L([a-zA-Z_$][a-zA-Z0-9_$.-]*);', '$1'
        foreach ($m in [regex]::Matches($clean, $pattern)) {
            [void]$found.Add($m.Value)
        }
    }
    return $found
}

function Get-BaseClassName([string]$n) {
    return $script:RxBaseLam.Replace($script:RxBaseHex.Replace($n, ''), '')
}

function Test-LoaderHas([string]$cls, [string]$loader) {
    if (-not $script:LoadersByName) { return $false }
    $ls = $script:LoadersByName[$cls]
    return [bool]($ls -and $ls.Contains($loader))
}

function Test-MixinArgs([string]$b) {
    return ($b -cmatch '^org\.spongepowered\.asm\.synthetic\.args\.Args\$\d+$' -and $script:VerifiedClasses.Contains('org.spongepowered.asm.mixin.injection.invoke.arg.Args'))
}

function Test-IntermediaryOrGenerated([string]$b) {
    if ($b -cmatch '^jdk\.internal\.vm\.Filler(Object|Element)$') { return $true }
    if (Test-MixinArgs $b) { return $true }
    if ($b -cmatch '^com\.llamalad7\.mixinextras\.sugar\.impl\.ref\.generated\.[A-Za-z0-9_]+$' -and $script:VerifiedClasses.Contains('com.llamalad7.mixinextras.MixinExtrasBootstrap')) { return $true }
    if ($script:IntermediaryClasses.Contains($b)) { return $true }
    $outer = $b -creplace '\$Anonymous\$[0-9a-f]{32}$', ''
    if ($outer -cne $b -and ($script:VerifiedClasses.Contains($outer) -or $script:JdkClasses.Contains($outer) -or $script:IntermediaryClasses.Contains($outer))) { return $true }
    return $false
}

function Test-KnownByName([string]$name) {
    if ($name -match '^\[+L(.+);$') { $name = $Matches[1] }
    $b = Get-BaseClassName $name
    if ($script:VerifiedClasses.Contains($b) -or $script:JdkClasses.Contains($b)) { return $true }
    if ($b -match $ProxyPattern -or $b -match $AccessorPattern -or $b -match $JdkSpunPattern) { return $true }
    if (Test-IntermediaryOrGenerated $b) { return $true }
    return $false
}

function ConvertFrom-CodeSourceUrl([string]$url) {
    if (-not $url -or $url -eq "NONE" -or $url -eq "ERROR") { return $null }
    if ($url.StartsWith("jrt:")) { return @{ Type = "JRT"; Path = $url } }
    $inner = $url
    $isUnion = $false
    $isJar = $false
    if ($inner.StartsWith("jar:")) { $inner = $inner.Substring(4); $isJar = $true }
    elseif ($inner.StartsWith("union:")) { $inner = "file:" + $inner.Substring(6); $isUnion = $true }
    $bang = -1
    if ($isJar -or $isUnion) {
        $bang = $inner.IndexOf("!/")
        if ($bang -lt 0 -and $inner.EndsWith("!")) { $bang = $inner.Length - 1 }
    }
    if ($bang -ge 0) { $inner = $inner.Substring(0, $bang) }
    if ($isUnion) { $h = $inner.IndexOf('%23'); if ($h -ge 0) { $inner = $inner.Substring(0, $h) } }
    if ($inner.StartsWith("file:")) {
        try { return @{ Type = "FILE"; Path = ([Uri]$inner).LocalPath } } catch { return @{ Type = "OTHER"; Path = $url } }
    }
    return @{ Type = "OTHER"; Path = $url }
}

function Test-InRemapCacheRaw([string]$path, $remapFolders) {
    foreach ($f in @($remapFolders)) {
        if (-not $f) { continue }
        $full = ([IO.Path]::GetFullPath($f)).TrimEnd('\') + '\'
        if ($path.StartsWith($full, [StringComparison]::OrdinalIgnoreCase)) { return $true }
    }
    return $false
}

function Test-InRemapCache([string]$path, $remapFolders) {
    if ($script:RemapCache.ContainsKey($path)) { return $script:RemapCache[$path] }
    $r = [bool](Test-InRemapCacheRaw $path $remapFolders)
    $script:RemapCache[$path] = $r
    return $r
}

function Get-JarFileState([string]$path) {
    if ($script:StateCache.ContainsKey($path)) { return $script:StateCache[$path] }
    $k = Get-PathKey $path
    if ($script:StateCache.ContainsKey($k)) { return $script:StateCache[$k] }
    $st = @{ IsDir = $false; Missing = $false; Late = $false; Reparse = $false; Stamp = $null }
    try {
        if (Test-Path -LiteralPath $path -PathType Container) { $st.IsDir = $true }
        elseif (-not (Test-Path -LiteralPath $path -PathType Leaf)) { $st.Missing = $true }
        else {
            $item = Get-Item -LiteralPath $path -Force
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { $st.Reparse = $true }
            $t = $item.LastWriteTimeUtc
            if ($item.CreationTimeUtc -gt $t) { $t = $item.CreationTimeUtc }
            $st.Stamp = $t
            if ($t -gt $script:JvmStartUtc) { $st.Late = $true }
        }
    } catch { $st.Missing = $true }
    $script:StateCache[$k] = $st
    $script:StateCache[$path] = $st
    return $st
}

function New-Verdict([string]$tier, [string]$reason, [string]$jar = '') {
    return [PSCustomObject]@{ Tier = $tier; Reason = $reason; Jar = $jar }
}

function Get-ClassVerdict($rec, $remapFolders) {
    $name = $rec.Name
    if ($name -match '^\[+[BCDFIJSZ]$') { return (New-Verdict 'Generated' 'primitive array type (JVM-synthesized)') }
    if ($name -match '^\[+L(.+);$') { $name = $Matches[1] }
    $base = Get-BaseClassName $name
    $stripped = ($base -ne $name)
    $csKey = [string]$rec.CodeSource
    if ($script:LocCache.ContainsKey($csKey)) { $loc = $script:LocCache[$csKey] }
    else { $loc = ConvertFrom-CodeSourceUrl $csKey; $script:LocCache[$csKey] = $loc }

    $isBoot = ($rec.Loader -eq 'BOOTSTRAP' -or $rec.Loader -match 'ClassLoaders\$PlatformClassLoader')
    $ldr = [string]$rec.Loader
    $hidOk = if ($script:HiddenSupported) { $rec.Hidden -eq 'true' } else { $script:RxBaseHex.IsMatch($name) }
    $trustedLoader = ($script:VerifiedClasses.Contains($ldr) -or $script:JdkClasses.Contains($ldr))
    $mxOk0 = $script:VerifiedClasses.Contains('com.llamalad7.mixinextras.MixinExtrasBootstrap')
    $mxLdOk = Test-LoaderHas 'com.llamalad7.mixinextras.MixinExtrasBootstrap' $ldr
    $argsLdOk = ((Test-LoaderHas 'org.spongepowered.asm.mixin.injection.invoke.arg.Args' $ldr) -or $trustedLoader)
    $isMxName = ($base -match '^com\.llamalad7\.mixinextras\.sugar\.impl\.ref\.generated\.')
    $isMxGen = (($mxOk0 -and $mxLdOk -and $isMxName) -or ($argsLdOk -and (Test-MixinArgs $base)))
    if ($isBoot -or ($loc -and $loc.Type -eq 'JRT')) {
        if ($script:JdkClasses.Count -eq 0) { return (New-Verdict 'Unverified' 'JDK runtime image could not be indexed (jimage/rt.jar unavailable)') }
        if ($script:JdkClasses.Contains($base) -and (-not $stripped -or $hidOk -or $script:JdkClasses.Contains($name))) { return (New-Verdict 'Verified' 'present in this JVM runtime image') }
        if ($base -match $JdkSpunPattern) { return (New-Verdict 'Generated' 'JDK-spun invoke class') }
        if ($base -match $ProxyPattern -or $base -match $AccessorPattern) { return (New-Verdict 'Generated' 'JDK-generated class') }
        if ($base -match '^jdk\.internal\.vm\.Filler(Object|Element)$') { return (New-Verdict 'Generated' 'JVM-internal heap filler class') }
        return (New-Verdict 'Suspicious' 'loaded by bootstrap/platform loader but NOT present in the JDK runtime image (bootclasspath injection?)')
    }

    if (-not $loc -or $loc.Type -ne 'FILE') {
        if ($loc -and $loc.Type -eq 'OTHER') { return (New-Verdict 'Unverified' "codesource is not a local file: $($rec.CodeSource)") }
        if ($rec.CodeSource -eq 'ERROR') { return (New-Verdict 'Suspicious' 'codesource lookup threw an error') }
        if ($base -match $ProxyPattern) {
            if ($rec.Proxy -eq 'true') { return (New-Verdict 'Generated' 'dynamic proxy, confirmed by the JVM (its handler classes are checked on their own)') }
            if ($rec.Proxy -eq 'false') { return (New-Verdict 'Suspicious' 'named like a dynamic proxy but the JVM says it is not a proxy class - spoofed name') }
            if ($base -notmatch 'jdk\.proxy\d+\.' -or $script:JdkClasses.Contains([string]$rec.Loader) -or $script:VerifiedClasses.Contains([string]$rec.Loader)) { return (New-Verdict 'Generated' 'dynamic proxy (its handler classes are checked on their own)') }
            return (New-Verdict 'Unverified' "named like a JDK dynamic proxy (jdk.proxyN) but defined by unverified loader $($rec.Loader) - staff review")
        }
        if ($base -match $AccessorPattern -and $rec.Loader -match '(jdk\.internal|sun)\.reflect\.DelegatingClassLoader') { return (New-Verdict 'Generated' 'reflection accessor') }
        if ($stripped -and ($script:VerifiedClasses.Contains($base) -or $script:JdkClasses.Contains($base))) {
            $ldOk = Test-LoaderHas $base $ldr
            if ($hidOk -and $ldOk) { return (New-Verdict 'Generated' "generated from verified class $base") }
            $whyNot = if (-not $hidOk) { 'it is not a hidden/VM-anonymous class' } else { "it was defined by a different loader than $base" }
            return (New-Verdict 'Unverified' "named like a class generated from $base but $whyNot - staff review")
        }
        $anonOuter = $base -replace '\$Anonymous\$[0-9a-fA-F]{32}$', ''
        if ($anonOuter -ne $base -and ($script:VerifiedClasses.Contains($anonOuter) -or (Test-IntermediaryOrGenerated $anonOuter))) {
            if (Test-LoaderHas $anonOuter $ldr) { return (New-Verdict 'Generated' "Mixin-generated inner class of $anonOuter") }
            return (New-Verdict 'Unverified' "named like a Mixin-generated inner class of $anonOuter but it was defined by a different loader - staff review")
        }
        if ($isMxGen) { return (New-Verdict 'Generated' 'Mixin/MixinExtras runtime-generated class (library jar is verified)') }
        if ($isMxName -or (Test-MixinArgs $base)) { return (New-Verdict 'Unverified' "named like a Mixin/MixinExtras generated class but defined by a loader that did not load that library ($ldr) - staff review") }
        return (New-Verdict 'Unverified' 'in-memory class with no backing file - cannot be verified, staff review')
    }

    $path = $loc.Path
    $st = Get-JarFileState $path
    if ($st.IsDir) { return (New-Verdict 'Unverified' "loaded from a directory (cannot be hash-verified): $path" $path) }
    if ($st.Missing) { return (New-Verdict 'Suspicious' "codesource file no longer exists (deleted after load?): $path" $path) }
    $a = Get-JarAnalysis $path
    if (-not $a.Exists) { return (New-Verdict 'Unverified' "codesource file unreadable: $path ($($a.Error))" $path) }

    $derived = Test-InRemapCache $path $remapFolders
    $late = if ($derived) { [bool](Test-LateDerived $st) } else { [bool]$st.Late }
    if (-not $a.Exempt -and $late) {
        $lateWhat = if ($derived) { 'launcher cache jar was created/modified well AFTER the JVM finished starting' } else { 'jar was created/modified AFTER the JVM started' }
        return (New-Verdict 'Suspicious' "$lateWhat ($($st.Stamp) UTC) - replaced or altered at runtime: $path" $path)
    }
    if ($stripped -and -not $hidOk -and -not $a.Classes.Contains($name)) {
        return (New-Verdict 'Unverified' "named like a lambda/hidden class of $base but it is not a hidden class - staff review: $path" $path)
    }
    $note = if ($st.Reparse) { ' [file is a symlink/reparse point]' } else { '' }

    if ($a.Tier -eq 'BADLOCAL') { return (New-Verdict 'Suspicious' "$($a.Reason): $path$note" $path) }

    if ($a.Tier -eq 'OFFICIAL' -or $a.Tier -eq 'LOCAL') {
        $tierName = if ($a.Tier -eq 'OFFICIAL') { 'Verified' } else { 'Weak' }
        if (-not $a.Parsed) { return (New-Verdict $tierName "$($a.Reason) (jar not strict-parseable; class presence unchecked)$note" $path) }
        if (-not $a.Classes.Contains($base) -and $isMxGen) { return (New-Verdict 'Generated' 'Mixin/MixinExtras runtime-generated class (library jar is verified)' $path) }
        if (-not $a.Classes.Contains($base)) {
            return (New-Verdict 'Suspicious' "claims to come from verified jar ($($a.Reason)) but that jar does not contain this class - forged codesource or jar swapped: $path" $path)
        }
        return (New-Verdict $tierName "$($a.Reason)$note" $path)
    }

    if ($derived) {
        if (-not $a.Parsed) { return (New-Verdict 'Unverified' "launcher-cache jar not strict-parseable: $path" $path) }
        if (-not $a.Classes.Contains($base) -and $isMxGen) { return (New-Verdict 'Generated' 'Mixin/MixinExtras runtime-generated class (library jar is verified)' $path) }
        if (-not $a.Classes.Contains($base)) { return (New-Verdict 'Suspicious' "class not present in the launcher-cache jar it claims to come from: $path" $path) }
        return (New-Verdict 'Unverified' "launcher cache jar cannot be content-checked by the fallback engine - rerun in a new PowerShell window: $path" $path)
    }

    $why = if ($a.Error) { "jar hash not in any database; $($a.Error)" } else { "jar hash not found in Mojang / Fabric / Quilt / Modrinth / Maven Central / staff list" }
    return (New-Verdict 'Unverified' "${why}: $path$note" $path)
}

function New-VerdictContext([string]$csKey, $remapFolders) {
    $c = New-Object P1Ctx
    $loc = ConvertFrom-CodeSourceUrl $csKey
    if (-not $loc) { return $c }
    $c.Kind = [string]$loc.Type
    $c.Path = [string]$loc.Path
    if ($loc.Type -ne 'FILE') { return $c }
    $st = Get-JarFileState $loc.Path
    $c.IsDir = [bool]$st.IsDir; $c.Missing = [bool]$st.Missing; $c.Late = [bool]$st.Late; $c.Reparse = [bool]$st.Reparse
    $c.Stamp = [string]$st.Stamp
    if ($c.IsDir -or $c.Missing) { return $c }
    $a = Get-JarAnalysis $loc.Path
    $c.AExists = [bool]$a.Exists; $c.AParsed = [bool]$a.Parsed; $c.AExempt = [bool]$a.Exempt
    $c.AError = [string]$a.Error; $c.ATier = [string]$a.Tier; $c.AReason = [string]$a.Reason
    $c.Classes = $a.Classes
    $c.Derived = [bool](Test-InRemapCache $loc.Path $remapFolders)
    if ($c.Derived) {
        $c.Late = [bool](Test-LateDerived $st)
        $di = Get-RemapDigestInfo $loc.Path
        $c.DState = [string]$di.State; $c.DKey = [string]$di.Key
    }
    return $c
}

function Build-ProvenanceAgent([string]$javacPath, [string]$jarPath) {
    $ErrorActionPreference = 'Continue'
    $buildDir = Join-Path $env:TEMP "p1ae-provenance"
    New-Item -ItemType Directory -Path $buildDir -Force | Out-Null
    Get-ChildItem -LiteralPath $buildDir -Filter "report_*.tsv" -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

    $agentSrc = Join-Path $buildDir "ProvenanceAgent.java"
    $launcherSrc = Join-Path $buildDir "AttachLauncher.java"
    $manifestPath = Join-Path $buildDir "agent-manifest.mf"
    $agentJarPath = Join-Path $buildDir "provenance-agent-build.jar"

    @'
import java.lang.instrument.Instrumentation;
import java.security.CodeSource;
import java.security.ProtectionDomain;
import java.io.PrintWriter;
import java.io.FileOutputStream;
import java.io.OutputStreamWriter;
import java.nio.charset.StandardCharsets;

public class ProvenanceAgent {
    private static final java.lang.reflect.Method IS_HIDDEN = findIsHidden();
    private static java.lang.reflect.Method findIsHidden() {
        try { return Class.class.getMethod("isHidden"); } catch (Throwable t) { return null; }
    }

    public static void agentmain(String agentArgs, Instrumentation inst) {
        try (PrintWriter out = new PrintWriter(new OutputStreamWriter(new FileOutputStream(agentArgs, false), StandardCharsets.UTF_8), true)) {
            for (Class<?> c : inst.getAllLoadedClasses()) {
                String name;
                try { name = c.getName(); } catch (Throwable t) { continue; }

                Class<?> resolved = c;
                try {
                    while (resolved.isArray()) {
                        Class<?> comp = resolved.getComponentType();
                        if (comp == null) break;
                        resolved = comp;
                    }
                } catch (Throwable t) { resolved = c; }

                ClassLoader loader = resolved.getClassLoader();
                String loaderName = (loader == null) ? "BOOTSTRAP" : loader.getClass().getName();

                String codeSourceLoc = "NONE";
                try {
                    ProtectionDomain pd = resolved.getProtectionDomain();
                    if (pd != null) {
                        CodeSource cs = pd.getCodeSource();
                        if (cs != null && cs.getLocation() != null) {
                            codeSourceLoc = cs.getLocation().toString();
                        }
                    }
                } catch (Throwable t) { codeSourceLoc = "ERROR"; }

                boolean hidden = false, synthetic = false, anon = false;
                try { hidden = IS_HIDDEN != null && Boolean.TRUE.equals(IS_HIDDEN.invoke(resolved)); } catch (Throwable t) {}
                try { synthetic = resolved.isSynthetic(); } catch (Throwable t) {}
                try { anon = resolved.isAnonymousClass(); } catch (Throwable t) {}
                boolean proxy = false;
                try { proxy = java.lang.reflect.Proxy.isProxyClass(resolved); } catch (Throwable t) {}

                out.println(name + "\t" + loaderName + "\t" + codeSourceLoc + "\t" + hidden + "\t" + synthetic + "\t" + anon + "\t" + proxy);
            }
        } catch (Exception e) {
        }
    }
}
'@ | Set-Content -Path $agentSrc -Encoding ASCII

    @'
import com.sun.tools.attach.VirtualMachine;

public class AttachLauncher {
    public static void main(String[] args) throws Exception {
        VirtualMachine vm = VirtualMachine.attach(args[0]);
        try {
            vm.loadAgent(args[1], args[2]);
        } finally {
            vm.detach();
        }
    }
}
'@ | Set-Content -Path $launcherSrc -Encoding ASCII

    "Agent-Class: ProvenanceAgent`r`nCan-Redefine-Classes: false`r`nCan-Retransform-Classes: false`r`n" | Set-Content -Path $manifestPath -Encoding ASCII -NoNewline

    try {
        & $javacPath --release 8 -d $buildDir $agentSrc 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { & $javacPath -d $buildDir $agentSrc 2>&1 | Out-Null }
        if ($LASTEXITCODE -ne 0) { return @{ Success = $false; Reason = "javac failed on the agent (exit $LASTEXITCODE)" } }
        & $javacPath --add-modules jdk.attach -d $buildDir $launcherSrc 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { return @{ Success = $false; Reason = "javac failed on the attach launcher (exit $LASTEXITCODE)" } }
        Push-Location $buildDir
        try {
            if (Test-Path $agentJarPath) { Remove-Item $agentJarPath -Force -ErrorAction SilentlyContinue }
            & $jarPath --create --file $agentJarPath --manifest $manifestPath --date 2000-01-01T00:00:00Z "ProvenanceAgent.class" 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0 -or -not (Test-Path $agentJarPath)) {
                & $jarPath cfm $agentJarPath $manifestPath "ProvenanceAgent.class" 2>&1 | Out-Null
            }
        } finally { Pop-Location }
        if (-not (Test-Path $agentJarPath -ErrorAction SilentlyContinue)) { return @{ Success = $false; Reason = "agent jar build failed" } }
    } catch {
        return @{ Success = $false; Reason = $_.Exception.Message }
    }

    $h = Get-BytesHashes ([IO.File]::ReadAllBytes($agentJarPath))
    $finalJar = Join-Path $buildDir ("provenance-agent-{0}.jar" -f $h['SHA256'].Substring(0, 12))
    $reuse = $false
    if (Test-Path -LiteralPath $finalJar -PathType Leaf -ErrorAction SilentlyContinue) {
        try { $reuse = ((Get-BytesHashes ([IO.File]::ReadAllBytes($finalJar)))['SHA256'] -eq $h['SHA256']) } catch { $reuse = $false }
    }
    if ($reuse) {
        Remove-Item -LiteralPath $agentJarPath -Force -ErrorAction SilentlyContinue
        $agentJarPath = $finalJar
    } else {
        try { Move-Item -LiteralPath $agentJarPath -Destination $finalJar -Force -ErrorAction Stop; $agentJarPath = $finalJar } catch {}
    }
    Register-AllHashes $h 'OFFICIAL' "this tool's own provenance agent (built locally this run)" $true

    return @{ Success = $true; BuildDir = $buildDir; AgentJar = $agentJarPath }
}

function Invoke-ProvenanceAgent([string]$javaPath, [string]$buildDir, [string]$agentJarPath, [int]$pidNum, [string]$outFilePath) {
    $ErrorActionPreference = 'Continue'
    try {
        $errOut = & $javaPath --add-modules jdk.attach -cp $buildDir AttachLauncher $pidNum $agentJarPath $outFilePath 2>&1
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path $outFilePath -ErrorAction SilentlyContinue)) {
            return @{ Success = $false; Error = ($errOut -join " ") }
        }
        return @{ Success = $true }
    } catch {
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

function Import-ProvenanceReport([string]$path) {
    $records = New-Object System.Collections.Generic.List[object]
    if (-not (Test-Path $path -ErrorAction SilentlyContinue)) { return $records }
    foreach ($line in [IO.File]::ReadAllLines($path, [Text.Encoding]::UTF8)) {
        if (-not $line) { continue }
        $parts = $line.Split([char]9)
        if ($parts.Count -lt 6) { continue }
        $records.Add([PSCustomObject]@{
            Name       = $parts[0]
            Loader     = $parts[1]
            CodeSource = $parts[2]
            Hidden     = $parts[3]
            Synthetic  = $parts[4]
            Anon       = $parts[5]
            Proxy      = $(if ($parts.Count -gt 6) { $parts[6] } else { '' })
        })
    }
    return $records
}

$ProvenanceMode = $false
$provenanceAgent = $null
if ($javacExe -and $jarExe -and $javaExe) {
    Write-Section "Provenance agent"
    Write-Info "Building the provenance agent..."
    $provenanceAgent = Build-ProvenanceAgent $javacExe $jarExe
    if ($provenanceAgent.Success) {
        $ProvenanceMode = $true
        Write-Ok "Agent built - class origin will be checked directly against the running JVM"
    } else {
        Write-Warn "Could not build the provenance agent ($($provenanceAgent.Reason)) - falling back to the name-based check only"
    }
} else {
    Write-Host ""
    Write-Dim "javac/jar/java not all found next to this JDK - provenance mode unavailable, using the name-based check only"
}

$jobs = @(
    @{ Cmd = "VM.classloaders show-classes"; Short = "Classloaders-Full"; Title = "VM.classloaders show-classes" },
    @{ Cmd = "VM.classloaders"; Short = "Classloaders-Tree"; Title = "VM.classloaders" }
)
$downloads = Join-Path $env:USERPROFILE "Downloads"
if (-not (Test-Path $downloads)) { $downloads = [Environment]::GetFolderPath("Desktop") }
$stamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
foreach ($j in $jobs) {
    $j.File = Join-Path $downloads ("{0}_{1}.txt" -f $j.Short, $stamp)
    @(
        "P1ae's Classloader Dump"
        "Command  : jcmd <pid> $($j.Title)"
        "Date     : $(Get-Date)"
        "Machine  : $env:COMPUTERNAME   User: $env:USERNAME"
        ($gBar * 60)
    ) -join "`r`n" | Set-Content -Path $j.File -Encoding UTF8
}
$UnknownFile = Join-Path $downloads ("Classloaders-Unknown_{0}.txt" -f $stamp)
@(
    "P1ae's Classloader Dump - UNKNOWN CLASSES REPORT (name-based, weaker than the provenance report)"
    "Known = class name exists in a HASH-VERIFIED jar, or in the target JVM's runtime image."
    "Mods folder scanned : $modsFolder"
    "Date                : $(Get-Date)"
    "Machine             : $env:COMPUTERNAME   User: $env:USERNAME"
) -join "`r`n" | Set-Content -Path $UnknownFile -Encoding UTF8

$ProvenanceFullFile = $null
$ProvenanceUnknownFile = $null
if ($ProvenanceMode) {
    $ProvenanceFullFile = Join-Path $downloads ("Provenance-Full_{0}.txt" -f $stamp)
    $ProvenanceUnknownFile = Join-Path $downloads ("Provenance-Unknown_{0}.txt" -f $stamp)
    @(
        "P1ae's Classloader Dump - PROVENANCE REPORT"
        "Date     : $(Get-Date)"
        $EngineLine
    ) -join "`r`n" | Set-Content -Path $ProvenanceFullFile -Encoding UTF8
    @(
        "P1ae's Classloader Dump - PROVENANCE TRUST REPORT"
        "Date     : $(Get-Date)"
        $EngineLine
    ) -join "`r`n" | Set-Content -Path $ProvenanceUnknownFile -Encoding UTF8
}

Write-Section "Minecraft process scan"
$javaProcs = Get-Process -Name javaw -ErrorAction SilentlyContinue
if (-not $javaProcs) {
    Write-Fail "No javaw process found"
    Write-Info "Make sure Minecraft is running"
    foreach ($j in $jobs) { Add-Content $j.File "`r`nNO JAVA PROCESS FOUND $gDash Minecraft was not running." }
    exit
}
Write-Info "Found $($javaProcs.Count) Java process(es)"
foreach ($p in $javaProcs) {
    try {
        $up = (Get-Date) - $p.StartTime
        Write-Host "    $gTri " -NoNewline -ForegroundColor Green
        Write-Host "$($p.Name)" -NoNewline -ForegroundColor White
        Write-Host "   PID $($p.Id)" -NoNewline -ForegroundColor Cyan
        Write-Host "   up $($up.Hours)h $($up.Minutes)m $($up.Seconds)s" -ForegroundColor DarkGray
        Write-Host ""
    } catch {}
}

$targetProcs = $javaProcs
if ($instanceFolders -and $instanceFolders.Base -and $javaProcs) {
    $matched = New-Object System.Collections.Generic.List[object]
    foreach ($p in $javaProcs) {
        $procBase = Get-ProcessInstanceBase $p
        if ($procBase -and ($procBase.TrimEnd('\') -ieq $instanceFolders.Base.TrimEnd('\'))) {
            $matched.Add($p)
        } else {
            $label = if ($procBase) { $procBase } else { "(instance undetermined)" }
            Write-Dim "PID $($p.Id) belongs to a different instance ($label) - skipping" 4
        }
    }
    if ($matched.Count -gt 0) {
        $targetProcs = $matched
    } else {
        Write-Warn "Couldn't match any running process back to the detected instance - falling back to dumping all javaw processes"
    }
}
Write-Ok "jcmd  $jcmd"

Write-Section "Trust sources"
$ProcSetup = @{}
$staffCount = Import-StaffHashFile
if ($staffCount -gt 0) { Write-Ok "staff allow-list  $staffCount built-in hash(es)" }

$jdkSeen = @{}
foreach ($proc in $targetProcs) {
    $jdkCount = Select-JdkClasses $proc
    if ($jdkSeen.ContainsKey($script:JdkKey)) { continue }
    $jdkSeen[$script:JdkKey] = $true
    $jdkWho = if ($targetProcs.Count -gt 1) { "  (PID $($proc.Id): $($script:JdkKey))" } else { "" }
    if ($jdkCount -gt 0) { Write-Ok "jdk        $jdkCount platform classes indexed from the target's own runtime$jdkWho" }
    else { Write-Warn "JDK runtime classes could not be indexed - JDK classes will show as unverified$jdkWho" }
}

foreach ($proc in $targetProcs) {
    $pidNum = $proc.Id
    Write-Info "Collecting trust data for PID $pidNum..."
    try { $script:JvmStartUtc = $proc.StartTime.ToUniversalTime() } catch { $script:JvmStartUtc = [datetime]::MaxValue }

    $cmdText = Get-JcmdText $jcmd $pidNum "VM.command_line"
    $propsText = Get-JcmdText $jcmd $pidNum "VM.system_properties"
    $cpEntries = Split-PathList (Get-JvmPropertyValue $propsText "java.class.path")
    $mpEntries = Split-PathList (Get-JvmPropertyValue $propsText "jdk.module.path")
    $agentPaths = Get-JavaAgentPaths $cmdText
    $flagFindings = Get-JvmFlagFindings $cmdText $propsText

    $versionFolders = if ($instanceFolders) { $instanceFolders.Versions } else { @() }
    $meta = Import-MetadataForProcess $cmdText $cpEntries $versionFolders
    if ($script:OnlineOK) { Write-Ok "official metadata  Mojang$(if ($meta.OfficialIds.Count) { ' (' + ($meta.OfficialIds -join ', ') + ')' })" 4 }
    else { Write-Warn "Mojang metadata unreachable - vanilla jars are only verifiable through local launcher metadata (Weak tier)" 4 }

    $sources = New-Object System.Collections.Generic.List[string]
    $modJars = New-Object System.Collections.Generic.List[string]
    foreach ($e in @($cpEntries) + @($mpEntries) + @($meta.ClientJars)) {
        if ($e -and $e -match '\.jar$' -and (Test-Path -LiteralPath $e -PathType Leaf -ErrorAction SilentlyContinue)) { $sources.Add($e) }
    }
    foreach ($e in @($agentPaths)) {
        if ($e -and (Test-Path -LiteralPath $e -PathType Leaf -ErrorAction SilentlyContinue)) { $sources.Add($e) }
    }
    if ($instanceFolders -and (Test-Path $instanceFolders.Mods -ErrorAction SilentlyContinue)) {
        foreach ($f in (Get-ChildItem -LiteralPath $instanceFolders.Mods -Filter "*.jar" -Recurse -File -ErrorAction SilentlyContinue)) { $sources.Add($f.FullName); $modJars.Add($f.FullName) }
    }
    Invoke-JarPrefetch @($sources | Select-Object -Unique)
    foreach ($s in ($sources | Select-Object -Unique)) { [void](Get-JarAnalysis $s) }

    $modsTrusted = 0
    foreach ($mj in $modJars) {
        $ma = Get-JarAnalysis $mj
        if ($ma.Exists -and $ma.Hashes) {
            Register-AllHashes $ma.Hashes 'OFFICIAL' 'mods folder jar (whitelisted without lookup)'
            $modsTrusted++
        }
    }
    Write-Ok "mods folder  $modsTrusted jar(s)" 4

    foreach ($e in @($cpEntries)) {
        if ($e -match '(?i)(prism|polymc|multimc).*[\\/]jars[\\/]NewLaunch\.jar$' -and (Test-Path -LiteralPath $e -PathType Leaf -ErrorAction SilentlyContinue)) {
            $la = Get-JarAnalysis $e
            if ($la.Exists -and $la.Parsed -and $la.Classes.Contains('org.prismlauncher.EntryPoint')) {
                Register-AllHashes $la.Hashes 'LOCAL' 'launcher bootstrap jar on java.class.path (NewLaunch.jar) - not hash-verifiable'
            }
        }
    }

    $ProcSetup[$pidNum] = @{
        Cmd = $cmdText; ClassPath = $cpEntries; AgentPaths = $agentPaths; Flags = $flagFindings
        Sources = @($sources | Select-Object -Unique)
    }
}

Write-Info "Looking up jar hashes (Modrinth / Maven Central / Fabric+Quilt Maven)..."
Resolve-JarTiers
Invoke-ModrinthLookup
Resolve-JarTiers
Invoke-RepoSha1Lookup
Resolve-JarTiers
Invoke-MavenLookup
Resolve-JarTiers
Update-VerifiedClasses
Import-IntermediaryMappings
if ($script:IntermediaryClasses.Count -gt 0) { Write-Ok "intermediary  $($script:IntermediaryClasses.Count) mapped class names from the verified mappings jar" }
elseif ($instanceFolders -and @($instanceFolders.Remapped).Count -gt 0) { Write-Warn "No hash-verified intermediary mappings jar found - class_N names in the launcher cache can't be validated and will show as Unverified" }

$tc = @{ OFFICIAL = 0; LOCAL = 0; BADLOCAL = 0; NONE = 0 }
foreach ($a in $script:AnalysisCache.Values) { if ($a.Exists) { $tc[$a.Tier]++ } }
Write-Ok "jars analysed  $($script:AnalysisCache.Count)   verified $($tc.OFFICIAL)   weak $($tc.LOCAL)   unverified $($tc.NONE)"
if ($tc.BADLOCAL -gt 0) { Write-Note "$($tc.BADLOCAL) jar(s) are listed only in local launcher metadata that disagrees with the official metadata" }
Write-Info "$($script:VerifiedClasses.Count) classes belong to hash-verified jars"
Lap "trust sources"

foreach ($proc in $targetProcs) {
    $ps = $ProcSetup[$proc.Id]
    foreach ($fl in $ps.Flags) { Write-Note "PID $($proc.Id) JVM flag: $fl" 4 }
    foreach ($ap in $ps.AgentPaths) {
        $a = if (Test-Path -LiteralPath $ap -ErrorAction SilentlyContinue) { Get-JarAnalysis $ap } else { $null }
        $t = if ($a -and $a.Exists) { $a.Tier } else { 'MISSING' }
        Write-Note "PID $($proc.Id) -javaagent  [$t]  $ap" 4
    }
}

Write-Section "Classloader dumps"
$allUnknown = New-Object System.Collections.Generic.SortedSet[string]
$jcmdNamesByPid = @{}
foreach ($j in $jobs) {
    Add-Content $j.File "`r`nUsing jcmd: $jcmd"
    Write-Host ""
    Write-Host "  $gDiamond " -NoNewline -ForegroundColor Cyan
    Write-Host "$($j.Title)" -ForegroundColor White
    foreach ($proc in $targetProcs) {
        $pidNum = $proc.Id
        [void](Select-JdkClasses $proc)
        $procPath = if ($proc.Path) { $proc.Path } else { "(path unavailable)" }
        Add-Content $j.File "`r`n$($gBar * 60)"
        Add-Content $j.File "PROCESS  : $($proc.ProcessName)   PID: $pidNum"
        Add-Content $j.File "EXE      : $procPath"
        Add-Content $j.File "COMMAND  : jcmd $pidNum $($j.Cmd)"
        Add-Content $j.File ($gBar * 60)
        try {
            $output = & $jcmd $pidNum $j.Cmd.Split(" ") 2>&1
            $outputText = if ($output) { $output -join "`r`n" } else { "(no output)" }
            Add-Content $j.File $outputText
            Write-Ok "PID $pidNum dumped" 4
            if ($j.Short -eq "Classloaders-Full" -and $output) {
                $classes = Extract-ClassNames $outputText
                $jcmdNamesByPid[$pidNum] = $classes
                $unknownForProc = if ($script:FastOK) {
                    [P1Fast]::FilterUnknown([string[]]@($classes), $script:VerifiedClasses, $script:JdkClasses, $ProxyPattern, $AccessorPattern, $JdkSpunPattern, [bool]$script:VerifiedClasses.Contains('com.llamalad7.mixinextras.MixinExtrasBootstrap')) | Sort-Object
                } else { $classes | Where-Object { -not (Test-KnownByName $_) } | Sort-Object }
                Add-Content $UnknownFile "`r`n$($gBar * 60)"
                if ($unknownForProc) {
                    Add-Content $UnknownFile "PROCESS  : $($proc.ProcessName)   PID: $pidNum"
                    Add-Content $UnknownFile ($gBar * 60)
                    Add-Lines $UnknownFile @($unknownForProc)
                    foreach ($u in $unknownForProc) { [void]$allUnknown.Add($u) }
                    Write-Note "$(@($unknownForProc).Count) unrecognized class name(s) for PID $pidNum" 4
                } else {
                    Add-Content $UnknownFile "PROCESS  : $($proc.ProcessName)   PID: $pidNum  $gDash no unrecognized classes found"
                    Add-Content $UnknownFile ($gBar * 60)
                }
            }
        } catch {
            Add-Content $j.File "[!] ATTACH FAILED: $($_.Exception.Message)"
            Add-Content $j.File "    (A cheat that blocks the Attach API can cause this $gDash worth a closer look.)"
            Write-Fail "PID $pidNum attach failed" 4
        }
    }
    Add-Content $j.File "`r`n$($gBar * 60)`r`nEnd of report."
}
Add-Content $UnknownFile "`r`n$($gBar * 60)"
Add-Content $UnknownFile "TOTAL UNIQUE UNRECOGNIZED CLASSES: $($allUnknown.Count)"
Add-Content $UnknownFile ($gBar * 60)

Lap "classloader dumps"
function Format-ClassGroup($g, $names, $reasons, [int]$cap, [bool]$withSha) {
    $o = New-Object System.Collections.Generic.List[string]
    $o.Add("[$($g.Tier)] $($g.Idx.Count) class(es) - $($g.Main)")
    $o.Add("  source: $($g.Cs)")
    $o.Add("  loader: $($g.Loader)")
    if ($withSha -and $g.Jar -and (Test-Path -LiteralPath $g.Jar -PathType Leaf -ErrorAction SilentlyContinue)) {
        $ja = Get-JarAnalysis $g.Jar
        if ($ja.Hashes) { $o.Add("  sha256: $($ja.Hashes.SHA256)") }
    }
    $lines = New-Object System.Collections.Generic.List[string]
    foreach ($i in $g.Idx) {
        if ($reasons[$i] -eq $g.Main) { $lines.Add("      " + $names[$i]) }
        else { $lines.Add("      " + $names[$i] + "   <- " + $reasons[$i]) }
    }
    $lines.Sort([StringComparer]::Ordinal)
    if ($cap -gt 0 -and $lines.Count -gt $cap) {
        $o.AddRange($lines.GetRange(0, $cap))
        $o.Add("      ... +$($lines.Count - $cap) more (see Provenance-Full)")
    } else { $o.AddRange($lines) }
    return ,$o
}
$allProvenanceUnknown = New-Object System.Collections.Generic.SortedSet[string]
if ($ProvenanceMode) {
    Write-Section "Provenance check"
    foreach ($proc in $targetProcs) {
        $pidNum = $proc.Id
        $ps = $ProcSetup[$pidNum]
        try { $script:JvmStartUtc = $proc.StartTime.ToUniversalTime() } catch { $script:JvmStartUtc = [datetime]::MaxValue }
        $script:StateCache = @{}
        [void](Select-JdkClasses $proc)

        $reportPath = Join-Path $provenanceAgent.BuildDir ("report_{0}.tsv" -f $pidNum)
        Remove-Item -LiteralPath $reportPath -Force -ErrorAction SilentlyContinue
        $attachResult = Invoke-ProvenanceAgent $javaExe $provenanceAgent.BuildDir $provenanceAgent.AgentJar $pidNum $reportPath
        Add-Content $ProvenanceFullFile "`r`n$($gBar * 60)`r`nPROCESS  : $($proc.ProcessName)   PID: $pidNum`r`n$($gBar * 60)"
        Add-Content $ProvenanceUnknownFile "`r`n$($gBar * 60)`r`nPROCESS  : $($proc.ProcessName)   PID: $pidNum`r`n$($gBar * 60)"
        if (-not $attachResult.Success) {
            $m = "[!] AGENT ATTACH FAILED: $($attachResult.Error)"
            Add-Content $ProvenanceFullFile $m
            Add-Content $ProvenanceUnknownFile $m
            if ($attachResult.Error -match "jdk\.attach|FindException") {
                Add-Content $ProvenanceFullFile "    (The javac/java found here lacks the jdk.attach module - an environment mismatch, not proof of blocking. Use the Classloaders-Unknown report for this run.)"
            } else {
                Add-Content $ProvenanceFullFile "    (A cheat that blocks the Attach API can cause this - check whether the jcmd dumps above show the same failure; if THOSE also failed, that's the stronger signal.)"
            }
            Write-Fail "PID $pidNum provenance attach failed"
            continue
        }

        if ($script:FastOK) {
            $rd = [P1Fast]::ParseReport($reportPath)
            $rNames = $rd.Name; $rLoaders = $rd.Loader; $rCs = $rd.CodeSource; $rHidden = $rd.Hidden; $rProxy = $rd.Proxy
            $csDistinct = [P1Fast]::Distinct($rCs)
        } else {
            $records = Import-ProvenanceReport $reportPath
            $rNames = [string[]]@($records | ForEach-Object { $_.Name })
            $rLoaders = [string[]]@($records | ForEach-Object { $_.Loader })
            $rCs = [string[]]@($records | ForEach-Object { $_.CodeSource })
            $csDistinct = [string[]]@($rCs | Select-Object -Unique)
            $script:HiddenSupported = $false
            $script:LoadersByName = @{}
            foreach ($rec in $records) {
                if ($rec.Hidden -eq 'true') { $script:HiddenSupported = $true }
                $ls = $script:LoadersByName[$rec.Name]
                if (-not $ls) { $ls = New-Object System.Collections.Generic.HashSet[string]; $script:LoadersByName[$rec.Name] = $ls }
                [void]$ls.Add([string]$rec.Loader)
            }
        }
        $rCount = $rNames.Length
        Remove-Item -LiteralPath $reportPath -Force -ErrorAction SilentlyContinue

        $csPaths = New-Object System.Collections.Generic.List[string]
        foreach ($csu in $csDistinct) {
            $loc = ConvertFrom-CodeSourceUrl $csu
            if ($loc -and $loc.Type -eq 'FILE' -and $loc.Path -and (Test-Path -LiteralPath $loc.Path -PathType Leaf -ErrorAction SilentlyContinue)) {
                $csPaths.Add($loc.Path)
            }
        }
        Invoke-JarPrefetch @($csPaths)
        foreach ($p0 in $csPaths) { [void](Get-JarAnalysis $p0) }
        Resolve-JarTiers
        Invoke-ModrinthLookup
        Resolve-JarTiers
        Update-VerifiedClasses
        Import-IntermediaryMappings
        Lap "provenance: read + jars"

        $remap = if ($instanceFolders) { $instanceFolders.Remapped } else { @() }
        if ($script:FastOK) {
            $ctxArr = New-Object 'P1Ctx[]' $csDistinct.Length
            for ($ci = 0; $ci -lt $csDistinct.Length; $ci++) { $ctxArr[$ci] = New-VerdictContext $csDistinct[$ci] $remap }
            $mxOk = [bool]$script:VerifiedClasses.Contains('com.llamalad7.mixinextras.MixinExtrasBootstrap')
            $res = [P1Fast]::Classify($rNames, $rLoaders, $rCs, $rHidden, $rProxy, $csDistinct, $ctxArr, $script:VerifiedClasses, $script:JdkClasses, $ProxyPattern, $AccessorPattern, $JdkSpunPattern, $mxOk)
            $vTier = $res.Tier; $vReason = $res.Reason; $vJar = $res.Jar
        } else {
            $verdicts = New-Object System.Collections.Generic.List[object]
            foreach ($rec in $records) { $verdicts.Add((Get-ClassVerdict $rec $remap)) }
            $vTier = [string[]]@($verdicts | ForEach-Object { [string]$_.Tier })
            $vReason = [string[]]@($verdicts | ForEach-Object { [string]$_.Reason })
            $vJar = [string[]]@($verdicts | ForEach-Object { [string]$_.Jar })
        }
        Lap "provenance: verdicts"

        $full = New-Object System.Collections.Generic.List[string]
        $full.Add("JAR INVENTORY (sha256 | tier | reason | path)")
        foreach ($a in ($script:AnalysisCache.Values | Sort-Object Path)) {
            if ($a.Exists) { $full.Add("$($a.Hashes.SHA256) | $($a.Tier) | $($a.Reason) | $($a.Path)") }
        }
        $tierOrder = @('Suspicious', 'Unverified', 'Weak', 'Derived', 'Generated', 'Verified')
        $counts = @{}
        $groups = @{}
        $firstIdx = @{}
        $loaderUse = @{}
        for ($i = 0; $i -lt $rCount; $i++) {
            $t = $vTier[$i]
            $counts[$t] = 1 + [int]$counts[$t]
            if (-not $firstIdx.ContainsKey($rNames[$i])) { $firstIdx[$rNames[$i]] = $i }
            if (($t -eq 'Verified' -or $t -eq 'Weak' -or $t -eq 'Derived') -and $rLoaders[$i] -ne 'BOOTSTRAP') {
                $loaderUse[$rLoaders[$i]] = 1 + [int]$loaderUse[$rLoaders[$i]]
            }
            $gk = $t + "`t" + $rCs[$i] + "`t" + $rLoaders[$i]
            $g = $groups[$gk]
            if (-not $g) {
                $g = @{ Tier = $t; Cs = $rCs[$i]; Loader = $rLoaders[$i]; Jar = $vJar[$i]; Main = ''; Rank = 0; Idx = (New-Object System.Collections.Generic.List[int]); Reasons = @{} }
                $groups[$gk] = $g
            }
            $g.Idx.Add($i)
            $rk = [string]$vReason[$i]
            $g.Reasons[$rk] = 1 + [int]$g.Reasons[$rk]
            if ($t -eq 'Suspicious' -or $t -eq 'Unverified' -or $t -eq 'Weak') { [void]$allProvenanceUnknown.Add($rNames[$i]) }
        }
        foreach ($g in $groups.Values) {
            $g.Main = [string](($g.Reasons.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1).Key)
            $g.Rank = [array]::IndexOf($tierOrder, $g.Tier)
        }
        $groupList = @($groups.Values | Sort-Object { $_.Rank }, { $_.Cs }, { $_.Loader })

        $badLoaders = New-Object System.Collections.Generic.List[object]
        if ($script:JdkClasses.Count -gt 0) {
            foreach ($ln in ($loaderUse.Keys | Sort-Object)) {
                $li = $firstIdx[$ln]
                $lt = if ($null -ne $li) { $vTier[$li] } else { 'not in class list' }
                if ($lt -eq 'Verified' -or $lt -eq 'Derived' -or $lt -eq 'Generated') { continue }
                $lr = if ($null -ne $li) { $vReason[$li] } else { 'the loader class itself was not reported by the agent' }
                $lc = if ($null -ne $li) { $rCs[$li] } else { '(unknown)' }
                $badLoaders.Add(@{ Name = $ln; Tier = $lt; Reason = $lr; Cs = $lc; Count = [int]$loaderUse[$ln] })
            }
        }

        $full.Add($gBar * 60)
        $full.Add("CLASSES BY SOURCE - $rCount classes in $($groupList.Count) group(s), worst tier first")
        $full.Add("A class only shows its own reason ('<-') when it differs from its group's.")
        foreach ($g in $groupList) {
            $full.Add("")
            $full.AddRange((Format-ClassGroup $g $rNames $vReason 0 $false))
        }
        Add-Lines $ProvenanceFullFile $full

        $rep = New-Object System.Collections.Generic.List[string]
        if (-not $script:OnlineOK) {
            $rep.Add("*** INCONCLUSIVE - official Mojang metadata was unreachable, so vanilla jars and local launcher metadata could not be cross-checked. RERUN ONLINE. ***")
            $rep.Add("")
        }
        $rep.Add("SUMMARY: " + (($tierOrder | ForEach-Object { "$_=$([int]$counts[$_])" }) -join "   ") + "   (total $rCount)")
        $rep.Add("Online lookups reachable: $script:OnlineOK   |   JDK classes indexed: $($script:JdkClasses.Count)")
        foreach ($sec in @(@('Suspicious', 100), @('Unverified', 25), @('Weak', 25))) {
            $rep.Add("")
            $rep.Add("== $($sec[0].ToUpper()) ($([int]$counts[$sec[0]]) class(es), grouped by source) ==")
            $secGroups = @($groupList | Where-Object { $_.Tier -eq $sec[0] })
            if ($secGroups.Count -eq 0) { $rep.Add("none") }
            foreach ($g in $secGroups) { $rep.AddRange((Format-ClassGroup $g $rNames $vReason $sec[1] $true)) }
        }
        $rep.Add("")
        $rep.Add("== UNTRUSTED CLASS LOADERS ($($badLoaders.Count)) ==")
        if ($badLoaders.Count -eq 0) { $rep.Add("none") }
        foreach ($bl in $badLoaders) {
            $rep.Add("[$($bl.Tier)] $($bl.Name) - $($bl.Reason)")
            $rep.Add("  source: $($bl.Cs)")
            $rep.Add("  defined $($bl.Count) class(es) that otherwise check out - their codesource is reported by this loader, so treat them as only as trustworthy as the loader")
        }
        $rep.Add("")
        $rep.Add("== LAUNCHER CACHE JARS (generated locally - only a built-in content digest can verify their bytes) ==")
        $derivedJars = @($groupList | Where-Object { $_.Jar -and (Test-InRemapCache $_.Jar $remap) -and (Get-JarAnalysis $_.Jar).Tier -ne 'OFFICIAL' } | Group-Object { [string]$_.Jar } | Sort-Object Name)
        if ($derivedJars.Count -eq 0) { $rep.Add("none") }
        foreach ($dj in $derivedJars) {
            $dn = 0
            foreach ($dg in $dj.Group) { $dn += $dg.Idx.Count }
            $ja = Get-JarAnalysis $dj.Name
            $di = Get-RemapDigestInfo $dj.Name
            $dsha = if ($ja -and $ja.Hashes) { $ja.Hashes.SHA256 } else { '(unreadable)' }
            $dstate = switch ($di.State) {
                'match'    { 'MATCHES the built-in known-good digest' }
                'mismatch' { 'DOES NOT MATCH the built-in known-good digest' }
                default    { 'no built-in digest for this version - bytes unverified' }
            }
            $dextra = 0
            if ($ja -and $ja.Classes) {
                foreach ($cn in $ja.Classes) { if (-not $script:VerifiedClasses.Contains($cn) -and -not $script:IntermediaryClasses.Contains($cn)) { $dextra++ } }
            }
            $dbuilt = 'creation time unreadable'
            try {
                $dct = (Get-Item -LiteralPath $dj.Name -Force).CreationTimeUtc
                if ($script:JvmStartUtc -ne [datetime]::MaxValue -and $dct -ge $script:JvmStartUtc -and $dct -le $script:JvmStartUtc.AddSeconds($DerivedGraceSec)) { $dbuilt = "built during this launch ($dct UTC)" }
                else { $dbuilt = "reused from an earlier launch (created $dct UTC)" }
            } catch {}
            $rep.Add("$($dj.Name)")
            $rep.Add("  $dn loaded class(es)   $dbuilt")
            $rep.Add("  content digest: $(if ($di.Digest) { $di.Digest } else { '(unavailable)' })   [$($di.Key)]   $dstate")
            $rep.Add("  file sha256   : $dsha")
            if ($dextra -gt 0) { $rep.Add("  WARNING: $dextra class(es) in this jar are not in the verified mappings or any verified jar") }
        }
        $rep.Add("")
        $rep.Add("== OTHER WEAK-TIER JARS (no classes loaded from them; hash only attested by local launcher metadata) ==")
        $weakShown = New-Object System.Collections.Generic.HashSet[string]
        foreach ($wg in $groupList) { if ($wg.Tier -eq 'Weak' -and $wg.Jar) { [void]$weakShown.Add((Get-PathKey $wg.Jar)) } }
        $weak = @($script:AnalysisCache.Values | Where-Object { $_.Tier -eq 'LOCAL' -and -not $weakShown.Contains((Get-PathKey $_.Path)) } | Sort-Object Path)
        if ($weak.Count -eq 0) { $rep.Add("none") }
        foreach ($a in $weak) { $rep.Add("$($a.Hashes.SHA256)  $($a.Path)") }
        $rep.Add("")
        $rep.Add("== JVM FLAGS / AGENTS ==")
        if ($ps.Flags.Count -eq 0 -and $ps.AgentPaths.Count -eq 0) { $rep.Add("none") }
        foreach ($fl in $ps.Flags) { $rep.Add("flag: $fl") }
        foreach ($ap in $ps.AgentPaths) {
            $a = if (Test-Path -LiteralPath $ap -ErrorAction SilentlyContinue) { Get-JarAnalysis $ap } else { $null }
            $t = if ($a -and $a.Exists) { "$($a.Tier) ($($a.Reason))  sha256=$($a.Hashes.SHA256)" } else { "MISSING ON DISK" }
            $rep.Add("javaagent: $ap  =>  $t")
        }
        $rep.Add("")
        $rep.Add("== CROSS-CHECK: jcmd names the agent did not report (informational) ==")
        if ($jcmdNamesByPid.ContainsKey($pidNum)) {
            if ($script:FastOK) {
                $missing = @([P1Fast]::MissingNames([string[]]@($jcmdNamesByPid[$pidNum]), $rNames))
            } else {
                $agentSet = New-Object System.Collections.Generic.HashSet[string]
                foreach ($n0 in $rNames) {
                    $n = $n0
                    if ($n -match '^\[+L(.+);$') { $n = $Matches[1] }
                    [void]$agentSet.Add($n); [void]$agentSet.Add((Get-BaseClassName $n))
                }
                $missing = @($jcmdNamesByPid[$pidNum] | Where-Object { -not $agentSet.Contains($_) -and -not $agentSet.Contains((Get-BaseClassName $_)) } | Sort-Object)
            }
            if ($missing.Count -eq 0) { $rep.Add("none") } else { $rep.Add("count: $($missing.Count)") }
            foreach ($m in ($missing | Select-Object -First 300)) { $rep.Add("  $m") }
            if ($missing.Count -gt 300) { $rep.Add("  ... +$($missing.Count - 300) more") }
        } else { $rep.Add("no jcmd class list available for this PID") }
        $kept = New-Object System.Collections.Generic.List[string]
        for ($ri = 0; $ri -lt $rep.Count; $ri++) {
            if ($rep[$ri] -like '== * ==' -and ($ri + 1) -lt $rep.Count -and $rep[$ri + 1] -eq 'none') {
                if ($kept.Count -gt 0 -and $kept[$kept.Count - 1] -eq '') { $kept.RemoveAt($kept.Count - 1) }
                $ri++
                continue
            }
            $kept.Add($rep[$ri])
        }
        $rep = $kept
        Add-Lines $ProvenanceUnknownFile $rep

        $weakN = [int]$counts['Weak']
        $bad = [int]$counts['Suspicious'] + [int]$counts['Unverified'] + $weakN
        if ($bad -gt 0) {
            Write-Note "PID $pidNum - $rCount classes checked, suspicious $([int]$counts['Suspicious']), unverified $([int]$counts['Unverified']), weak $weakN"
        } elseif ($script:OnlineOK) {
            Write-Ok "PID $pidNum - $rCount classes checked, 0 suspicious / unverified / weak"
        } else {
            Write-Warn "PID $pidNum - $rCount classes checked, nothing flagged, but the result is not conclusive (see below)"
        }
        if (-not $script:OnlineOK) { Write-Fail "PID $pidNum - INCONCLUSIVE: official Mojang metadata was unreachable - rerun online" 4 }
        foreach ($bl in $badLoaders) { Write-Note "PID $pidNum - untrusted class loader $($bl.Name) [$($bl.Tier)] defined $($bl.Count) class(es)" 4 }
    }
    Add-Content $ProvenanceUnknownFile "`r`n$($gBar * 60)`r`nTOTAL UNIQUE SUSPICIOUS/UNVERIFIED/WEAK CLASSES: $($allProvenanceUnknown.Count)$(if (-not $script:OnlineOK) { '   *** INCONCLUSIVE - RERUN ONLINE ***' })`r`n$($gBar * 60)"
}

Lap "provenance check"
function Write-SavedFile([string]$name, [string]$path, [string]$extra = "", [string]$extraColor = "DarkGray") {
    Write-Host "  $gCheck " -NoNewline -ForegroundColor Green
    Write-Host $name -NoNewline -ForegroundColor White
    if ($extra) { Write-Host "  $extra" -NoNewline -ForegroundColor $extraColor }
    Write-Host ""
    Write-Host "      $path" -ForegroundColor DarkGray
}

Write-Section "Done - files saved"
foreach ($j in $jobs) {
    Write-SavedFile "$($j.Short).txt" $j.File
}
$uc = if ($allUnknown.Count -gt 0) { "Magenta" } else { "Green" }
Write-SavedFile "Classloaders-Unknown.txt" $UnknownFile "($($allUnknown.Count) unique)" $uc
if ($ProvenanceMode) {
    Write-SavedFile "Provenance-Full.txt" $ProvenanceFullFile
    $pc = if ($allProvenanceUnknown.Count -gt 0) { "Magenta" } else { "Green" }
    Write-SavedFile "Provenance-Unknown.txt" $ProvenanceUnknownFile "  ($($allProvenanceUnknown.Count) unique)" $pc
}
$fileCount = if ($ProvenanceMode) { "ALL FIVE" } else { "ALL THREE" }
Write-Host ""
Write-Box @("Send $fileCount .txt files to the staff member running your SS.") 'Green' @('White')
Write-Host ""
exit
