[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Continue"
$gCheck=[string][char]0x2713; $gChev=[string][char]0x203A; $gDot=[string][char]0x00B7; $gWarn=[string][char]0x25B2
$gCross=[string][char]0x2717; $gDiamond=[string][char]0x25C6; $gH=[string][char]0x2500; $gTL=[string][char]0x256D
$gTR=[string][char]0x256E; $gV=[string][char]0x2502; $gBL=[string][char]0x2570; $gBR=[string][char]0x256F
$gPrompt=[string][char]0x276F; $gArrow=[string][char]0x2192; $gDash=[string][char]0x2013; $gBar=[string][char]0x2501
$gTri=[string][char]0x25B8; $gHead=[string][char]0x2578

$script:UiWidth = 76
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
    $fill = $script:UiWidth - 8 - $label.Length
    if ($fill -lt 3) { $fill = 3 }
    Write-Host ""
    Write-Host ("  {0:00}" -f $script:SectionNo) -NoNewline -ForegroundColor Cyan
    Write-Host "  $label " -NoNewline -ForegroundColor White
    Write-Host ($gH * $fill) -ForegroundColor DarkGray
}

function Write-Box([string[]]$lines, [string]$color = 'Cyan', [string[]]$colors = $null) {
    $inner = $script:UiWidth - 4
    Write-Host ($gTL + ($gH * ($script:UiWidth - 2)) + $gTR) -ForegroundColor $color
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $c = if ($colors -and $i -lt $colors.Count) { $colors[$i] } else { 'White' }
        Write-Host ($gV + ' ') -NoNewline -ForegroundColor $color
        Write-Host ([string]$lines[$i]).PadRight($inner) -NoNewline -ForegroundColor $c
        Write-Host (' ' + $gV) -ForegroundColor $color
    }
    Write-Host ($gBL + ($gH * ($script:UiWidth - 2)) + $gBR) -ForegroundColor $color
}

function Show-Bar([int]$pct, [int]$done, [int]$total, [bool]$final = $false) {
    $width  = 36
    $filled = [int][Math]::Floor($width * $pct / 100)
    $accent = if ($final) { 'Green' } else { 'Cyan' }
    Write-Host "`r  " -NoNewline
    Write-Host ($(if ($final) { $gCheck } else { $gTri }) + " ") -NoNewline -ForegroundColor $accent
    if ($filled -gt 0) { Write-Host ($gBar * $filled) -NoNewline -ForegroundColor $accent }
    $rest = $width - $filled
    if ($rest -gt 0) {
        Write-Host $gHead -NoNewline -ForegroundColor White
        if ($rest -gt 1) { Write-Host ($gH * ($rest - 1)) -NoNewline -ForegroundColor DarkGray }
    }
    Write-Host (" {0,3}%" -f $pct) -NoNewline -ForegroundColor White
    Write-Host ("  $gDot  {0}/{1} files   " -f $done, $total) -NoNewline -ForegroundColor DarkGray
}

Clear-Host
Write-Host ""
Write-Box @(
    "A L T   C H E C K E R",
    "v1.0.0",
    "",
    "Finds Discord + Minecraft accounts cached on this PC"
) 'Cyan' @('Cyan', 'DarkGray', 'White', 'Gray', 'Gray')

Write-Host ""
Write-Host "  Select an action" -ForegroundColor White
Write-Host ("  " + ($gH * ($script:UiWidth - 4))) -ForegroundColor DarkGray
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

Add-Type -AssemblyName System.IO.Compression -ErrorAction SilentlyContinue
$script:Latin1 = [System.Text.Encoding]::GetEncoding(28591)
$script:MaxScanFile = 16MB
$script:Rx = [System.Text.RegularExpressions.RegexOptions]::CultureInvariant

