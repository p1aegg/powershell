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

$MsiUrl  = "https://github.com/adoptium/temurin25-binaries/releases/download/jdk-25.0.3%2B9/OpenJDK25U-jdk_x64_windows_hotspot_25.0.3_9.msi"
$MsiName = "OpenJDK25U-jdk_x64_windows_hotspot_25.0.3_9.msi"

$DefaultModsFolder = "$env:APPDATA\.minecraft\mods"

$CoreBaselinePrefixes = @(
    "java", "javax", "jdk", "sun", "com.sun", "org.w3c", "org.xml",
    "net.minecraft", "com.mojang",
    "org.lwjgl", "io.netty", "com.google", "org.apache", "it.unimi.dsi.fastutil",
    "com.electronwill.nightconfig", "joptsimple",
    "net.fabricmc", "net.minecraftforge", "net.neoforged", "cpw.mods",
    "org.spongepowered", "org.objectweb.asm",
    "org.joml", "org.slf4j", "org.quiltmc",
    "com.ibm.icu",
    "oshi",
    "com.llamalad7.mixinextras",
    "org.prismlauncher",
    "org.multimc", "org.polymc",
    "com.atlauncher",
    "org.jcp.xml.dsig",
    "com.jcraft"
)

$sepMenu = "━" * 100
Write-Host $sepMenu -ForegroundColor Magenta
Write-Host "SELECT MODE" -ForegroundColor Magenta
Write-Host $sepMenu -ForegroundColor Magenta
Write-Host ""
Write-Host "  [1] Normal           - Just run the classloader dumps" -ForegroundColor White
Write-Host "  [2] Normal + Compare - Also scan a mods folder you point it at, build a known-good class list from those jars, and produce a third file containing ONLY the unrecognized classes" -ForegroundColor White
Write-Host ""

$CompareMode = $false
$choice = Read-Host "Enter 1 or 2"
if ($choice.Trim() -eq "2") {
    $CompareMode = $true

    $modsFolder = $null
    if (-not [string]::IsNullOrWhiteSpace($DefaultModsFolder) -and (Test-Path $DefaultModsFolder)) {
        Write-Host "  [i] Default mods folder found: $DefaultModsFolder" -ForegroundColor DarkGray
        $useDefault = Read-Host "  Press Enter to use it, or paste a different mods folder path"
        $modsFolder = if ([string]::IsNullOrWhiteSpace($useDefault)) { $DefaultModsFolder } else { $useDefault }
    } else {
        $modsFolder = Read-Host "Enter the full path to the mods folder to compare against"
    }

    if ([string]::IsNullOrWhiteSpace($modsFolder) -or -not (Test-Path $modsFolder)) {
        Write-Host "  [!] Mods folder not found - falling back to Normal mode." -ForegroundColor Yellow
        $CompareMode = $false
    }
}
Write-Host ""

Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue

