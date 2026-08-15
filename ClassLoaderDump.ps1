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
Write-Host "P1ae's Classloader Dump v1.1".PadLeft(($lineWidth + 37) / 2) -ForegroundColor Cyan
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
Write-Host "`n"
$RawBaseUrl = "https://raw.githubusercontent.com/p1aegg/powershell/main/CoreBaselineClasses.txt"

function Get-BaselineFileContent([string]$fileName) {
    if ($PSScriptRoot) {
        $localPath = Join-Path $PSScriptRoot $fileName
        if (Test-Path -LiteralPath $localPath -ErrorAction SilentlyContinue) {
            return Get-Content -LiteralPath $localPath -Encoding UTF8
        }
    }
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $resp = Invoke-RestMethod -Uri "$RawBaseUrl/$fileName" -ErrorAction Stop
        return ($resp -split "`r?`n")
    } catch {
        Write-Host "  [!] Could not load $fileName locally or remotely: $($_.Exception.Message)" -ForegroundColor DarkYellow
        return @()
    }
}

$CoreBaselinePrefixes = @(
    Get-BaselineFileContent "CoreBaselineClasses.txt" | Where-Object { $_ -and $_.Trim() -ne '' }
)

$CoreBaselinePackagePrefixes = @(
    "net.minecraft",
    "java",
    "javax",
    "jdk",
    "sun",
    "com.sun",
    "org.w3c.dom",
    "org.xml.sax",
    "org.ietf.jgss",
    "org.jcp.xml.dsig"
    "com.mojang.blaze3d.opengl",
    "com.mojang.blaze3d.systems",
    "com.mojang.blaze3d.vertex",
    "com.llamalad7.mixinextras",
    "org.spongepowered.asm.synthetic.args",
    "org.ladysnake.cca.internal.base.asm"
)
$exactFileCandidates = @(
    (Join-Path $PSScriptRoot "CoreBaselineExact.txt"),
    (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "CoreBaselineExact.txt"),
    (Join-Path $PWD "CoreBaselineExact.txt")
)
$exactLoaded = $false
foreach ($ef in $exactFileCandidates) {
    if ($ef -and (Test-Path -LiteralPath $ef -ErrorAction SilentlyContinue)) {
        $CoreBaselinePrefixes = @(Get-Content -LiteralPath $ef -Encoding UTF8 | Where-Object { $_ -and $_.Trim() -ne '' })
        Write-Host " [i] Loaded $($CoreBaselinePrefixes.Count) exact baseline class names from: $ef" -ForegroundColor DarkGray
        $exactLoaded = $true
        break
    }
}
if (-not $exactLoaded) {}

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
function Resolve-ModsFolder([string]$cwd) {
    if (-not $cwd -or -not (Test-Path $cwd -ErrorAction SilentlyContinue)) { return $null }
    foreach ($base in (Get-LayoutBases $cwd)) {
        $p = Join-Path $base "mods"
        if (Test-Path $p -ErrorAction SilentlyContinue) { return $p }
    }
    try {
        foreach ($entry in (Get-ChildItem -LiteralPath $cwd -Directory -ErrorAction SilentlyContinue)) {
            foreach ($base in (Get-LayoutBases $entry.FullName)) {
                $p = Join-Path $base "mods"
                if (Test-Path $p -ErrorAction SilentlyContinue) { return $p }
            }
        }
    } catch {}
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
$modsFolder = $null
Write-Host "`n[i] Detecting mods folder for the running Minecraft instance..." -ForegroundColor Yellow
$javaProcs = Get-Process -Name javaw -ErrorAction SilentlyContinue
if ($javaProcs) {
    foreach ($proc in $javaProcs) {
        $cwd = Get-ProcessCurrentDirectory -processId $proc.Id
        if ($cwd) {
            $candidate = Resolve-ModsFolder $cwd
            if ($candidate) {
                $modsFolder = $candidate
                Write-Host "  [✓] Found via process CWD (PEB): $modsFolder" -ForegroundColor Green
                break
            }
        }
    }
}
if (-not $modsFolder) {
    Write-Host "  [i] PEB path found no mods folder – scanning every launcher's instances for the most recently updated logs\latest.log..." -ForegroundColor DarkGray
    $latestBase = Find-LatestInstanceByLog
    if ($latestBase) {
        $candidate = Resolve-ModsFolder $latestBase
        if ($candidate) {
            $modsFolder = $candidate
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
                $candidate = Resolve-ModsFolder $cwd
                if ($candidate) {
                    $modsFolder = $candidate
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

function Build-JarWhitelist($modsFolder) {
    $prefixes = New-Object System.Collections.Generic.List[string]
    $exact = New-Object System.Collections.Generic.HashSet[string]
    $packageSet = New-Object System.Collections.Generic.HashSet[string]

    foreach ($c in $CoreBaselinePrefixes) {
        if ($c) { [void]$exact.Add($c) }
    }

    foreach ($p in $CoreBaselinePackagePrefixes) {
        if ($p) { [void]$prefixes.Add($p) }
    }

    $jars = Get-ChildItem -Path $modsFolder -Filter "*.jar" -Recurse -ErrorAction SilentlyContinue
    $jarCount = 0
    $classCount = 0

    foreach ($jarFile in $jars) {
        try {
            $zip = [System.IO.Compression.ZipFile]::OpenRead($jarFile.FullName)
            $result = Get-ClassesFromZip $zip 0

            foreach ($c in $result.Exact) {
                [void]$exact.Add($c)
            }

            foreach ($p in $result.Packages) {
                [void]$packageSet.Add($p)
            }

            $classCount += $result.Count
            $zip.Dispose()
            $jarCount++
        }
        catch {
            Write-Host "  [!] Could not read jar: $($jarFile.Name) - $($_.Exception.Message)" -ForegroundColor DarkYellow
        }
    }

    Write-Host "  [✓] Scanned $jarCount jar(s) (including nested jar-in-jar deps)" -ForegroundColor Green
    Write-Host "  [✓] Indexed $classCount classes across $($packageSet.Count) packages, matched EXACTLY (+ $($CoreBaselinePackagePrefixes.Count) baseline package prefixes, $($CoreBaselinePrefixes.Count) exact baseline classes)`n" -ForegroundColor Green

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

function Test-KnownClass($className, $whitelist) {
    if ($whitelist.Exact.Contains($className)) {
        return $true
    }

    foreach ($p in $whitelist.Prefixes) {
        if ($className -eq $p -or $className.StartsWith("$p.")) {
            return $true
        }
    }

    if ($className -match '\$\$(Lambda|InjectedInvoker)$') {
        $declaringClass = $className -replace '\$\$(Lambda|InjectedInvoker)$', ''

        if ($whitelist.Exact.Contains($declaringClass)) {
            return $true
        }

        foreach ($p in $whitelist.Prefixes) {
            if ($declaringClass -eq $p -or $declaringClass.StartsWith("$p.")) {
                return $true
            }
        }
    }

    if ($className -match '\$Proxy\d+$') {
        $declaringClass = $className -replace '\$Proxy\d+$', ''

        if ($whitelist.Exact.Contains($declaringClass)) {
            return $true
        }

        foreach ($p in $whitelist.Prefixes) {
            if ($declaringClass -eq $p -or $declaringClass.StartsWith("$p.")) {
                return $true
            }
        }

        $proxyPackage = $className -replace '\.\$Proxy\d+$', ''

        if ($proxyPackage -and $whitelist.Packages.Contains($proxyPackage)) {
            return $true
        }

        foreach ($pkg in $whitelist.Packages) {
            if ($proxyPackage -eq $pkg -or $proxyPackage.StartsWith("$pkg.")) {
                return $true
            }
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

$whitelist = $null
if ($CompareMode) {
    Write-Host "`n[i] Building known-classes whitelist from mods folder..." -ForegroundColor Yellow
    try {
        $whitelist = Build-JarWhitelist $modsFolder
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
        "Classes below appeared in the dump but were NOT matched against the whitelist."
        "This is a heuristic - review manually before drawing conclusions."
        ("━" * 60)
    ) -join "`r`n" | Set-Content -Path $UnknownFile -Encoding UTF8
}

function Find-Jcmd($proc) {
    if ($PSScriptRoot) {
        $c = Join-Path $PSScriptRoot "jcmd.exe"
        if (Test-Path $c) { return $c }
    }
    try {
        if ($proc -and $proc.Path) {
            $c = Join-Path (Split-Path $proc.Path) "jcmd.exe"
            if (Test-Path $c) { return $c }
        }
    } catch {}
    if ($env:JAVA_HOME) {
        $c = Join-Path $env:JAVA_HOME "bin\jcmd.exe"
        if (Test-Path $c) { return $c }
    }
    $onPath = Get-Command jcmd.exe -ErrorAction SilentlyContinue
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
        $hit = Get-ChildItem -Path $r -Filter jcmd.exe -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($hit) { return $hit.FullName }
    }
    return $null
}
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
$jcmd = Find-Jcmd $javaProcs[0]
if (-not $jcmd) { Write-Host "  [i] jcmd not found locally" -ForegroundColor Yellow; $jcmd = Install-Temurin }
if (-not $jcmd) {
    Write-Host "  [!] Could not obtain jcmd. Aborting." -ForegroundColor Red
    foreach ($j in $jobs) { Add-Content $j.File "`r`n[!] jcmd unavailable – no diagnostics collected." }
    exit
}
Write-Host "  [✓] Using jcmd: $jcmd`n" -ForegroundColor Green
if ($CompareMode -and $whitelist) {
    Write-Host "  [i] Expanding whitelist from the running JVM's actual classpath..." -ForegroundColor Yellow
    $cpJarsSeen = 0
    foreach ($proc in $javaProcs) {
        try {
            $entries = Get-ClassPathEntries $jcmd $proc.Id
            Merge-ClasspathIntoWhitelist $whitelist $entries
            $cpJarsSeen += ($entries | Measure-Object).Count
        } catch {
            Write-Host "  [!] Could not read classpath for PID $($proc.Id): $($_.Exception.Message)" -ForegroundColor DarkYellow
        }
    }
    Write-Host "  [✓] Folded in $cpJarsSeen classpath entries (loader jar, launcher wrapper, vanilla libraries, etc.)`n" -ForegroundColor Green
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
    foreach ($proc in $javaProcs) {
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
            Add-Content $j.File "    (A cheat that blocks the Attach API can cause this – worth a closer look.)"
            Write-Host "  ║ " -NoNewline -ForegroundColor Cyan; Write-Host "[!] PID $pidNum attach failed" -ForegroundColor Red
        }
    }
    Add-Content $j.File "`r`n$('━' * 60)`r`nEnd of report."
    Write-Host "  ╚══════════════════════════════════════════" -ForegroundColor Cyan
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
    Write-Host "  [i] Send ALL THREE .txt files to the staff member running your SS.`n" -ForegroundColor Cyan
}
exit