function Read-SharedBytes([string]$path) {
    $fs = $null
    try {
        $share = [System.IO.FileShare]::ReadWrite -bor [System.IO.FileShare]::Delete
        $fs = [System.IO.File]::Open($path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, $share)
        $len = [int][Math]::Min($fs.Length, [long][int]::MaxValue)
        $buf = New-Object byte[] $len
        $read = 0
        while ($read -lt $len) {
            $n = $fs.Read($buf, $read, $len - $read)
            if ($n -le 0) { break }
            $read += $n
        }
        if ($read -ne $len) { [Array]::Resize([ref]$buf, $read) }
        return ,$buf
    } catch {
        return $null
    } finally {
        if ($fs) { $fs.Dispose() }
    }
}

function Read-TextFile([string]$path) {
    $bytes = Read-SharedBytes $path
    if (-not $bytes -or $bytes.Length -eq 0) { return "" }
    if ($path -match '\.gz$') {
        try {
            $ms = New-Object System.IO.MemoryStream(,$bytes)
            $gz = New-Object System.IO.Compression.GZipStream($ms, [System.IO.Compression.CompressionMode]::Decompress)
            $out = New-Object System.IO.MemoryStream
            $buf = New-Object byte[] 65536
            while ($out.Length -lt $script:MaxScanFile) {
                $n = $gz.Read($buf, 0, $buf.Length)
                if ($n -le 0) { break }
                $out.Write($buf, 0, $n)
            }
            $gz.Dispose()
            return [System.Text.Encoding]::UTF8.GetString($out.ToArray())
        } catch { return "" }
    }
    if ($bytes.Length -gt $script:MaxScanFile) { [Array]::Resize([ref]$bytes, $script:MaxScanFile) }
    $start = 0
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) { $start = 3 }
    return [System.Text.Encoding]::UTF8.GetString($bytes, $start, $bytes.Length - $start)
}

function Convert-Latin1ToUtf8([string]$s) {
    try { return [System.Text.Encoding]::UTF8.GetString($script:Latin1.GetBytes($s)) } catch { return $s }
}

function Get-SnowflakeDate([string]$id) {
    if ($id -notmatch '^[0-9]{17,19}$') { return "" }
    try {
        $v = [uint64]$id
        $ms = [int64](($v -shr 22) + 1420070400000)
        return [DateTimeOffset]::FromUnixTimeMilliseconds($ms).LocalDateTime.ToString("yyyy-MM-dd HH:mm:ss")
    } catch { return "" }
}

function Add-Unique($list, [string]$s) {
    if ($s -and -not $list.Contains($s)) { [void]$list.Add($s) }
}

$script:Work     = New-Object System.Collections.Generic.List[object]
$script:WorkSeen = New-Object System.Collections.Generic.HashSet[string]
$script:McSeen   = New-Object System.Collections.Generic.List[string]
$script:DiscordClients = New-Object System.Collections.Generic.List[string]
$script:Count = @{ Discord = 0; Accounts = 0; Logs = 0 }

function Add-Work([string]$kind, $file, [string]$label) {
    if (-not $script:WorkSeen.Add($file.FullName.ToLower())) { return }
    [void]$script:Work.Add([PSCustomObject]@{
        Kind   = $kind
        Path   = $file.FullName
        Label  = $label
        Weight = [double][Math]::Max($file.Length, 16384)
    })
    switch ($kind) {
        'discord'  { $script:Count.Discord++ }
        'accounts' { $script:Count.Accounts++ }
        'log'      { $script:Count.Logs++ }
    }
}

function Find-Discord {
    $appData = $env:APPDATA
    if (-not $appData) { return }
    $clients = @(
        @{ Folder = "discord";       Name = "Stable" },
        @{ Folder = "discordcanary"; Name = "Canary" },
        @{ Folder = "discordptb";    Name = "PTB" }
    )
    $subs = @("Local Storage\leveldb", "Session Storage")
    foreach ($c in $clients) {
        $base = Join-Path $appData $c.Folder
        if (-not (Test-Path -LiteralPath $base -ErrorAction SilentlyContinue)) { continue }
        [void]$script:DiscordClients.Add($c.Name)
        foreach ($sub in $subs) {
            $dir = Join-Path $base $sub
            if (-not (Test-Path -LiteralPath $dir -ErrorAction SilentlyContinue)) { continue }
            Get-ChildItem -LiteralPath $dir -Recurse -File -ErrorAction SilentlyContinue |
                Where-Object { $_.Extension -ieq ".ldb" -or $_.Extension -ieq ".log" } |
                ForEach-Object { Add-Work 'discord' $_ $c.Name }
        }
    }
}