function Get-ClassesFromZip($zipArchive, $depth) {
    $localExact    = New-Object System.Collections.Generic.HashSet[string]
    $localPackages = New-Object System.Collections.Generic.HashSet[string]
    $localCount    = 0

    foreach ($entry in $zipArchive.Entries) {
        if ($entry.FullName.EndsWith(".class")) {
            if ($entry.FullName.StartsWith("META-INF/")) { continue }
            if ($entry.FullName -eq "module-info.class") { continue }

            $qualified = $entry.FullName.Substring(0, $entry.FullName.Length - 6) -replace '/', '.'
            [void]$localExact.Add($qualified)
            $localCount++

            $lastDot = $qualified.LastIndexOf('.')
            if ($lastDot -gt 0) {
                [void]$localPackages.Add($qualified.Substring(0, $lastDot))
            }
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
    $exact    = New-Object System.Collections.Generic.HashSet[string]

    foreach ($p in $CoreBaselinePrefixes) { $prefixes.Add($p) }

    $jars = Get-ChildItem -Path $modsFolder -Filter "*.jar" -Recurse -ErrorAction SilentlyContinue
    $jarCount = 0
    $nestedJarCount = 0
    $classCount = 0
    $packageSet = New-Object System.Collections.Generic.HashSet[string]

    foreach ($jarFile in $jars) {
        try {
            $zip = [System.IO.Compression.ZipFile]::OpenRead($jarFile.FullName)
            $before = $packageSet.Count
            $result = Get-ClassesFromZip $zip 0
            foreach ($c in $result.Exact) { [void]$exact.Add($c) }
            foreach ($p in $result.Packages) { [void]$packageSet.Add($p) }
            $classCount += $result.Count
            $zip.Dispose()
            $jarCount++
        } catch {
            Write-Host "  [!] Could not read jar: $($jarFile.Name) - $($_.Exception.Message)" -ForegroundColor DarkYellow
        }
    }

    foreach ($pkg in $packageSet) { $prefixes.Add($pkg) }

    Write-Host "  [✓] Scanned $jarCount jar(s) (including nested jar-in-jar deps) in $modsFolder" -ForegroundColor Green
    Write-Host "  [✓] Indexed $classCount classes across $($packageSet.Count) packages (+ $($CoreBaselinePrefixes.Count) baseline core packages)`n" -ForegroundColor Green

    return @{ Prefixes = $prefixes; Exact = $exact }
}

function Get-ClassPathEntries($jcmdPath, $pidNum) {
    try {
        $raw = & $jcmdPath $pidNum "VM.system_properties" 2>&1
    } catch { return @() }
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

    return ($value -split [regex]::Escape([IO.Path]::PathSeparator)) |
        Where-Object { $_ -and $_.Trim() -ne '' }
}

function Merge-ClasspathIntoWhitelist($whitelist, $entries) {
    foreach ($raw in $entries) {
        $path = $raw.Trim()
        if (-not $path -or -not (Test-Path $path)) { continue }
        try {
            $item = Get-Item -LiteralPath $path -ErrorAction Stop
            if ($item.PSIsContainer) {
                Get-ChildItem -LiteralPath $path -Filter "*.class" -Recurse -ErrorAction SilentlyContinue |
                    ForEach-Object {
                        $rel = $_.FullName.Substring($path.Length).TrimStart('\', '/').Replace('\', '/').Replace('/', '.')
                        $qualified = $rel.Substring(0, $rel.Length - 6)
                        [void]$whitelist.Exact.Add($qualified)
                        $lastDot = $qualified.LastIndexOf('.')
                        if ($lastDot -gt 0) { $whitelist.Prefixes.Add($qualified.Substring(0, $lastDot)) }
                    }
            }
            elseif ($path -match '\.jar$') {
                $zip = [System.IO.Compression.ZipFile]::OpenRead($path)
                $result = Get-ClassesFromZip $zip 0
                foreach ($c in $result.Exact) { [void]$whitelist.Exact.Add($c) }
                foreach ($p in $result.Packages) { $whitelist.Prefixes.Add($p) }
                $zip.Dispose()
            }
        } catch {}
    }
}

function Test-KnownClass($className, $whitelist) {
    if ($whitelist.Exact.Contains($className)) { return $true }
    foreach ($p in $whitelist.Prefixes) {
        if ($className -eq $p -or $className.StartsWith("$p.")) { return $true }
    }
    return $false
}

function Extract-ClassNames($rawText) {
    $found = New-Object System.Collections.Generic.HashSet[string]
    $pattern = '(?:[a-zA-Z_$][a-zA-Z0-9_$]*\.)+[a-zA-Z_$][a-zA-Z0-9_$]*'
    foreach ($line in ($rawText -split "`r?`n")) {
        if ($line -match 'unique loaded classes' -or $line -match '^COMMAND' -or $line -match '^PROCESS' -or $line -match '^EXE' -or $line -match '^━+$') { continue }
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
    Write-Host "  [i] Building known-classes whitelist from mods folder..." -ForegroundColor Yellow
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
    @{ Cmd = "VM.classloaders";              Short = "Classloaders-Tree"; Title = "VM.classloaders" }
)

$downloads = Join-Path $env:USERPROFILE "Downloads"
if (-not (Test-Path $downloads)) { $downloads = [Environment]::GetFolderPath("Desktop") }
$stamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

foreach ($j in $jobs) {
    $j.File = Join-Path $downloads ("{0}_{1}.txt" -f $j.Short, $stamp)
    @(
        "P1ae's Classloader Dump"
        "Command : jcmd <pid> $($j.Title)"
        "Date    : $(Get-Date)"
        "Machine : $env:COMPUTERNAME   User: $env:USERNAME"
        ("━" * 60)
    ) -join "`r`n" | Set-Content -Path $j.File -Encoding UTF8
}

$UnknownFile = $null
if ($CompareMode) {
    $UnknownFile = Join-Path $downloads ("Unknown-Classes_{0}.txt" -f $stamp)
    @(
        "P1ae's Classloader Dump - UNKNOWN CLASSES REPORT"
        "Mods folder scanned : $modsFolder"
        "Date             : $(Get-Date)"
        "Machine          : $env:COMPUTERNAME   User: $env:USERNAME"
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
    (New-Object Security.Principal.WindowsPrincipal $id).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-Temurin {
    if (-not (Test-Admin)) {
        Write-Host "  [i] Need admin to install the JDK - relaunching elevated..." -ForegroundColor Yellow
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

$javaProcs = Get-Process -Name javaw, java -ErrorAction SilentlyContinue
if (-not $javaProcs) {
    Write-Host "  [!] No javaw/java process found" -ForegroundColor Red
    Write-Host "  [i] Make sure Minecraft is running`n" -ForegroundColor Yellow
    foreach ($j in $jobs) { Add-Content $j.File "`r`nNO JAVA PROCESS FOUND - Minecraft was not running." }
    Write-Host "Press any key to exit..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown"); exit
}

Write-Host "  [i] Found $($javaProcs.Count) Java process(es)" -ForegroundColor White
foreach ($p in $javaProcs) {
    try {
        $up = (Get-Date) - $p.StartTime
        Write-Host "  ┌─ $($p.Name) PID $($p.Id)" -ForegroundColor Green
        Write-Host "  └─ Uptime: $($up.Hours)h $($up.Minutes)m $($up.Seconds)s" -ForegroundColor DarkGreen
    } catch {}
}
Write-Host ""

$jcmd = Find-Jcmd $javaProcs[0]
if (-not $jcmd) { Write-Host "  [i] jcmd not found locally" -ForegroundColor Yellow; $jcmd = Install-Temurin }
if (-not $jcmd) {
    Write-Host "  [!] Could not obtain jcmd. Aborting." -ForegroundColor Red
    foreach ($j in $jobs) { Add-Content $j.File "`r`n[!] jcmd unavailable - no diagnostics collected." }
    Write-Host "Press any key to exit..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown"); exit
}
Write-Host "  [✓] Using jcmd: $jcmd`n" -ForegroundColor Green

if ($CompareMode -and $whitelist) {
    Write-Host "  [i] Expanding whitelist from the running JVM's actual classpath..." -ForegroundColor Yellow
    Write-Host "  [i] (this is what makes the check launcher-agnostic - Modrinth, Prism, CurseForge, MultiMC, ATLauncher, vanilla, etc. all work the same way here)" -ForegroundColor DarkGray
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
        $pidNum   = $proc.Id
        $procPath = if ($proc.Path) { $proc.Path } else { "(path unavailable)" }

        Add-Content $j.File "`r`n$('━' * 60)"
        Add-Content $j.File "PROCESS : $($proc.ProcessName)  PID: $pidNum"
        Add-Content $j.File "EXE     : $procPath"
        Add-Content $j.File "COMMAND : jcmd $pidNum $($j.Cmd)"
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
                    Add-Content $UnknownFile "PROCESS : $($proc.ProcessName)  PID: $pidNum"
                    Add-Content $UnknownFile ("━" * 60)
                    foreach ($u in $unknownForProc) {
                        Add-Content $UnknownFile $u
                        [void]$allUnknown.Add($u)
                    }
                    Write-Host "  ║ " -NoNewline -ForegroundColor Cyan; Write-Host "[i] $($unknownForProc.Count) unrecognized class(es) for PID $pidNum" -ForegroundColor Magenta
                } else {
                    Add-Content $UnknownFile "`r`n$('━' * 60)"
                    Add-Content $UnknownFile "PROCESS : $($proc.ProcessName)  PID: $pidNum - no unrecognized classes found"
                    Add-Content $UnknownFile ("━" * 60)
                }
            }
        } catch {
            Add-Content $j.File "[!] ATTACH FAILED: $($_.Exception.Message)"
            Add-Content $j.File "    (A cheat that blocks the Attach API can cause this - worth a closer look.)"
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
    Write-Host "  ║ " -NoNewline -ForegroundColor DarkGray; Write-Host "Saved  " -NoNewline -ForegroundColor White; Write-Host "$($j.Short).txt" -ForegroundColor Green
    Write-Host "  ║ " -NoNewline -ForegroundColor DarkGray; Write-Host "Path   " -NoNewline -ForegroundColor White; Write-Host "$($j.File)" -ForegroundColor DarkGray
    Write-Host "  ╚══════════════════════════════════════════" -ForegroundColor DarkGray
    Write-Host ""
}

if ($CompareMode) {
    Write-Host "  ╔══════════════════════════════════════════" -ForegroundColor DarkGray
    Write-Host "  ║ " -NoNewline -ForegroundColor DarkGray; Write-Host "Saved  " -NoNewline -ForegroundColor White; Write-Host "Unknown-Classes.txt ($($allUnknown.Count) unique)" -ForegroundColor Magenta
    Write-Host "  ║ " -NoNewline -ForegroundColor DarkGray; Write-Host "Path   " -NoNewline -ForegroundColor White; Write-Host "$UnknownFile" -ForegroundColor DarkGray
    Write-Host "  ╚══════════════════════════════════════════" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [i] Send ALL THREE .txt files to the staff member running your SS.`n" -ForegroundColor Cyan
} else {
    Write-Host "  [i] Send BOTH .txt files to the staff member running your SS.`n" -ForegroundColor Cyan
}

Write-Host "Press any key to exit..." -ForegroundColor DarkGray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")