[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Stop"
Clear-Host
Write-Host "Made by p1ae (Fork of YarpLetapStan)`nDm p1ae for Questions or Bugs`n" -ForegroundColor Cyan
Write-Host @"
 ██████╗██╗      █████╗ ███████╗███████╗██╗      ██████╗  █████╗ ██████╗ ███████╗██████╗
██╔════╝██║     ██╔══██╗██╔════╝██╔════╝██║     ██╔═══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗
██║     ██║     ███████║███████╗███████╗██║     ██║   ██║███████║██║  ██║█████╗  ██████╔╝
██║     ██║     ██╔══██║╚════██║╚════██║██║     ██║   ██║██╔══██║██║  ██║██╔══╝  ██╔══██╗
╚██████╗███████╗██║  ██║███████║███████║███████╗╚██████╔╝██║  ██║██████╔╝███████╗██║  ██║
 ╚═════╝╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═════╝ ╚══════╝╚═╝  ╚═╝
"@ -ForegroundColor Blue
Write-Host @"
██████╗ ██╗   ██╗███╗   ███╗██████╗
██╔══██╗██║   ██║████╗ ████║██╔══██╗
██║  ██║██║   ██║██╔████╔██║██████╔╝
██║  ██║██║   ██║██║╚██╔╝██║██╔═══╝
██████╔╝╚██████╔╝██║ ╚═╝ ██║██║
╚═════╝  ╚═════╝ ╚═╝     ╚═╝╚═╝
"@ -ForegroundColor Blue
$lineWidth = 100
Write-Host "P1ae's Classloader Dump v1.2".PadLeft(($lineWidth + 37) / 2) -ForegroundColor Cyan
Write-Host ("━" * $lineWidth) -ForegroundColor Cyan
Write-Host ""
$sepMenu = "━" * 100
Write-Host $sepMenu -ForegroundColor Magenta
Write-Host "SELECT ACTION" -ForegroundColor Magenta
Write-Host $sepMenu -ForegroundColor Magenta
Write-Host ""
Write-Host "  [1] Start  - Run classloader dumps with built‑in comparison" -ForegroundColor White
Write-Host "  [2] Exit   - Close this tool" -ForegroundColor White
$key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
$choice = $key.Character.ToString()
if ($choice -eq "2") {
    Write-Host "`nExiting..."
    exit
}
if ($choice -ne "1") {
    Write-Host "`nInvalid choice. Exiting."
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
        $candidate = Join-Path $current $folderName
        if (Test-Path $candidate -ErrorAction SilentlyContinue) { [void]$found.Add($candidate) }
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
    Write-Host "  [i] Checked $checked instance log(s) across all known launchers" -ForegroundColor DarkGray
    if ($bestBase) { Write-Host "  [i] Newest latest.log: $bestTime  →  $bestBase" -ForegroundColor DarkGray }
    return $bestBase
}

$CompareMode = $true
$instanceFolders = $null
$modsFolder = $null
Write-Host "`n[i] Detecting mods folder for the running Minecraft instance..." -ForegroundColor Yellow
$javaProcs = Get-Process -Name javaw -ErrorAction SilentlyContinue
if ($javaProcs) {
    foreach ($proc in $javaProcs) {
        $cwd = Get-ProcessCurrentDirectory -processId $proc.Id
        if ($cwd) {
            $candidate = Resolve-InstanceFolders $cwd
            if ($candidate) {
                $instanceFolders = $candidate
                $modsFolder = $candidate.Mods
                Write-Host "  [✓] $modsFolder" -ForegroundColor Green
                break
            }
        }
    }
}
if (-not $modsFolder) {
    Write-Host "  [i] PEB path found no mods folder – scanning every launcher's instances for the most recently updated logs\latest.log..." -ForegroundColor DarkGray
    $latestBase = Find-LatestInstanceByLog
    if ($latestBase) {
        $candidate = Resolve-InstanceFolders $latestBase
        if ($candidate) {
            $instanceFolders = $candidate
            $modsFolder = $candidate.Mods
            Write-Host "  [✓] Found via newest latest.log: $modsFolder" -ForegroundColor Green
        } else {
            Write-Host "  [!] Newest latest.log found at $latestBase but no matching mods folder next to it" -ForegroundColor DarkYellow
        }
    }
}
if (-not $modsFolder -and $javaProcs) {
    Write-Host "  [i] Trying Win32_Process CWD fallback..." -ForegroundColor DarkGray
    foreach ($proc in $javaProcs) {
        try {
            $info = Get-CimInstance -ClassName Win32_Process -Filter "ProcessId = $($proc.Id)" -ErrorAction Stop
            if ($info -and $info.CurrentDirectory) {
                $cwd = $info.CurrentDirectory
                Write-Host "  [i] Win32_Process CWD for PID $($proc.Id): $cwd" -ForegroundColor DarkGray
                $candidate = Resolve-InstanceFolders $cwd
                if ($candidate) {
                    $instanceFolders = $candidate
                    $modsFolder = $candidate.Mods
                    Write-Host "  [✓] Found via Win32_Process: $modsFolder" -ForegroundColor Green
                    break
                }
            }
        } catch {}
    }
}
if (-not $modsFolder) {
    Write-Host "`n[!] Could not detect the mods folder. Comparison will be skipped." -ForegroundColor Yellow
    Write-Host "    Only the basic classloader dumps will be produced." -ForegroundColor Yellow
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
        Write-Host "  [i] Need admin to install the JDK – relaunching elevated..." -ForegroundColor Yellow
        Start-Process powershell.exe -Verb RunAs -ArgumentList @("-ExecutionPolicy","Bypass","-File","`"$PSCommandPath`"")
        exit
    }
    $msiPath = Join-Path $env:TEMP $MsiName
    Write-Host "  [i] Downloading Temurin 25 JDK (~180 MB)..." -ForegroundColor Yellow
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $MsiUrl -OutFile $msiPath -UseBasicParsing
    } catch {
        Write-Host "  [!] Download failed: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
    Write-Host "  [i] Installing silently..." -ForegroundColor Yellow
    Start-Process msiexec.exe -ArgumentList "/i `"$msiPath`" /qn /norestart" -Wait | Out-Null
    Remove-Item $msiPath -ErrorAction SilentlyContinue
    return (Find-Jcmd $null)
}

Write-Host "`n[i] Locating a JDK (jcmd + jimage + javac + jar + java)..." -ForegroundColor Yellow
$firstJavaProc = if ($javaProcs) { $javaProcs[0] } else { $null }
$jcmd = Find-Jcmd $firstJavaProc
if (-not $jcmd) {
    Write-Host "  [i] jcmd not found locally" -ForegroundColor Yellow
    $jcmd = Install-Temurin
}
$jimage = $null
$javacExe = $null
$jarExe = $null
$javaExe = $null
if ($jcmd) {
    Write-Host "  [✓] Using jcmd: $jcmd" -ForegroundColor Green
    $jimage = Find-Jimage $firstJavaProc
    if ($jimage) {
        Write-Host "  [✓] Using jimage: $jimage" -ForegroundColor Green
    } else {
        Write-Host "  [!] jimage.exe not found next to jcmd - JDK platform classes (java.*, javax.*, etc.) won't be pre-whitelisted and may show as unrecognized in the fallback report." -ForegroundColor Yellow
    }
    $javacExe = Find-JdkTool "javac.exe" $firstJavaProc
    $jarExe   = Find-JdkTool "jar.exe" $firstJavaProc
    $javaExe  = Find-JdkTool "java.exe" $firstJavaProc
} else {
    Write-Host "  [!] Could not obtain a JDK. Classloader dumps require jcmd - aborting." -ForegroundColor Red
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
            Write-Host "  [!] Could not read jar: $($jarFile.Name) - $($_.Exception.Message)" -ForegroundColor DarkYellow
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

function Add-JdkPlatformClassesToWhitelist([string]$jimagePath, [System.Collections.Generic.HashSet[string]]$exact, [System.Collections.Generic.HashSet[string]]$packageSet) {
    if (-not $jimagePath -or -not (Test-Path $jimagePath -ErrorAction SilentlyContinue)) { return @{ ClassCount = 0 } }
    try {
        $javaHome = Split-Path (Split-Path $jimagePath -Parent) -Parent
        $modulesImage = Join-Path $javaHome "lib\modules"
        if (-not (Test-Path $modulesImage -ErrorAction SilentlyContinue)) { return @{ ClassCount = 0 } }
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
        return @{ ClassCount = $count }
    } catch {
        return @{ ClassCount = 0 }
    }
}

$AlwaysTrustedPrefixes = @(
    "net.minecraft",
    "com.mojang",
    "java.lang.invoke",
    "jdk.internal.vm"
)

function Build-JarWhitelist($instanceFolders, [string]$jimagePath) {
    $exact = New-Object System.Collections.Generic.HashSet[string]
    $packageSet = New-Object System.Collections.Generic.HashSet[string]
    $prefixes = New-Object System.Collections.Generic.List[string]
    foreach ($p in $AlwaysTrustedPrefixes) { [void]$prefixes.Add($p) }

    $modsResult = Add-JarFolderToWhitelist $instanceFolders.Mods $exact $packageSet
    Write-Host "  [✓] Scanned $($modsResult.JarCount) mod jar(s) (including nested jar-in-jar deps) - $($modsResult.ClassCount) classes" -ForegroundColor Green

    $libResult = Add-JarFoldersToWhitelist $instanceFolders.Libraries $exact $packageSet
    if ($libResult.JarCount -gt 0) {
        Write-Host "  [✓] Scanned $($libResult.JarCount) library jar(s) across $($instanceFolders.Libraries.Count) libraries folder(s) - $($libResult.ClassCount) classes" -ForegroundColor Green
    } else {
        Write-Host "  [i] No libraries folder found next to mods (or it was empty)" -ForegroundColor DarkGray
    }

    $verResult = Add-JarFoldersToWhitelist $instanceFolders.Versions $exact $packageSet
    if ($verResult.JarCount -gt 0) {
        Write-Host "  [✓] Scanned $($verResult.JarCount) version/game jar(s) across $($instanceFolders.Versions.Count) versions folder(s) - $($verResult.ClassCount) classes" -ForegroundColor Green
    } else {
        Write-Host "  [i] No versions folder found next to mods (or it was empty)" -ForegroundColor DarkGray
    }

    $remapResult = Add-JarFoldersToWhitelist $instanceFolders.Remapped $exact $packageSet
    if ($remapResult.JarCount -gt 0) {
        Write-Host "  [✓] Scanned $($remapResult.JarCount) remapped game jar(s) - $($remapResult.ClassCount) classes" -ForegroundColor Green
    } else {
        Write-Host "  [i] No .fabric/.quilt remapped-jar cache found next to mods (or it was empty)" -ForegroundColor DarkGray
    }

    $jdkResult = Add-JdkPlatformClassesToWhitelist $jimagePath $exact $packageSet
    if ($jdkResult.ClassCount -gt 0) {
        Write-Host "  [✓] Indexed $($jdkResult.ClassCount) JDK platform classes via jimage" -ForegroundColor Green
    } else {
        Write-Host "  [i] JDK platform classes were not indexed (jimage unavailable) - java.*/javax.*/etc. may show as unrecognized" -ForegroundColor DarkGray
    }

    $mixinExtrasPresent = $packageSet | Where-Object { $_ -eq "com.llamalad7.mixinextras" -or $_.StartsWith("com.llamalad7.mixinextras.") } | Select-Object -First 1
    if ($mixinExtrasPresent) {
        [void]$prefixes.Add("com.llamalad7.mixinextras.sugar.impl.ref.generated")
    }

    Write-Host "  [✓] Indexed $($exact.Count) classes across $($packageSet.Count) packages`n" -ForegroundColor Green

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
                $zip = [System.IO.Compression.ZipFile]::OpenRead($path)
                $result = Get-ClassesFromZip $zip 0

                foreach ($c in $result.Exact) {
                    [void]$whitelist.Exact.Add($c)
                }

                foreach ($p in $result.Packages) {
                    [void]$whitelist.Packages.Add($p)
                }

                $zip.Dispose()
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
    $pattern = '(?:[a-zA-Z_$][a-zA-Z0-9_$]*\.)+[a-zA-Z_$][a-zA-Z0-9_$]*'
    foreach ($line in ($rawText -split "`r?`n")) {
        if ($line -match 'unique loaded classes' -or $line -match '^COMMAND' -or
            $line -match '^PROCESS' -or $line -match '^EXE' -or $line -match '^━+$') { continue }
        $clean = $line -replace '@[0-9a-fA-F]+', ''
        $clean = $clean -replace '\[+L([a-zA-Z_$][a-zA-Z0-9_$.]*);', '$1'
        foreach ($m in [regex]::Matches($clean, $pattern)) {
            [void]$found.Add($m.Value)
        }
    }
    return $found
}


function Build-ProvenanceAgent([string]$javacPath, [string]$jarPath) {
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
    Write-Host "`n[i] Building the provenance agent..." -ForegroundColor Yellow
    $provenanceAgent = Build-ProvenanceAgent $javacExe $jarExe
    if ($provenanceAgent.Success) {
        $ProvenanceMode = $true
        Write-Host "  [✓] Provenance agent built - class origin will be checked directly against the running JVM" -ForegroundColor Green
    } else {
        Write-Host "  [!] Could not build the provenance agent ($($provenanceAgent.Reason)) - falling back to the jar-scan whitelist only" -ForegroundColor DarkYellow
    }
} elseif ($CompareMode) {
    Write-Host "`n[i] javac/jar/java not all found next to this JDK - provenance mode unavailable, using the jar-scan whitelist only" -ForegroundColor DarkGray
}

$whitelist = $null
if ($CompareMode) {
    Write-Host "`n[i] Building the fallback known-classes whitelist from mods + libraries + versions + JDK..." -ForegroundColor Yellow
    try {
        $whitelist = Build-JarWhitelist $instanceFolders $jimage
    } catch {
        Write-Host "  [!] Failed to build whitelist: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  [i] Continuing in Normal mode (no comparison).`n" -ForegroundColor Yellow
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
        ("━" * 60)
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
        ("━" * 60)
        ("━" * 60)
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
        ("━" * 60)
    ) -join "`r`n" | Set-Content -Path $ProvenanceFullFile -Encoding UTF8
    @(
        "P1ae's Classloader Dump - PROVENANCE UNKNOWN CLASSES REPORT"
        "Date     : $(Get-Date)"
        ("━" * 60)
    ) -join "`r`n" | Set-Content -Path $ProvenanceUnknownFile -Encoding UTF8
}

$sep = "━" * 111
Write-Host $sep -ForegroundColor Yellow
Write-Host "MINECRAFT PROCESS SCANNER" -ForegroundColor Yellow
Write-Host $sep -ForegroundColor Yellow
Write-Host ""
$javaProcs = Get-Process -Name javaw -ErrorAction SilentlyContinue
if (-not $javaProcs) {
    Write-Host "  [!] No javaw process found" -ForegroundColor Red
    Write-Host "  [i] Make sure Minecraft is running`n" -ForegroundColor Yellow
    foreach ($j in $jobs) { Add-Content $j.File "`r`nNO JAVA PROCESS FOUND – Minecraft was not running." }
    exit
}
Write-Host "  [i] Found $($javaProcs.Count) Java process(es)" -ForegroundColor White
foreach ($p in $javaProcs) {
    try {
        $up = (Get-Date) - $p.StartTime
        Write-Host "  ┌─ $($p.Name)  PID $($p.Id)" -ForegroundColor Green
        Write-Host "  └─ Uptime: $($up.Hours)h $($up.Minutes)m $($up.Seconds)s" -ForegroundColor DarkGreen
    } catch {}
}
Write-Host ""

$targetProcs = $javaProcs
if ($instanceFolders -and $instanceFolders.Base -and $javaProcs) {
    $matched = New-Object System.Collections.Generic.List[object]
    foreach ($p in $javaProcs) {
        $procBase = Get-ProcessInstanceBase $p
        if ($procBase -and ($procBase.TrimEnd('\') -ieq $instanceFolders.Base.TrimEnd('\'))) {
            $matched.Add($p)
        } else {
            $label = if ($procBase) { $procBase } else { "(instance undetermined)" }
            Write-Host "  [i] PID $($p.Id) belongs to a different instance ($label) - skipping" -ForegroundColor DarkGray
        }
    }
    if ($matched.Count -gt 0) {
        $targetProcs = $matched
    } else {
        Write-Host "  [!] Couldn't match any running process back to the detected instance - falling back to dumping all javaw processes" -ForegroundColor DarkYellow
    }
    Write-Host ""
}

Write-Host "  [✓] Using jcmd: $jcmd`n" -ForegroundColor Green
if ($CompareMode -and $whitelist) {
    Write-Host "  [i] Expanding whitelist from the running JVM's actual classpath..." -ForegroundColor Yellow
    $cpJarsSeen = 0
    foreach ($proc in $targetProcs) {
        try {
            $entries = Get-ClassPathEntries $jcmd $proc.Id
            Merge-ClasspathIntoWhitelist $whitelist $entries
            $cpJarsSeen += ($entries | Measure-Object).Count
        } catch {
            Write-Host "  [!] Could not read classpath for PID $($proc.Id): $($_.Exception.Message)" -ForegroundColor DarkYellow
        }
    }
    Write-Host "  [✓] Folded in $cpJarsSeen classpath entries`n" -ForegroundColor Green
}
Write-Host $sep -ForegroundColor Cyan
Write-Host "RUNNING CLASSLOADER DUMPS" -ForegroundColor Cyan
Write-Host $sep -ForegroundColor Cyan
Write-Host ""
$allUnknown = New-Object System.Collections.Generic.SortedSet[string]
foreach ($j in $jobs) {
    Add-Content $j.File "`r`nUsing jcmd: $jcmd"
    Write-Host "  ╔══════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  ║ " -NoNewline -ForegroundColor Cyan; Write-Host "$($j.Title)" -ForegroundColor White
    Write-Host "  ╠══════════════════════════════════════════" -ForegroundColor Cyan
    foreach ($proc in $targetProcs) {
        $pidNum = $proc.Id
        $procPath = if ($proc.Path) { $proc.Path } else { "(path unavailable)" }
        Add-Content $j.File "`r`n$('━' * 60)"
        Add-Content $j.File "PROCESS  : $($proc.ProcessName)   PID: $pidNum"
        Add-Content $j.File "EXE      : $procPath"
        Add-Content $j.File "COMMAND  : jcmd $pidNum $($j.Cmd)"
        Add-Content $j.File ("━" * 60)
        try {
            $output = & $jcmd $pidNum $j.Cmd.Split(" ") 2>&1
            $outputText = if ($output) { $output -join "`r`n" } else { "(no output)" }
            Add-Content $j.File $outputText
            Write-Host "  ║ " -NoNewline -ForegroundColor Cyan; Write-Host "[✓] PID $pidNum dumped" -ForegroundColor Green
            if ($CompareMode -and $j.Short -eq "Classloaders-Full" -and $output) {
                $classes = Extract-ClassNames $outputText
                $unknownForProc = $classes | Where-Object { -not (Test-KnownClass $_ $whitelist) } | Sort-Object
                if ($unknownForProc) {
                    Add-Content $UnknownFile "`r`n$('━' * 60)"
                    Add-Content $UnknownFile "PROCESS  : $($proc.ProcessName)   PID: $pidNum"
                    Add-Content $UnknownFile ("━" * 60)
                    foreach ($u in $unknownForProc) {
                        Add-Content $UnknownFile $u
                        [void]$allUnknown.Add($u)
                    }
                    Write-Host "  ║ " -NoNewline -ForegroundColor Cyan
                    Write-Host "[i] $($unknownForProc.Count) unrecognized class(es) for PID $pidNum" -ForegroundColor Magenta
                } else {
                    Add-Content $UnknownFile "`r`n$('━' * 60)"
                    Add-Content $UnknownFile "PROCESS  : $($proc.ProcessName)   PID: $pidNum  – no unrecognized classes found"
                    Add-Content $UnknownFile ("━" * 60)
                }
            }
        } catch {
            Add-Content $j.File "[!] ATTACH FAILED: $($_.Exception.Message)"
            Add-Content $j.File "    (A jvm argument like -XX:+DisableAttachMechanism can cause this, Lunar Client has this as default.)"
            Write-Host "  ║ " -NoNewline -ForegroundColor Cyan; Write-Host "[!] PID $pidNum attach failed" -ForegroundColor Red
        }
    }
    Add-Content $j.File "`r`n$('━' * 60)`r`nEnd of report."
    Write-Host "  ╚══════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}

$allProvenanceUnknown = New-Object System.Collections.Generic.SortedSet[string]
if ($ProvenanceMode) {
    Write-Host $sep -ForegroundColor Cyan
    Write-Host "RUNNING PROVENANCE AGENT" -ForegroundColor Cyan
    Write-Host $sep -ForegroundColor Cyan
    Write-Host ""
    foreach ($proc in $targetProcs) {
        $pidNum = $proc.Id
        $reportPath = Join-Path $provenanceAgent.BuildDir ("report_{0}.tsv" -f $pidNum)
        $attachResult = Invoke-ProvenanceAgent $javaExe $provenanceAgent.BuildDir $provenanceAgent.AgentJar $pidNum $reportPath
        Add-Content $ProvenanceFullFile "`r`n$('━' * 60)`r`nPROCESS  : $($proc.ProcessName)   PID: $pidNum`r`n$('━' * 60)"
        if (-not $attachResult.Success) {
            Add-Content $ProvenanceFullFile "[!] AGENT ATTACH FAILED: $($attachResult.Error)"
            Add-Content $ProvenanceFullFile "    (A jvm argument like -XX:+DisableAttachMechanism can cause this, Lunar Client has this as default.)"
            Write-Host "  [!] PID $pidNum provenance attach failed" -ForegroundColor Red
            continue
        }
        $cpEntries = @()
        try { $cpEntries = Get-ClassPathEntries $jcmd $pidNum } catch {}
        $trustedRaw = @($instanceFolders.Mods) + @($instanceFolders.Libraries) + @($instanceFolders.Versions) + @($instanceFolders.Remapped) + @($cpEntries) + @($provenanceAgent.AgentJar)
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
        Write-Host "  [✓] PID $pidNum - $($records.Count) loaded classes checked by origin, $unknownCount unaccounted for" -ForegroundColor Green
    }
    Add-Content $ProvenanceUnknownFile "`r`n$('━' * 60)`r`nTOTAL UNIQUE UNACCOUNTED-FOR CLASSES: $($allProvenanceUnknown.Count)`r`n$('━' * 60)"
    Write-Host ""
}

if ($CompareMode) {
    Add-Content $UnknownFile "`r`n$('━' * 60)"
    Add-Content $UnknownFile "TOTAL UNIQUE UNRECOGNIZED CLASSES: $($allUnknown.Count)"
    Add-Content $UnknownFile ("━" * 60)
}
Write-Host ("━" * 50) -ForegroundColor Cyan
Write-Host "  DUMP COMPLETE" -ForegroundColor Cyan
Write-Host ("━" * 50) -ForegroundColor Cyan
Write-Host ""
foreach ($j in $jobs) {
    Write-Host "  ╔══════════════════════════════════════════" -ForegroundColor DarkGray
    Write-Host "  ║ " -NoNewline -ForegroundColor DarkGray; Write-Host "Saved " -NoNewline -ForegroundColor White; Write-Host "$($j.Short).txt" -ForegroundColor Green
    Write-Host "  ║ " -NoNewline -ForegroundColor DarkGray; Write-Host "Path  " -NoNewline -ForegroundColor White; Write-Host "$($j.File)" -ForegroundColor DarkGray
    Write-Host "  ╚══════════════════════════════════════════" -ForegroundColor DarkGray
    Write-Host ""
}
if ($CompareMode) {
    Write-Host "  ╔══════════════════════════════════════════" -ForegroundColor DarkGray
    Write-Host "  ║ " -NoNewline -ForegroundColor DarkGray; Write-Host "Saved " -NoNewline -ForegroundColor White
    Write-Host "Classloaders-Unknown.txt ($($allUnknown.Count) unique)" -ForegroundColor Magenta
    Write-Host "  ║ " -NoNewline -ForegroundColor DarkGray; Write-Host "Path  " -NoNewline -ForegroundColor White; Write-Host "$UnknownFile" -ForegroundColor DarkGray
    Write-Host "  ╚══════════════════════════════════════════" -ForegroundColor DarkGray
    Write-Host ""
}
if ($ProvenanceMode) {
    Write-Host "  ╔══════════════════════════════════════════" -ForegroundColor DarkGray
    Write-Host "  ║ " -NoNewline -ForegroundColor DarkGray; Write-Host "Saved " -NoNewline -ForegroundColor White; Write-Host "Provenance-Full.txt" -ForegroundColor Green
    Write-Host "  ║ " -NoNewline -ForegroundColor DarkGray; Write-Host "Path  " -NoNewline -ForegroundColor White; Write-Host "$ProvenanceFullFile" -ForegroundColor DarkGray
    Write-Host "  ╚══════════════════════════════════════════" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════" -ForegroundColor DarkGray
    Write-Host "  ║ " -NoNewline -ForegroundColor DarkGray; Write-Host "Saved " -NoNewline -ForegroundColor White
    Write-Host "Provenance-Unknown.txt ($($allProvenanceUnknown.Count) unique)" -ForegroundColor Magenta
    Write-Host "  ║ " -NoNewline -ForegroundColor DarkGray; Write-Host "Path  " -NoNewline -ForegroundColor White; Write-Host "$ProvenanceUnknownFile" -ForegroundColor DarkGray
    Write-Host "  ╚══════════════════════════════════════════" -ForegroundColor DarkGray
    Write-Host ""
}
if ($CompareMode) {
    $fileCount = if ($ProvenanceMode) { "ALL FIVE" } else { "ALL THREE" }
    Write-Host "  [i] Send $fileCount .txt files to the staff member running your SS.`n" -ForegroundColor Cyan
}
exit