function Find-AccountsJson([string]$path, [string]$label) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf -ErrorAction SilentlyContinue)) { return }
    Add-Unique $script:McSeen $label
    Add-Work 'accounts' (Get-Item -LiteralPath $path -ErrorAction SilentlyContinue) $label
}

function Find-Logs([string]$folder, [string]$label) {
    if (-not (Test-Path -LiteralPath $folder -ErrorAction SilentlyContinue)) { return }
    Add-Unique $script:McSeen $label
    Get-ChildItem -LiteralPath $folder -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '\.log(\.gz)?$' } |
        Sort-Object LastWriteTime -Descending |
        ForEach-Object { Add-Work 'log' $_ $label }
}

function Find-Minecraft {
    $appData     = $env:APPDATA
    $localApp    = $env:LOCALAPPDATA
    $userProfile = $env:USERPROFILE

    if ($appData) {
        $mc = Join-Path $appData ".minecraft"
        Find-AccountsJson (Join-Path $mc "launcher_accounts.json") "Official Launcher"
        Find-Logs (Join-Path $mc "logs") ".minecraft logs"

        $prism = Join-Path $appData "PrismLauncher"
        Find-AccountsJson (Join-Path $prism "accounts.json") "Prism Launcher"
        Find-Logs (Join-Path $prism "logs") "Prism logs"
        $instances = Join-Path $prism "instances"
        if (Test-Path -LiteralPath $instances -ErrorAction SilentlyContinue) {
            foreach ($d in (Get-ChildItem -LiteralPath $instances -Directory -ErrorAction SilentlyContinue)) {
                $logs = Join-Path $d.FullName "minecraft\logs"
                if (-not (Test-Path -LiteralPath $logs -ErrorAction SilentlyContinue)) { $logs = Join-Path $d.FullName "logs" }
                Find-Logs $logs "Prism $($d.Name)"
            }
        }
    }

    foreach ($name in @("MultiMC", "PolyMC", "polymc")) {
        $root = $null
        if ($appData) {
            $root = Join-Path $appData $name
            if (-not (Test-Path -LiteralPath $root -ErrorAction SilentlyContinue) -and $localApp) { $root = Join-Path $localApp $name }
        } elseif ($localApp) {
            $root = Join-Path $localApp $name
        }
        if (-not $root -or -not (Test-Path -LiteralPath $root -ErrorAction SilentlyContinue)) { continue }
        Find-AccountsJson (Join-Path $root "accounts.json") $name
        $instances = Join-Path $root "instances"
        if (Test-Path -LiteralPath $instances -ErrorAction SilentlyContinue) {
            foreach ($d in (Get-ChildItem -LiteralPath $instances -Directory -ErrorAction SilentlyContinue)) {
                Find-Logs (Join-Path $d.FullName "minecraft\logs") "$name $($d.Name)"
            }
        }
    }

    if ($userProfile) { Find-Logs (Join-Path $userProfile ".lunarclient\offline") "Lunar Client" }
    if ($appData) {
        Find-Logs (Join-Path $appData ".minecraft\logs\blclient") "Badlion"
        foreach ($extra in @("ModrinthApp", "com.modrinth.theseus", "CurseForge", "GDLauncher", "ATLauncher")) {
            $folder = Join-Path $appData $extra
            if (-not (Test-Path -LiteralPath $folder -ErrorAction SilentlyContinue)) { continue }
            Add-Unique $script:McSeen $extra
            Get-ChildItem -LiteralPath $folder -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
                if ($_.Name -ieq "accounts.json") { Add-Work 'accounts' $_ $extra }
                elseif ($_.Name -match '\.log(\.gz)?$') { Add-Work 'log' $_ $extra }
            }
        }
    }
}

