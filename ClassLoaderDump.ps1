[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"
$gCheck=[string][char]0x2713; $gChev=[string][char]0x203A; $gDot=[string][char]0x00B7; $gWarn=[string][char]0x25B2
$gCross=[string][char]0x2717; $gDiamond=[string][char]0x25C6; $gH=[string][char]0x2500; $gTL=[string][char]0x256D
$gTR=[string][char]0x256E; $gV=[string][char]0x2502; $gBL=[string][char]0x2570; $gBR=[string][char]0x256F
$gPrompt=[string][char]0x276F; $gArrow=[string][char]0x2192; $gDash=[string][char]0x2013; $gBar=[string][char]0x2501
$gTri=[string][char]0x25B8

$script:W = 76
$script:SectionNo = 0

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
    "v1.2.1",
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

if (-not ('TolerantZip' -as [type])) {
    Add-Type -TypeDefinition @"
using System;
using System.IO;
using System.Text;
using System.Collections.Generic;
public static class TolerantZip
{
    public static List<string> ListEntries(string path)
    {
        byte[] d = File.ReadAllBytes(path);
        var names = new List<string>();
        if (!TryCentralDirectory(d, names)) { names.Clear(); ScanLocalHeaders(d, names); }
        return names;
    }
    static ushort U16(byte[] d, long o) { return (ushort)(d[o] | (d[o + 1] << 8)); }
    static uint U32(byte[] d, long o) { return (uint)(d[o] | (d[o+1] << 8) | (d[o+2] << 16) | (d[o+3] << 24)); }
    static ulong U64(byte[] d, long o) { return U32(d, o) | ((ulong)U32(d, o + 4) << 32); }

    static bool TryCentralDirectory(byte[] d, List<string> names)
    {
        long eocd = -1;
        long min = Math.Max(0, d.LongLength - 65557);
        for (long i = d.LongLength - 22; i >= min; i--)
            if (U32(d, i) == 0x06054b50) { eocd = i; break; }
        if (eocd < 0) return false;
        ulong entries = U16(d, eocd + 10);
        ulong cdOff = U32(d, eocd + 16);
        if ((entries == 0xFFFF || cdOff == 0xFFFFFFFF) && eocd >= 20 && U32(d, eocd - 20) == 0x07064b50)
        {
            ulong z64 = U64(d, eocd - 20 + 8);
            if (z64 + 56 <= (ulong)d.LongLength && U32(d, (long)z64) == 0x06064b50)
            {
                entries = U64(d, (long)z64 + 32);
                cdOff = U64(d, (long)z64 + 48);
            }
        }
        long p = (long)cdOff;
        for (ulong n = 0; n < entries; n++)
        {
            if (p < 0 || p + 46 > d.LongLength || U32(d, p) != 0x02014b50) return false;
            int nl = U16(d, p + 28), el = U16(d, p + 30), cl = U16(d, p + 32);
            if (p + 46 + nl > d.LongLength) return false;
            names.Add(Encoding.UTF8.GetString(d, (int)p + 46, nl));
            p += 46 + nl + el + cl;
        }
        return names.Count > 0;
    }

    static void ScanLocalHeaders(byte[] d, List<string> names)
    {
        for (long i = 0; i + 30 < d.LongLength; i++)
        {
            if (d[i] != 0x50 || d[i+1] != 0x4B || d[i+2] != 3 || d[i+3] != 4) continue;
            int nl = U16(d, i + 26);
            if (nl == 0 || i + 30 + nl > d.LongLength) continue;
            string name = Encoding.UTF8.GetString(d, (int)i + 30, nl);
            if (name.EndsWith(".class")) names.Add(name);
        }
    }
}
"@
}

function Add-EntryNamesToWhitelist($names, $exact, $packageSet) {
    $count = 0
    foreach ($n in $names) {
        if (-not $n.EndsWith(".class")) { continue }
        if ($n.StartsWith("META-INF/") -or $n -eq "module-info.class") { continue }
        $q = $n.Substring(0, $n.Length - 6) -replace '/', '.'
        [void]$exact.Add($q)
        $count++
        $i = $q.LastIndexOf('.')
        if ($i -gt 0) { [void]$packageSet.Add($q.Substring(0, $i)) }
    }
    return $count
}

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

$EssentialModJarPattern = '^Essential_[0-9][0-9.\-]*_[A-Za-z]+_[0-9][0-9.\-]*\.jar$'
function Get-EssentialFolders([string]$base) {
    $found = New-Object System.Collections.Generic.List[string]
    $modsDir = Join-Path $base "mods"
    $candidate = Join-Path $base "essential"
    if (-not (Test-Path $modsDir -ErrorAction SilentlyContinue)) { return $found }
    if (-not (Test-Path $candidate -ErrorAction SilentlyContinue)) { return $found }
    $essentialJar = Get-ChildItem -LiteralPath $modsDir -Filter "*.jar" -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match $EssentialModJarPattern } | Select-Object -First 1
    if ($essentialJar) { [void]$found.Add($candidate) }
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

function Resolve-InstanceFolders([string]$cwd) {
    if (-not $cwd -or -not (Test-Path $cwd -ErrorAction SilentlyContinue)) { return $null }
    foreach ($base in (Get-LayoutBases $cwd)) {
        $modsPath = Join-Path $base "mods"
        if (Test-Path $modsPath -ErrorAction SilentlyContinue) {
            return @{
                Mods      = $modsPath
                Libraries = (Find-UpwardFolders $base "libraries")
                Versions  = (Find-UpwardFolders $base "versions")
                Remapped  = (Get-RemapCacheFolders $base)
                Essential = (Get-EssentialFolders $base)
                Base      = $base
            }
        }
    }
    try {
        foreach ($entry in (Get-ChildItem -LiteralPath $cwd -Directory -ErrorAction SilentlyContinue)) {
            foreach ($base in (Get-LayoutBases $entry.FullName)) {
                $modsPath = Join-Path $base "mods"
                if (Test-Path $modsPath -ErrorAction SilentlyContinue) {
                    return @{
                        Mods      = $modsPath
                        Libraries = (Find-UpwardFolders $base "libraries")
                        Versions  = (Find-UpwardFolders $base "versions")
                        Remapped  = (Get-RemapCacheFolders $base)
                        Essential = (Get-EssentialFolders $base)
                        Base      = $base
                    }
                }
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

$CompareMode = $true
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
    Write-Warn "Could not detect the mods folder. Comparison will be skipped."
    Write-Dim "Only the basic classloader dumps will be produced." 4
    $CompareMode = $false
}

$MsiUrl = "https://github.com/adoptium/temurin25-binaries/releases/download/jdk-25.0.3%2B9/OpenJDK25U-jdk_x64_windows_hotspot_25.0.3_9.msi"
$MsiName = "OpenJDK25U-jdk_x64_windows_hotspot_25.0.3_9.msi"

function Find-JdkTool([string]$toolExeName, $proc) {
    if ($PSScriptRoot) {
        $c = Join-Path $PSScriptRoot $toolExeName
        if (Test-Path $c) { return $c }
    }
    try {
        if ($proc -and $proc.Path) {
            $c = Join-Path (Split-Path $proc.Path) $toolExeName
            if (Test-Path $c) { return $c }
        }
    } catch {}
    if ($env:JAVA_HOME) {
        $c = Join-Path $env:JAVA_HOME "bin\$toolExeName"
        if (Test-Path $c) { return $c }
    }
    $onPath = Get-Command $toolExeName -ErrorAction SilentlyContinue
    if ($onPath) { return $onPath.Source }
    $roots = @(
        "C:\Program Files\Eclipse Adoptium",
        "C:\Program Files\Java",
        "C:\Program Files\Microsoft",
        "C:\Program Files\Zulu",
        "C:\Program Files\Amazon Corretto",
        "$env:LOCALAPPDATA\Programs\Java"
    )
    foreach ($r in $roots) {
        $hit = Get-ChildItem -Path $r -Filter $toolExeName -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($hit) { return $hit.FullName }
    }
    return $null
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
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
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

function Find-AllJdkToolCandidates([string]$toolExeName, $proc) {
    $candidates = New-Object System.Collections.Generic.List[string]
    if ($PSScriptRoot) {
        $c = Join-Path $PSScriptRoot $toolExeName
        if (Test-Path $c -ErrorAction SilentlyContinue) { [void]$candidates.Add($c) }
    }
    try {
        if ($proc -and $proc.Path) {
            $c = Join-Path (Split-Path $proc.Path) $toolExeName
            if (Test-Path $c -ErrorAction SilentlyContinue) { [void]$candidates.Add($c) }
        }
    } catch {}
    if ($env:JAVA_HOME) {
        $c = Join-Path $env:JAVA_HOME "bin\$toolExeName"
        if (Test-Path $c -ErrorAction SilentlyContinue) { [void]$candidates.Add($c) }
    }
    $onPath = Get-Command $toolExeName -ErrorAction SilentlyContinue
    if ($onPath) { [void]$candidates.Add($onPath.Source) }
    $roots = @(
        "C:\Program Files\Eclipse Adoptium",
        "C:\Program Files\Java",
        "C:\Program Files\Microsoft",
        "C:\Program Files\Zulu",
        "C:\Program Files\Amazon Corretto",
        "$env:LOCALAPPDATA\Programs\Java"
    )
    foreach ($r in $roots) {
        Get-ChildItem -Path $r -Filter $toolExeName -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
            if (-not $candidates.Contains($_.FullName)) { [void]$candidates.Add($_.FullName) }
        }
    }
    return $candidates
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
        Write-Warn "jimage.exe not found next to jcmd - JDK platform classes (java.*, javax.*, etc.) won't be pre-whitelisted and may show as unrecognized in the fallback report."
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
            Write-Warn "No attach-capable JDK found on this machine - provenance mode will fail to attach; the jar-scan whitelist will still run."
        }
    }
} else {
    Write-Fail "Could not obtain a JDK. Classloader dumps require jcmd - aborting."
    exit
}

Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue

function Get-ClassesFromZip($zipArchive, $depth) {
    $localExact = New-Object System.Collections.Generic.HashSet[string]
    $localPackages = New-Object System.Collections.Generic.HashSet[string]
    $localCount = 0
    foreach ($entry in $zipArchive.Entries) {
        if ($entry.FullName.EndsWith(".class")) {
            if ($entry.FullName.StartsWith("META-INF/")) { continue }
            if ($entry.FullName -eq "module-info.class") { continue }
            $qualified = $entry.FullName.Substring(0, $entry.FullName.Length - 6) -replace '/', '.'
            [void]$localExact.Add($qualified)
            $localCount++
            $lastDot = $qualified.LastIndexOf('.')
            if ($lastDot -gt 0) { [void]$localPackages.Add($qualified.Substring(0, $lastDot)) }
        }
        elseif ($depth -lt 5 -and $entry.FullName -match '^META-INF/jars/.*\.jar$') {
            try {
                $ms = New-Object System.IO.MemoryStream
                $es = $entry.Open()
                $es.CopyTo($ms)
                $es.Dispose()
                $ms.Position = 0
                $nestedZip = New-Object System.IO.Compression.ZipArchive($ms, [System.IO.Compression.ZipArchiveMode]::Read)
                $nested = Get-ClassesFromZip $nestedZip ($depth + 1)
                foreach ($c in $nested.Exact) { [void]$localExact.Add($c) }
                foreach ($p in $nested.Packages) { [void]$localPackages.Add($p) }
                $localCount += $nested.Count
                $nestedZip.Dispose()
                $ms.Dispose()
            } catch {}
        }
    }
    return @{ Exact = $localExact; Packages = $localPackages; Count = $localCount }
}

function Add-JarFolderToWhitelist([string]$folder, [System.Collections.Generic.HashSet[string]]$exact, [System.Collections.Generic.HashSet[string]]$packageSet) {
    if (-not $folder -or -not (Test-Path $folder -ErrorAction SilentlyContinue)) { return @{ JarCount = 0; ClassCount = 0 } }
    $jars = Get-ChildItem -Path $folder -Filter "*.jar" -Recurse -ErrorAction SilentlyContinue
    $jarCount = 0
    $classCount = 0
    foreach ($jarFile in $jars) {
        $zip = $null
        try {
            $zip = [System.IO.Compression.ZipFile]::OpenRead($jarFile.FullName)
            $result = Get-ClassesFromZip $zip 0
            foreach ($c in $result.Exact) { [void]$exact.Add($c) }
            foreach ($p in $result.Packages) { [void]$packageSet.Add($p) }
            $classCount += $result.Count
            $zip.Dispose()
            $jarCount++
        }
        catch {
            if ($zip) { try { $zip.Dispose() } catch {} }
            try {
                $names = [TolerantZip]::ListEntries($jarFile.FullName)
                $recovered = Add-EntryNamesToWhitelist $names $exact $packageSet
                $classCount += $recovered
                $jarCount++
            } catch {
            }
        }
    }
    return @{ JarCount = $jarCount; ClassCount = $classCount }
}

function Add-JarFoldersToWhitelist($folders, [System.Collections.Generic.HashSet[string]]$exact, [System.Collections.Generic.HashSet[string]]$packageSet) {
    $totalJars = 0
    $totalClasses = 0
    foreach ($folder in $folders) {
        $r = Add-JarFolderToWhitelist $folder $exact $packageSet
        $totalJars += $r.JarCount
        $totalClasses += $r.ClassCount
    }
    return @{ JarCount = $totalJars; ClassCount = $totalClasses }
}

function Get-TargetModulesImage($proc) {
    if (-not $proc -or -not $proc.Path) { return $null }
    try {
        $javaHome = Split-Path (Split-Path $proc.Path -Parent) -Parent
        $modulesImage = Join-Path $javaHome "lib\modules"
        if (Test-Path $modulesImage -ErrorAction SilentlyContinue) { return $modulesImage }
    } catch {}
    return $null
}

function Add-JdkPlatformClassesToWhitelist([string]$jimagePath, [System.Collections.Generic.HashSet[string]]$exact, [System.Collections.Generic.HashSet[string]]$packageSet, [string]$preferredModulesImage) {
    if (-not $jimagePath -or -not (Test-Path $jimagePath -ErrorAction SilentlyContinue)) { return @{ ClassCount = 0; UsedTarget = $false } }
    try {
        $modulesImage = $null
        $usedTarget = $false
        if ($preferredModulesImage -and (Test-Path $preferredModulesImage -ErrorAction SilentlyContinue)) {
            $modulesImage = $preferredModulesImage
            $usedTarget = $true
        } else {
            $javaHome = Split-Path (Split-Path $jimagePath -Parent) -Parent
            $modulesImage = Join-Path $javaHome "lib\modules"
        }
        if (-not (Test-Path $modulesImage -ErrorAction SilentlyContinue)) { return @{ ClassCount = 0; UsedTarget = $false } }
        $raw = & $jimagePath list $modulesImage 2>&1
        $count = 0
        foreach ($line in $raw) {
            $t = $line.Trim()
            if (-not $t -or $t.StartsWith("Module:") -or -not $t.EndsWith(".class")) { continue }
            if ($t -eq "module-info.class") { continue }
            $qualified = ($t.Substring(0, $t.Length - 6)) -replace '/', '.'
            [void]$exact.Add($qualified)
            $count++
            $lastDot = $qualified.LastIndexOf('.')
            if ($lastDot -gt 0) { [void]$packageSet.Add($qualified.Substring(0, $lastDot)) }
        }
        return @{ ClassCount = $count; UsedTarget = $usedTarget }
    } catch {
        return @{ ClassCount = 0; UsedTarget = $false }
    }
}

$AlwaysTrustedPrefixes = @(
    "net.minecraft",
    "com.mojang",
    "java.lang.invoke",
    "jdk.internal.vm"
)

function Build-JarWhitelist($instanceFolders, [string]$jimagePath, [string]$preferredModulesImage) {
    $exact = New-Object System.Collections.Generic.HashSet[string]
    $packageSet = New-Object System.Collections.Generic.HashSet[string]
    $prefixes = New-Object System.Collections.Generic.List[string]
    foreach ($p in $AlwaysTrustedPrefixes) { [void]$prefixes.Add($p) }

    $modsResult = Add-JarFolderToWhitelist $instanceFolders.Mods $exact $packageSet
    Write-Ok "mods       $($modsResult.JarCount) jar(s), $($modsResult.ClassCount) classes  (incl. jar-in-jar)"

    $libResult = Add-JarFoldersToWhitelist $instanceFolders.Libraries $exact $packageSet
    if ($libResult.JarCount -gt 0) {
        Write-Ok "libraries  $($libResult.JarCount) jar(s), $($libResult.ClassCount) classes  ($($instanceFolders.Libraries.Count) folder(s))"
    } else {
        Write-Dim "libraries  none found next to mods (or empty)"
    }

    $verResult = Add-JarFoldersToWhitelist $instanceFolders.Versions $exact $packageSet
    if ($verResult.JarCount -gt 0) {
        Write-Ok "versions   $($verResult.JarCount) jar(s), $($verResult.ClassCount) classes  ($($instanceFolders.Versions.Count) folder(s))"
    } else {
        Write-Dim "versions   none found next to mods (or empty)"
    }

    $remapResult = Add-JarFoldersToWhitelist $instanceFolders.Remapped $exact $packageSet
    if ($remapResult.JarCount -gt 0) {
        Write-Ok "remapped   $($remapResult.JarCount) jar(s), $($remapResult.ClassCount) classes"
    } else {
        Write-Dim "remapped   no .fabric/.quilt cache found next to mods (or empty)"
    }

    $essResult = Add-JarFoldersToWhitelist $instanceFolders.Essential $exact $packageSet
    if ($essResult.JarCount -gt 0) {
        Write-Ok "essential  $($essResult.JarCount) jar(s), $($essResult.ClassCount) classes"
    } else {
        Write-Dim "essential  not trusted (no Essential_<ver>_<loader>_<mc>.jar in mods, or no essential folder)"
    }

    $jdkResult = Add-JdkPlatformClassesToWhitelist $jimagePath $exact $packageSet $preferredModulesImage
    if ($jdkResult.ClassCount -gt 0) {
        $sourceNote = if ($jdkResult.UsedTarget) { "target's own runtime image" } else { "located jimage's runtime image" }
        Write-Ok "jdk        $($jdkResult.ClassCount) platform classes  ($sourceNote)"
    } else {
        Write-Dim "jdk        not indexed (jimage unavailable) - java.*/javax.*/etc. may show as unrecognized"
    }

    $mixinExtrasPresent = $packageSet | Where-Object { $_ -eq "com.llamalad7.mixinextras" -or $_.StartsWith("com.llamalad7.mixinextras.") } | Select-Object -First 1
    if ($mixinExtrasPresent) {
        [void]$prefixes.Add("com.llamalad7.mixinextras.sugar.impl.ref.generated")
    }

    Write-Info "indexed $($exact.Count) classes across $($packageSet.Count) packages"

    return @{
        Prefixes = $prefixes
        Exact = $exact
        Packages = $packageSet
    }
}

function Get-ClassPathEntries($jcmdPath, $pidNum) {
    try { $raw = & $jcmdPath $pidNum "VM.system_properties" 2>&1 } catch { return @() }
    if (-not $raw) { return @() }
    $lines = ($raw -join "`n") -split "`r?`n"
    $joined = New-Object System.Collections.Generic.List[string]
    $buffer = $null
    foreach ($line in $lines) {
        $buffer = if ($null -ne $buffer) { $buffer + $line } else { $line }
        if ($buffer -match '(?<!\\)(\\\\)*\\$') {
            $buffer = $buffer.Substring(0, $buffer.Length - 1)
            continue
        }
        $joined.Add($buffer)
        $buffer = $null
    }
    if ($buffer) { $joined.Add($buffer) }
    $cpLine = $joined | Where-Object { $_ -match '^\s*java\.class\.path\s*=' } | Select-Object -First 1
    if (-not $cpLine) { return @() }
    $value = $cpLine -replace '^\s*java\.class\.path\s*=', ''
    $value = $value -replace '\\:', ':' -replace '\\=', '=' -replace '\\\\', '\'
    return ($value -split [regex]::Escape([IO.Path]::PathSeparator)) | Where-Object { $_ -and $_.Trim() -ne '' }
}

function Merge-ClasspathIntoWhitelist($whitelist, $entries) {
    foreach ($raw in $entries) {
        $path = $raw.Trim()

        if (-not $path -or -not (Test-Path $path)) {
            continue
        }

        try {
            $item = Get-Item -LiteralPath $path -ErrorAction Stop

            if ($item.PSIsContainer) {
                Get-ChildItem -LiteralPath $path -Filter "*.class" -Recurse -ErrorAction SilentlyContinue |
                    ForEach-Object {
                        $rel = $_.FullName.Substring($path.Length).TrimStart('\','/').Replace('\','/').Replace('/','.')
                        $qualified = $rel.Substring(0, $rel.Length - 6)

                        [void]$whitelist.Exact.Add($qualified)

                        $lastDot = $qualified.LastIndexOf('.')
                        if ($lastDot -gt 0) {
                            [void]$whitelist.Packages.Add($qualified.Substring(0, $lastDot))
                        }
                    }
            }
            elseif ($path -match '\.jar$') {
                $zip = $null
                try {
                    $zip = [System.IO.Compression.ZipFile]::OpenRead($path)
                    $result = Get-ClassesFromZip $zip 0

                    foreach ($c in $result.Exact) {
                        [void]$whitelist.Exact.Add($c)
                    }

                    foreach ($p in $result.Packages) {
                        [void]$whitelist.Packages.Add($p)
                    }

                    $zip.Dispose()
                } catch {
                    if ($zip) { try { $zip.Dispose() } catch {} }
                    $names = [TolerantZip]::ListEntries($path)
                    [void](Add-EntryNamesToWhitelist $names $whitelist.Exact $whitelist.Packages)
                }
            }
        }
        catch {}
    }
}

$SyntheticSuffixPattern = '\$(class|method|field)_\d+$|\$\d+$|\$\$Lambda(\$\d+)?$|\$\$InjectedInvoker$|\$Proxy\d+$'

function Test-KnownClass($className, $whitelist) {
    if ($whitelist.Exact.Contains($className)) {
        return $true
    }

    foreach ($p in $whitelist.Prefixes) {
        if ($className -eq $p -or $className.StartsWith("$p.")) {
            return $true
        }
    }

    if ($className -match '^(com\.sun\.proxy\.)?jdk\.proxy\d+\.\$Proxy\d+$' -or
        $className -match '^com\.sun\.proxy\.\$Proxy\d+$') {
        return $true
    }

    $base = $className
    while ($base -match $SyntheticSuffixPattern) {
        $base = $base -replace $SyntheticSuffixPattern, ''
        if (-not $base) { break }
        if ($whitelist.Exact.Contains($base)) { return $true }
        foreach ($p in $whitelist.Prefixes) {
            if ($base -eq $p -or $base.StartsWith("$p.")) { return $true }
        }
    }

    return $false
}

function Extract-ClassNames($rawText) {
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


function Build-ProvenanceAgent([string]$javacPath, [string]$jarPath) {
    $ErrorActionPreference = 'Continue'
    $buildDir = Join-Path $env:TEMP ("p1ae-provenance-{0}" -f ([guid]::NewGuid().ToString("N").Substring(0, 8)))
    New-Item -ItemType Directory -Path $buildDir -Force | Out-Null

    $agentSrc = Join-Path $buildDir "ProvenanceAgent.java"
    $launcherSrc = Join-Path $buildDir "AttachLauncher.java"
    $manifestPath = Join-Path $buildDir "agent-manifest.mf"
    $agentJarPath = Join-Path $buildDir "provenance-agent.jar"

    @'
import java.lang.instrument.Instrumentation;
import java.security.CodeSource;
import java.security.ProtectionDomain;
import java.io.PrintWriter;
import java.io.FileWriter;

public class ProvenanceAgent {
    public static void agentmain(String agentArgs, Instrumentation inst) {
        try (PrintWriter out = new PrintWriter(new FileWriter(agentArgs, false), true)) {
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
                try { hidden = resolved.isHidden(); } catch (Throwable t) {}
                try { synthetic = resolved.isSynthetic(); } catch (Throwable t) {}
                try { anon = resolved.isAnonymousClass(); } catch (Throwable t) {}

                out.println(name + "\t" + loaderName + "\t" + codeSourceLoc + "\t" + hidden + "\t" + synthetic + "\t" + anon);
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
        & $javacPath --add-modules jdk.attach -d $buildDir $agentSrc $launcherSrc 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { return @{ Success = $false; Reason = "javac failed (exit $LASTEXITCODE)" } }
        Push-Location $buildDir
        try {
            & $jarPath cfm $agentJarPath $manifestPath "ProvenanceAgent.class" 2>&1 | Out-Null
        } finally { Pop-Location }
        if (-not (Test-Path $agentJarPath -ErrorAction SilentlyContinue)) { return @{ Success = $false; Reason = "agent jar build failed" } }
    } catch {
        return @{ Success = $false; Reason = $_.Exception.Message }
    }

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
    foreach ($line in (Get-Content -LiteralPath $path -Encoding UTF8)) {
        if (-not $line) { continue }
        $parts = $line -split "`t"
        if ($parts.Count -lt 6) { continue }
        $records.Add([PSCustomObject]@{
            Name       = $parts[0]
            Loader     = $parts[1]
            CodeSource = $parts[2]
            Hidden     = $parts[3]
            Synthetic  = $parts[4]
            Anon       = $parts[5]
        })
    }
    return $records
}

function ConvertFrom-CodeSourceUrl([string]$url) {
    if (-not $url -or $url -eq "NONE" -or $url -eq "ERROR") { return $null }
    if ($url.StartsWith("jrt:")) { return @{ Type = "JRT"; Path = $url } }
    $inner = $url
    if ($inner.StartsWith("jar:")) {
        $inner = $inner.Substring(4)
        $bang = $inner.IndexOf("!")
        if ($bang -ge 0) { $inner = $inner.Substring(0, $bang) }
    }
    if ($inner.StartsWith("file:")) {
        try {
            $path = ([Uri]$inner).LocalPath
            return @{ Type = "FILE"; Path = $path }
        } catch { return @{ Type = "FILE"; Path = $inner } }
    }
    return @{ Type = "OTHER"; Path = $url }
}

function Resolve-TrustedPaths($paths) {
    $resolved = New-Object System.Collections.Generic.List[object]
    foreach ($p in $paths) {
        if (-not $p -or -not (Test-Path $p -ErrorAction SilentlyContinue)) { continue }
        $full = (Resolve-Path $p -ErrorAction SilentlyContinue).ProviderPath
        if (-not $full) { continue }
        $isDir = (Get-Item -LiteralPath $full -ErrorAction SilentlyContinue).PSIsContainer
        $resolved.Add([PSCustomObject]@{ Path = $full.TrimEnd('\', '/'); IsDir = [bool]$isDir; Label = $p })
    }
    return $resolved
}

function Find-TrustedPathMatch([string]$path, $resolvedTrustedPaths) {
    if (-not $path) { return $null }
    $trimmed = $path.TrimEnd('\', '/')
    foreach ($t in $resolvedTrustedPaths) {
        if ($t.IsDir) {
            if ($trimmed.StartsWith($t.Path, [StringComparison]::OrdinalIgnoreCase)) { return $t.Label }
        } else {
            if ($trimmed -ieq $t.Path) { return $t.Label }
        }
    }
    return $null
}

function Test-KnownByProvenance($rec, $resolvedTrustedPaths) {
    if ($rec.Loader -eq "BOOTSTRAP") { return @{ Known = $true; Reason = "JDK bootstrap loader" } }
    if ($rec.Loader -match "PlatformClassLoader") { return @{ Known = $true; Reason = "JDK platform loader" } }

    if ($rec.Name -eq "ProvenanceAgent" -or $rec.Name -eq "AttachLauncher") {
        return @{ Known = $true; Reason = "this tool's own agent/launcher class" }
    }

    if ($rec.Name -match '^\[+(L.+;|[BCDFIJSZ])$') {
        return @{ Known = $true; Reason = "array type (JVM-synthesized on demand, never itself a file on disk - its element type is checked independently wherever it appears on its own)" }
    }

    if ($rec.Name -match '^(com\.sun\.proxy\.)?jdk\.proxy\d+\.\$Proxy\d+$' -or $rec.Name -match '^com\.sun\.proxy\.\$Proxy\d+$') {
        return @{ Known = $true; Reason = "JDK dynamic proxy class (java.lang.reflect.Proxy)" }
    }

    $loc = ConvertFrom-CodeSourceUrl $rec.CodeSource
    if ($loc -and $loc.Type -eq "JRT") { return @{ Known = $true; Reason = "JDK runtime image (jrt:)" } }

    if ($loc -and $loc.Type -eq "FILE" -and $loc.Path) {
        $hit = Find-TrustedPathMatch $loc.Path $resolvedTrustedPaths
        if ($hit) { return @{ Known = $true; Reason = "loaded from $hit" } }
        if ($script:EssentialTrusted -and $rec.Loader -match 'gg\.essential\.util\.classloader\.RelaunchClassLoader') {
            $leaf = Split-Path $loc.Path -Leaf
            $dir = (Split-Path $loc.Path -Parent).TrimEnd('\', '/')
            $tempDirs = @([System.IO.Path]::GetTempPath(), $env:TEMP, $env:TMP) | Where-Object { $_ } | ForEach-Object { $_.TrimEnd('\', '/') }
            $inTemp = ($tempDirs | Where-Object { $_ -ieq $dir } | Select-Object -First 1) -or ($dir -imatch '\\AppData\\Local\\Temp$')
            if ($inTemp -and $leaf -match '^essential-lwjgl[0-9]+\.jar$') {
                return @{ Known = $true; Reason = "Essential's extracted LWJGL jar in the temp folder (Essential is installed in mods)" }
            }
        }
        return @{ Known = $false; Reason = "loaded from a file outside all known locations: $($loc.Path)" }
    }

    if ($rec.CodeSource -eq "NONE" -and ($rec.Hidden -eq "true" -or $rec.Synthetic -eq "true" -or $rec.Anon -eq "true")) {
        return @{ Known = $true; Reason = "JVM-generated in memory (hidden/synthetic/anonymous, no backing file)" }
    }

    if ($rec.CodeSource -eq "NONE") {
        return @{ Known = $false; Reason = "no classloader/codesource and not flagged hidden or synthetic - unusual, worth a look" }
    }

    return @{ Known = $false; Reason = "unrecognized codesource: $($rec.CodeSource)" }
}

$ProvenanceMode = $false
$provenanceAgent = $null
if ($CompareMode -and $javacExe -and $jarExe -and $javaExe) {
    Write-Section "Provenance agent"
    Write-Info "Building the provenance agent..."
    $provenanceAgent = Build-ProvenanceAgent $javacExe $jarExe
    if ($provenanceAgent.Success) {
        $ProvenanceMode = $true
        Write-Ok "Agent built - class origin will be checked directly against the running JVM"
    } else {
        Write-Warn "Could not build the provenance agent ($($provenanceAgent.Reason)) - falling back to the jar-scan whitelist only"
    }
} elseif ($CompareMode) {
    Write-Host ""
    Write-Dim "javac/jar/java not all found next to this JDK - provenance mode unavailable, using the jar-scan whitelist only"
}

$TargetModulesImage = Get-TargetModulesImage $firstJavaProc

$whitelist = $null
if ($CompareMode) {
    Write-Section "Known-class whitelist"
    Write-Info "Building from mods + libraries + versions + JDK..."
    try {
        $whitelist = Build-JarWhitelist $instanceFolders $jimage $TargetModulesImage
    } catch {
        Write-Fail "Failed to build whitelist: $($_.Exception.Message)"
        Write-Info "Continuing in Normal mode (no comparison)."
        $CompareMode = $false
    }
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
$UnknownFile = $null
if ($CompareMode) {
    $UnknownFile = Join-Path $downloads ("Classloaders-Unknown_{0}.txt" -f $stamp)
    @(
        "P1ae's Classloader Dump - UNKNOWN CLASSES REPORT"
        "Mods folder scanned : $modsFolder"
        "Date                : $(Get-Date)"
        "Machine             : $env:COMPUTERNAME   User: $env:USERNAME"
        ($gBar * 60)
        ($gBar * 60)
    ) -join "`r`n" | Set-Content -Path $UnknownFile -Encoding UTF8
}
$ProvenanceFullFile = $null
$ProvenanceUnknownFile = $null
if ($ProvenanceMode) {
    $ProvenanceFullFile = Join-Path $downloads ("Provenance-Full_{0}.txt" -f $stamp)
    $ProvenanceUnknownFile = Join-Path $downloads ("Provenance-Unknown_{0}.txt" -f $stamp)
    @(
        "P1ae's Classloader Dump - PROVENANCE REPORT"
        "Date     : $(Get-Date)"
        ($gBar * 60)
    ) -join "`r`n" | Set-Content -Path $ProvenanceFullFile -Encoding UTF8
    @(
        "P1ae's Classloader Dump - PROVENANCE UNKNOWN CLASSES REPORT"
        "Date     : $(Get-Date)"
        ($gBar * 60)
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
if ($CompareMode -and $whitelist) {
    Write-Info "Expanding whitelist from the running JVM's actual classpath..."
    $cpJarsSeen = 0
    foreach ($proc in $targetProcs) {
        try {
            $entries = Get-ClassPathEntries $jcmd $proc.Id
            Merge-ClasspathIntoWhitelist $whitelist $entries
            $cpJarsSeen += ($entries | Measure-Object).Count
        } catch {
            Write-Warn "Could not read classpath for PID $($proc.Id): $($_.Exception.Message)"
        }
    }
    Write-Ok "Folded in $cpJarsSeen classpath entries"
}

Write-Section "Classloader dumps"
$allUnknown = New-Object System.Collections.Generic.SortedSet[string]
foreach ($j in $jobs) {
    Add-Content $j.File "`r`nUsing jcmd: $jcmd"
    Write-Host ""
    Write-Host "  $gDiamond " -NoNewline -ForegroundColor Cyan
    Write-Host "$($j.Title)" -ForegroundColor White
    foreach ($proc in $targetProcs) {
        $pidNum = $proc.Id
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
            if ($CompareMode -and $j.Short -eq "Classloaders-Full" -and $output) {
                $classes = Extract-ClassNames $outputText
                $unknownForProc = $classes | Where-Object { -not (Test-KnownClass $_ $whitelist) } | Sort-Object
                if ($unknownForProc) {
                    Add-Content $UnknownFile "`r`n$($gBar * 60)"
                    Add-Content $UnknownFile "PROCESS  : $($proc.ProcessName)   PID: $pidNum"
                    Add-Content $UnknownFile ($gBar * 60)
                    foreach ($u in $unknownForProc) {
                        Add-Content $UnknownFile $u
                        [void]$allUnknown.Add($u)
                    }
                    Write-Note "$($unknownForProc.Count) unrecognized class(es) for PID $pidNum" 4
                } else {
                    Add-Content $UnknownFile "`r`n$($gBar * 60)"
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

$allProvenanceUnknown = New-Object System.Collections.Generic.SortedSet[string]
$script:EssentialTrusted = [bool]($instanceFolders -and $instanceFolders.Essential -and (@($instanceFolders.Essential).Count -gt 0))
if ($ProvenanceMode) {
    Write-Section "Provenance check"
    foreach ($proc in $targetProcs) {
        $pidNum = $proc.Id
        $reportPath = Join-Path $provenanceAgent.BuildDir ("report_{0}.tsv" -f $pidNum)
        $attachResult = Invoke-ProvenanceAgent $javaExe $provenanceAgent.BuildDir $provenanceAgent.AgentJar $pidNum $reportPath
        Add-Content $ProvenanceFullFile "`r`n$($gBar * 60)`r`nPROCESS  : $($proc.ProcessName)   PID: $pidNum`r`n$($gBar * 60)"
        if (-not $attachResult.Success) {
            Add-Content $ProvenanceFullFile "[!] AGENT ATTACH FAILED: $($attachResult.Error)"
            if ($attachResult.Error -match "jdk\.attach|FindException") {
                Add-Content $ProvenanceFullFile "    (This specific error means the javac/java this script found - a system-wide install, not the target's own bundled runtime - doesn't have the jdk.attach module in its own boot layer. That's an environment/JDK-distribution mismatch, not a sign of blocking: jcmd above still attached fine using its own built-in mechanism, which is why the Classloaders-* files above are still complete. The Classloaders-Unknown fallback report is the one to check for this run.)"
            } else {
                Add-Content $ProvenanceFullFile "    (A cheat that blocks the Attach API can cause this - check whether the jcmd dumps above show the same failure; if THOSE also failed, that's the stronger signal.)"
            }
            Write-Fail "PID $pidNum provenance attach failed"
            continue
        }
        $cpEntries = @()
        try { $cpEntries = Get-ClassPathEntries $jcmd $pidNum } catch {}
        $trustedRaw = @($instanceFolders.Mods) + @($instanceFolders.Libraries) + @($instanceFolders.Versions) + @($instanceFolders.Remapped) + @($instanceFolders.Essential) + @($cpEntries) + @($provenanceAgent.AgentJar)
        $resolvedTrustedPaths = Resolve-TrustedPaths $trustedRaw
        $records = Import-ProvenanceReport $reportPath
        $unknownCount = 0
        foreach ($rec in $records) {
            Add-Content $ProvenanceFullFile "$($rec.Name)`t$($rec.Loader)`t$($rec.CodeSource)"
            $verdict = Test-KnownByProvenance $rec $resolvedTrustedPaths
            if (-not $verdict.Known) {
                Add-Content $ProvenanceUnknownFile "$($rec.Name)  [loader=$($rec.Loader)] [codesource=$($rec.CodeSource)] - $($verdict.Reason)"
                [void]$allProvenanceUnknown.Add($rec.Name)
                $unknownCount++
            }
        }
        if ($unknownCount -gt 0) {
            Write-Note "PID $pidNum - $($records.Count) loaded classes checked by origin, $unknownCount unaccounted for"
        } else {
            Write-Ok "PID $pidNum - $($records.Count) loaded classes checked by origin, 0 unaccounted for"
        }
    }
    Add-Content $ProvenanceUnknownFile "`r`n$($gBar * 60)`r`nTOTAL UNIQUE UNACCOUNTED-FOR CLASSES: $($allProvenanceUnknown.Count)`r`n$($gBar * 60)"
}

if ($CompareMode) {
    Add-Content $UnknownFile "`r`n$($gBar * 60)"
    Add-Content $UnknownFile "TOTAL UNIQUE UNRECOGNIZED CLASSES: $($allUnknown.Count)"
    Add-Content $UnknownFile ($gBar * 60)
}

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
if ($CompareMode) {
    $uc = if ($allUnknown.Count -gt 0) { "Magenta" } else { "Green" }
    Write-SavedFile "Classloaders-Unknown.txt" $UnknownFile "($($allUnknown.Count) unique)" $uc
}
if ($ProvenanceMode) {
    Write-SavedFile "Provenance-Full.txt" $ProvenanceFullFile
    $pc = if ($allProvenanceUnknown.Count -gt 0) { "Magenta" } else { "Green" }
    Write-SavedFile "Provenance-Unknown.txt" $ProvenanceUnknownFile "  ($($allProvenanceUnknown.Count) unique)" $pc
}
if ($CompareMode) {
    $fileCount = if ($ProvenanceMode) { "ALL FIVE" } else { "ALL THREE" }
    Write-Host ""
    Write-Box @("Send $fileCount .txt files to the staff member running your SS.") 'Green' @('White')
    Write-Host ""
}
exit