$script:DiscordAccounts = @{}

$DiscordPatterns = @(
    '"id"\s*:\s*"([0-9]{17,19})".{0,1200}?"username"\s*:\s*"([^"]{1,32})"',
    '"username"\s*:\s*"([^"]{1,32})".{0,1200}?"id"\s*:\s*"([0-9]{17,19})"',
    '"id"\s*:\s*"([0-9]{17,19})".{0,800}?"global_name"\s*:\s*"([^"]{1,32})"',
    '"global_name"\s*:\s*"([^"]{1,32})".{0,800}?"id"\s*:\s*"([0-9]{17,19})"'
)

function Read-DiscordFile([string]$path, [string]$client) {
    $bytes = Read-SharedBytes $path
    if (-not $bytes -or $bytes.Length -lt 50) { return }
    $content = $script:Latin1.GetString($bytes)
    foreach ($p in $DiscordPatterns) {
        foreach ($m in [regex]::Matches($content, $p, $script:Rx)) {
            $a = $m.Groups[1].Value
            $b = $m.Groups[2].Value
            if ($a -match '^[0-9]{17,19}$') { $id = $a; $user = $b }
            elseif ($b -match '^[0-9]{17,19}$') { $id = $b; $user = $a }
            else { continue }
            if (-not $id -or -not $user) { continue }
            if ($user -match '^[0-9]+$' -or $user.Length -lt 2) { continue }
            if ($script:DiscordAccounts.ContainsKey($id)) { continue }
            $script:DiscordAccounts[$id] = [PSCustomObject]@{
                User    = (Convert-Latin1ToUtf8 $user)
                Id      = $id
                Created = (Get-SnowflakeDate $id)
                Client  = $client
            }
        }
    }
}

$script:McAccounts = @{}
$script:McNames    = @{}

function Test-Uuidish([string]$s) {
    return ($s.Length -ge 32 -and $s.Length -le 36 -and $s -match '^[0-9a-fA-F\-]+$')
}
function Test-NameLike([string]$s) {
    return ($s.Length -gt 0 -and $s.Length -le 32 -and $s -match '^[A-Za-z0-9_ .\-]+$')
}

function Merge-Mc([string]$from, [string]$to) {
    if ($from -eq $to) { return }
    if (-not $script:McAccounts.ContainsKey($from)) { return }
    $old = $script:McAccounts[$from]
    $script:McAccounts.Remove($from)
    if ($script:McAccounts.ContainsKey($to)) {
        $cur = $script:McAccounts[$to]
        if (-not $cur.Name) { $cur.Name = $old.Name }
        if (-not $cur.Uuid) { $cur.Uuid = $old.Uuid }
    } else {
        $script:McAccounts[$to] = $old
    }
}

function Add-Minecraft([string]$name, [string]$uuid) {
    $norm = ""
    if ($uuid -and (Test-Uuidish $uuid)) {
        $s = $uuid.ToLower().Replace("-", "")
        if ($s.Length -eq 32) { $s = $s.Insert(8, "-").Insert(13, "-").Insert(18, "-").Insert(23, "-") }
        $norm = $s
    }
    if ($name -and -not (Test-NameLike $name)) { $name = "" }
    if (-not $norm -and -not $name) { return }

    $nameKey = if ($name) { "name:" + $name.ToLower() } else { "" }
    $uuidKey = if ($norm) { "uuid:" + $norm } else { "" }

    if ($nameKey -and $uuidKey -and $script:McAccounts.ContainsKey($nameKey)) { Merge-Mc $nameKey $uuidKey }
    $k = if ($uuidKey) { $uuidKey } else { $nameKey }
    if ($nameKey -and -not $uuidKey -and $script:McNames.ContainsKey($nameKey)) { $k = $script:McNames[$nameKey] }

    if ($script:McAccounts.ContainsKey($k)) {
        $e = $script:McAccounts[$k]
        if ($name -and -not $e.Name) { $e.Name = $name }
        if ($norm -and -not $e.Uuid) { $e.Uuid = $norm }
    } else {
        $script:McAccounts[$k] = [PSCustomObject]@{ Name = $name; Uuid = $norm }
    }
    if ($nameKey) { $script:McNames[$nameKey] = $k }
}

$McLogPatterns = @(
    @('Setting user:\s*(\S+)', 'NU'),
    @('Logged in as\s+(\S+)', 'NU'),
    @('UUID of player\s+(\S+)\s+is\s+([0-9a-fA-F\-]{32,36})', 'NU'),
    @('"name"\s*:\s*"([^"]+)"[^}]{0,200}?"id"\s*:\s*"([0-9a-fA-F\-]{32,36})"', 'NU'),
    @('"id"\s*:\s*"([0-9a-fA-F\-]{32,36})".{0,300}?"name"\s*:\s*"([^"]+)"', 'UN'),
    @('uuid=([0-9a-fA-F\-]{32,36}),\s*name=([A-Za-z0-9_ .\-]{1,32})', 'UN')
)

function Parse-McLog([string]$content) {
    if (-not $content) { return }
    foreach ($entry in $McLogPatterns) {
        foreach ($m in [regex]::Matches($content, $entry[0], $script:Rx)) {
            $g1 = $m.Groups[1].Value
            $g2 = if ($m.Groups.Count -gt 2) { $m.Groups[2].Value } else { "" }
            if ($entry[1] -eq 'UN') {
                if (-not $g2) { continue }
                Add-Minecraft $g2 $g1
            } else {
                Add-Minecraft $g1 $g2
            }
        }
    }
}

function Get-Prop($obj, [string]$name) {
    if ($null -eq $obj) { return $null }
    $p = $obj.PSObject.Properties[$name]
    if ($p) { return $p.Value }
    return $null
}

function Read-AccountsJson([string]$path) {
    $raw = Read-TextFile $path
    if (-not $raw) { return }

    try {
        $root = $raw | ConvertFrom-Json -ErrorAction Stop
        $accs = Get-Prop $root "accounts"
        if ($accs -is [System.Array]) {
            foreach ($acc in $accs) {
                $name = ""; $uuid = ""
                $prof = Get-Prop $acc "profile"
                if ($prof) { $name = [string](Get-Prop $prof "name"); $uuid = [string](Get-Prop $prof "id") }
                if (-not $name) { $name = [string](Get-Prop $acc "username") }
                if (-not $uuid) { $uuid = [string](Get-Prop $acc "uuid") }
                if (-not $uuid) { $uuid = [string](Get-Prop $acc "id") }
                Add-Minecraft $name $uuid
            }
        } elseif ($accs) {
            foreach ($prop in $accs.PSObject.Properties) {
                $acc = $prop.Value
                $name = ""; $uuid = ""
                $mp = Get-Prop $acc "minecraftProfile"
                if ($mp) { $name = [string](Get-Prop $mp "name"); $uuid = [string](Get-Prop $mp "id") }
                else { $name = [string](Get-Prop $acc "username") }
                if (-not $uuid) { $uuid = [string](Get-Prop $acc "id") }
                Add-Minecraft $name $uuid
            }
        }
    } catch {}
    Parse-McLog $raw
}

Write-Section "Locating files"
Write-Info "Looking through Discord and Minecraft folders..."
Find-Discord
Find-Minecraft

$total = $script:Work.Count
if ($total -gt 0) {
    Write-Ok "$total file(s) queued for scanning"
    Write-Dim ("Discord cache {0}   {1}   account files {2}   {1}   logs {3}" -f $script:Count.Discord, $gDot, $script:Count.Accounts, $script:Count.Logs) 4
} else {
    Write-Dim "No Discord or Minecraft files were found on this PC"
}

if ($total -gt 0) {
    Write-Section "Scanning"
    Write-Host ""
    $totalWeight = 0.0
    foreach ($item in $script:Work) { $totalWeight += $item.Weight }
    $doneWeight = 0.0
    $doneCount  = 0
    $lastPct    = -1
    try { [Console]::CursorVisible = $false } catch {}
    Show-Bar 0 0 $total
    foreach ($item in $script:Work) {
        try {
            switch ($item.Kind) {
                'discord'  { Read-DiscordFile $item.Path $item.Label }
                'accounts' { Read-AccountsJson $item.Path }
                'log'      { Parse-McLog (Read-TextFile $item.Path) }
            }
        } catch {}
        $doneCount++
        $doneWeight += $item.Weight
        $pct = [int][Math]::Floor(($doneWeight / $totalWeight) * 100)
        if ($pct -ge 100 -and $doneCount -lt $total) { $pct = 99 }
        if ($pct -ne $lastPct -or ($doneCount % 25) -eq 0) {
            Show-Bar $pct $doneCount $total
            $lastPct = $pct
        }
    }
    Show-Bar 100 $total $total $true
    Write-Host ""
    try { [Console]::CursorVisible = $true } catch {}
}

$discordAlt = $false
$mcAlt = $false
$offline = $false

Write-Section "Discord results"
if ($script:DiscordClients.Count -eq 0) {
    Write-Dim "Discord is not installed (Stable, Canary and PTB folders are all missing)"
} elseif ($script:DiscordAccounts.Count -eq 0) {
    Write-Dim "Scanned $($script:DiscordClients -join ', ') $gDash no account records in the cache"
} else {
    $discordAlt = $script:DiscordAccounts.Count -gt 1
    foreach ($a in ($script:DiscordAccounts.Values | Sort-Object User)) {
        $detail = "User ID $($a.Id)"
        if ($a.Created) { $detail += ", created $($a.Created)" }
        if ($a.Client)  { $detail += " $gDash cached by the $($a.Client) client" }
        if ($discordAlt) { Write-Warn "Discord alt account: $($a.User)" } else { Write-Ok "Discord account in cache: $($a.User)" }
        Write-Dim $detail 4
    }
}

Write-Section "Minecraft results"
if ($script:McAccounts.Count -eq 0) {
    if ($script:McSeen.Count -eq 0) {
        Write-Dim "No Minecraft launcher folders found for this user"
    } else {
        Write-Dim "Scanned $($script:McSeen -join ', ') $gDash no username or UUID found"
    }
} else {
    $mcAlt = $script:McAccounts.Count -gt 1
    foreach ($k in ($script:McAccounts.Keys | Sort-Object)) {
        $a = $script:McAccounts[$k]
        $name = if ($a.Name) { $a.Name } else { "(no name)" }
        $detail = ""
        if ($a.Uuid) { $detail = "UUID $($a.Uuid)" }
        $isOffline = -not $a.Uuid
        if ($isOffline) {
            $offline = $true
            $detail = "bare username with no UUID (what an offline session leaves in a log)"
        }
        if ($mcAlt) {
            Write-Warn "Minecraft alt account: $name"
        } elseif ($isOffline) {
            Write-Warn "Offline Minecraft session: $name"
        } else {
            Write-Ok "Minecraft account: $name"
        }
        Write-Dim $detail 4
    }
}

Write-Host ""
$flagged = $discordAlt -or $mcAlt -or $offline
$boxColor = if ($flagged) { 'Magenta' } else { 'Green' }
Write-Box @(("Scan complete: {0} Discord, {1} Minecraft account(s) found." -f $script:DiscordAccounts.Count, $script:McAccounts.Count)) $boxColor @('White')
Write-Host ""
exit
