[System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[System.Console]::InputEncoding  = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = "Continue"

try { Clear-Host } catch {}

$gCheck=[string][char]0x2713; $gChev=[string][char]0x203A; $gDot=[string][char]0x00B7; $gWarn=[string][char]0x25B2
$gCross=[string][char]0x2717; $gDiamond=[string][char]0x25C6; $gH=[string][char]0x2500; $gTL=[string][char]0x256D
$gTR=[string][char]0x256E; $gV=[string][char]0x2502; $gBL=[string][char]0x2570; $gBR=[string][char]0x256F
$gPrompt=[string][char]0x003E; $gArrow=[string][char]0x2192; $gDash=[string][char]0x2013; $gBar=[string][char]0x2501
$gTri=[string][char]0x25B8; $gBullet=[string][char]0x2022

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
function Write-ResultNote([string]$m, [int]$i = 8) {
    if ($m -like 'Known false-flag*') { Write-Line $gDiamond 'Cyan' $m 'Cyan' $i } else { Write-Dim $m $i }
}

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
    $mx = 0; foreach ($l in $lines) { if (([string]$l).Length -gt $mx) { $mx = ([string]$l).Length } }
    $inner = [math]::Max($script:W - 4, $mx)
    Write-Host ($gTL + ($gH * ($inner + 2)) + $gTR) -ForegroundColor $color
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $c = if ($colors -and $i -lt $colors.Count) { $colors[$i] } else { 'White' }
        Write-Host ($gV + ' ') -NoNewline -ForegroundColor $color
        Write-Host ([string]$lines[$i]).PadRight($inner) -NoNewline -ForegroundColor $c
        Write-Host (' ' + $gV) -ForegroundColor $color
    }
    Write-Host ($gBL + ($gH * ($inner + 2)) + $gBR) -ForegroundColor $color
}

function Write-Sub([string]$title, [int]$count, [string]$color) {
    Write-Host ""
    Write-Host "  " -NoNewline
    Write-Host $gTri -NoNewline -ForegroundColor $color
    Write-Host " $($title.ToUpper())  " -NoNewline -ForegroundColor White
    Write-Host "($count)" -ForegroundColor $color
}

function Write-Card([string]$Tag, [string]$TagColor, [string]$Title, $Groups) {
    Write-Host ""
    Write-Host ("  " + $gTL + $gH + " ") -NoNewline -ForegroundColor $TagColor
    $fg = if ($TagColor -eq 'DarkRed' -or $TagColor -eq 'DarkMagenta' -or $TagColor -eq 'Red' -or $TagColor -eq 'Magenta') { 'White' } else { 'Black' }
    Write-Host (" $Tag ") -NoNewline -ForegroundColor $fg -BackgroundColor $TagColor
    Write-Host ("  " + $Title) -ForegroundColor Yellow
    foreach ($g in $Groups) {
        $items = @($g.Items | Where-Object { $_ })
        if ($items.Count -eq 0) { continue }
        Write-Host ("  " + $gV) -ForegroundColor $TagColor
        if ($g.Head) {
            Write-Host ("  " + $gV + "  ") -NoNewline -ForegroundColor $TagColor
            Write-Host $g.Head -ForegroundColor DarkGray
        }
        $n = 0
        foreach ($it in $items) {
            if ($n -ge 30) {
                Write-Host ("  " + $gV + "    ") -NoNewline -ForegroundColor $TagColor
                Write-Host "... +$($items.Count - 30) more" -ForegroundColor DarkGray
                break
            }
            Write-Host ("  " + $gV + "    ") -NoNewline -ForegroundColor $TagColor
            Write-Host ($gBullet + " " + $it) -ForegroundColor $g.Color
            $n++
        }
    }
    Write-Host ("  " + $gBL + ($gH * 70)) -ForegroundColor $TagColor
}

function Wait-Key {
    Write-Host ""
    Write-Host "  Press any key to exit..." -ForegroundColor DarkGray
    try { $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") } catch { Start-Sleep -Seconds 5 }
}

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal $id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

Clear-Host
Write-Host ""
Write-Box @(
    "P 1 A E ' S   M O D   A N A L Y Z E R",
    "v1.0.1",
    "",
    "Dm .p1ae for Questions or Bugs"
) 'Cyan' @('Cyan', 'DarkGray', 'White', 'Gray', 'DarkGray')

Write-Host ""
Write-Host "  Select an action" -ForegroundColor White
Write-Host ("  " + ($gH * ($script:W - 4))) -ForegroundColor DarkGray
Write-Host "   [1]" -NoNewline -ForegroundColor Cyan;  Write-Host "  Start  (auto-detect the running instance)" -ForegroundColor White
Write-Host "   [2]" -NoNewline -ForegroundColor Cyan;  Write-Host "  Scan a specific folder" -ForegroundColor White
Write-Host "   [3]" -NoNewline -ForegroundColor Cyan;  Write-Host "  Exit" -ForegroundColor White
Write-Host ""
Write-Host "  Option $gPrompt " -NoNewline -ForegroundColor DarkGray
$key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
$choice = $key.Character.ToString()
Write-Host $choice -ForegroundColor Cyan
if ($choice -eq "3") { Write-Host ""; Write-Dim "Exiting..."; exit }
if ($choice -ne "1" -and $choice -ne "2") { Write-Host ""; Write-Fail "Invalid choice. Exiting."; exit }
$ManualOnly = ($choice -eq "2")

Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue

if (-not ('ProcessHelper' -as [type])) {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class ProcessHelper
{
    [DllImport("ntdll.dll")]
    private static extern int NtQueryInformationProcess(IntPtr ProcessHandle, int ProcessInformationClass, IntPtr ProcessInformation, int ProcessInformationLength, out int ReturnLength);
    [DllImport("ntdll.dll")]
    private static extern int RtlAdjustPrivilege(int Privilege, bool Enable, bool CurrentThread, out bool Previous);
    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool ReadProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, IntPtr lpBuffer, IntPtr dwSize, out IntPtr lpNumberOfBytesRead);
    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern IntPtr OpenProcess(int dwDesiredAccess, bool bInheritHandle, int dwProcessId);
    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool CloseHandle(IntPtr hObject);
    [DllImport("kernel32.dll", SetLastError = true)]
    private static extern bool IsWow64Process(IntPtr hProcess, out bool wow64Process);

    public static string Diag = "";
    public static void EnableDebug() { try { bool prev; RtlAdjustPrivilege(20, true, false, out prev); } catch { } }

    private static bool Read(IntPtr h, IntPtr addr, IntPtr buf, int size)
    {
        IntPtr br;
        return ReadProcessMemory(h, addr, buf, (IntPtr)size, out br);
    }
    private static string ReadStr(IntPtr h, IntPtr addr, bool is32)
    {
        int usSize = is32 ? 8 : 16;
        IntPtr us = Marshal.AllocHGlobal(16);
        try
        {
            if (!Read(h, addr, us, usSize)) { Diag += "read UNICODE_STRING failed (err " + Marshal.GetLastWin32Error() + "); "; return null; }
            int length = (ushort)Marshal.ReadInt16(us, 0);
            if (length <= 0 || length > 65534) { Diag += "PEB string length " + length + " = EMPTY; "; return null; }
            IntPtr bufPtr = is32 ? (IntPtr)(long)(uint)Marshal.ReadInt32(us, 4) : Marshal.ReadIntPtr(us, 8);
            if (bufPtr == IntPtr.Zero) { Diag += "PEB string pointer null = EMPTY; "; return null; }
            IntPtr sb = Marshal.AllocHGlobal(length);
            try
            {
                if (!Read(h, bufPtr, sb, length)) { Diag += "read string data failed (err " + Marshal.GetLastWin32Error() + "); "; return null; }
                return Marshal.PtrToStringUni(sb, length / 2);
            }
            finally { Marshal.FreeHGlobal(sb); }
        }
        finally { Marshal.FreeHGlobal(us); }
    }
    private static string ReadParam(int pid, bool cmdLine)
    {
        if (IntPtr.Size != 8) { Diag += "PowerShell host is 32-bit; "; return null; }
        IntPtr h = OpenProcess(0x0410, false, pid);
        if (h == IntPtr.Zero) h = OpenProcess(0x1010, false, pid);
        if (h == IntPtr.Zero) { Diag += "OpenProcess(read) failed (err " + Marshal.GetLastWin32Error() + "); "; return null; }
        IntPtr pbi = IntPtr.Zero; IntPtr pp = IntPtr.Zero;
        try
        {
            bool wow64;
            if (!IsWow64Process(h, out wow64)) { Diag += "IsWow64Process failed; "; return null; }
            pbi = Marshal.AllocHGlobal(48);
            pp = Marshal.AllocHGlobal(8);
            int ret;
            if (wow64)
            {
                int st = NtQueryInformationProcess(h, 26, pbi, 8, out ret);
                if (st != 0) { Diag += "wow64 PEB query 0x" + st.ToString("X8") + "; "; return null; }
                IntPtr peb32 = Marshal.ReadIntPtr(pbi, 0);
                if (peb32 == IntPtr.Zero) { Diag += "wow64 PEB null; "; return null; }
                if (!Read(h, (IntPtr)((long)peb32 + 0x10), pp, 4)) { Diag += "read PEB32 params failed (err " + Marshal.GetLastWin32Error() + "); "; return null; }
                long pars = (uint)Marshal.ReadInt32(pp, 0);
                if (pars == 0) { Diag += "PEB32 ProcessParameters null; "; return null; }
                return ReadStr(h, (IntPtr)(pars + (cmdLine ? 0x40 : 0x24)), true);
            }
            else
            {
                int st = NtQueryInformationProcess(h, 0, pbi, 48, out ret);
                if (st != 0) { Diag += "PEB query 0x" + st.ToString("X8") + "; "; return null; }
                IntPtr peb = Marshal.ReadIntPtr(pbi, 8);
                if (peb == IntPtr.Zero) { Diag += "PEB null; "; return null; }
                if (!Read(h, (IntPtr)((long)peb + 0x20), pp, 8)) { Diag += "read PEB params failed (err " + Marshal.GetLastWin32Error() + "); "; return null; }
                IntPtr pars = Marshal.ReadIntPtr(pp, 0);
                if (pars == IntPtr.Zero) { Diag += "ProcessParameters null; "; return null; }
                return ReadStr(h, (IntPtr)((long)pars + (cmdLine ? 0x70 : 0x38)), false);
            }
        }
        catch (Exception ex) { Diag += "PEB read exception: " + ex.Message + "; "; return null; }
        finally
        {
            if (pbi != IntPtr.Zero) Marshal.FreeHGlobal(pbi);
            if (pp != IntPtr.Zero) Marshal.FreeHGlobal(pp);
            CloseHandle(h);
        }
    }
    public static string GetCurrentDirectory(int pid) { return ReadParam(pid, false); }
    private static string CmdLine60(int pid)
    {
        IntPtr h = OpenProcess(0x1000, false, pid);
        if (h == IntPtr.Zero) { Diag += "OpenProcess(query) failed (err " + Marshal.GetLastWin32Error() + "); "; return null; }
        try
        {
            int need = 0;
            int st0 = NtQueryInformationProcess(h, 60, IntPtr.Zero, 0, out need);
            if (need <= 0 || need > 1048576) { Diag += "cmdline query status 0x" + st0.ToString("X8") + ", size " + need + "; "; return null; }
            IntPtr buf = Marshal.AllocHGlobal(need);
            try
            {
                int ret;
                int st1 = NtQueryInformationProcess(h, 60, buf, need, out ret);
                if (st1 != 0) { Diag += "cmdline query status 0x" + st1.ToString("X8") + "; "; return null; }
                int len = (ushort)Marshal.ReadInt16(buf, 0);
                if (len <= 0) { Diag += "Windows returned an EMPTY command line (length 0); "; return null; }
                IntPtr sp = Marshal.ReadIntPtr(buf, IntPtr.Size == 8 ? 8 : 4);
                if (sp == IntPtr.Zero) { Diag += "cmdline pointer null; "; return null; }
                return Marshal.PtrToStringUni(sp, len / 2);
            }
            finally { Marshal.FreeHGlobal(buf); }
        }
        catch (Exception ex) { Diag += "cmdline exception: " + ex.Message + "; "; return null; }
        finally { CloseHandle(h); }
    }
    public static string GetCommandLine(int pid)
    {
        Diag = "";
        string s = CmdLine60(pid);
        if (!string.IsNullOrEmpty(s)) return s;
        return ReadParam(pid, true);
    }
}
"@
}

try { [ProcessHelper]::EnableDebug() } catch {}
if (-not [Environment]::Is64BitProcess -and [Environment]::Is64BitOperatingSystem) {
    Write-Warn "This is 32-bit PowerShell - it cannot read 64-bit Minecraft's command line. Use the 64-bit 'Windows PowerShell' / pwsh."
}

$scanSource = @'
using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;

public class JarResultV2
{
    public int Classes, OwnClasses, Single1, Two, Numeric, Unicode, Fullwidth, Japanese, NoVowel, Gibberish, Confusion, SinglePkg, ObfPath;
    public bool Exec, Download, Exfil, Malformed, Robot;
    public string ModId = "", Name = "", Version = "", Loader = "", Error = "";
    public List<string> Strings = new List<string>();
    public List<string> FwRuns = new List<string>();
    public HashSet<string> FwSeen = new HashSet<string>();
    public List<string> Obfuscators = new List<string>();
    public List<string> PatternHits = new List<string>();
    public List<string> NestedJars = new List<string>();
    public List<string> LoaderHits = new List<string>();
    public bool[] ExHit, StHit, ObHit;
}

public class ScanJobV2
{
    public JarResultV2[] Results;
    public string[] Hashes;
    public string[] Errors;
    public int Done;
    public int Total;
    public Task Task;
}

public sealed class P1AutomatonV2
{
    public int[] Next;
    public int[][] Outs;
    public byte[] ClassOf;
    public int Stride;

    public P1AutomatonV2(string[] patterns, bool fold)
    {
        ClassOf = new byte[65536];
        int classes = 0;
        for (int p = 0; p < patterns.Length; p++)
        {
            string pat = patterns[p];
            for (int k = 0; k < pat.Length; k++)
            {
                char c = pat[k];
                char lc = c;
                if (fold && c >= 'A' && c <= 'Z') { lc = (char)(c + 32); }
                if (ClassOf[lc] == 0)
                {
                    classes++;
                    if (classes > 254) { throw new InvalidOperationException("Pattern alphabet too large"); }
                    ClassOf[lc] = (byte)classes;
                    if (fold && lc >= 'a' && lc <= 'z') { ClassOf[(char)(lc - 32)] = (byte)classes; }
                }
            }
        }
        Stride = classes + 1;

        List<int[]> trie = new List<int[]>();
        List<List<int>> outl = new List<List<int>>();
        trie.Add(new int[Stride]); outl.Add(null);
        for (int p = 0; p < patterns.Length; p++)
        {
            string pat = patterns[p];
            if (pat.Length == 0) { continue; }
            int s = 0;
            for (int k = 0; k < pat.Length; k++)
            {
                int cl = ClassOf[pat[k]];
                int nx = trie[s][cl];
                if (nx == 0)
                {
                    nx = trie.Count;
                    trie.Add(new int[Stride]); outl.Add(null);
                    trie[s][cl] = nx;
                }
                s = nx;
            }
            if (outl[s] == null) { outl[s] = new List<int>(); }
            outl[s].Add(p);
        }

        int n = trie.Count;
        int[] fail = new int[n];
        List<int>[] merged = new List<int>[n];
        Next = new int[n * Stride];
        Outs = new int[n][];
        Queue<int> q = new Queue<int>();
        for (int cl = 1; cl < Stride; cl++)
        {
            int c0 = trie[0][cl];
            Next[cl] = c0;
            if (c0 != 0) { fail[c0] = 0; q.Enqueue(c0); }
        }
        while (q.Count > 0)
        {
            int s = q.Dequeue();
            List<int> o = null;
            if (outl[s] != null) { o = new List<int>(outl[s]); }
            List<int> fo = merged[fail[s]];
            if (fo != null) { if (o == null) { o = new List<int>(); } o.AddRange(fo); }
            merged[s] = o;
            for (int cl = 1; cl < Stride; cl++)
            {
                int c = trie[s][cl];
                int f = Next[fail[s] * Stride + cl];
                if (c != 0) { fail[c] = f; Next[s * Stride + cl] = c; q.Enqueue(c); }
                else { Next[s * Stride + cl] = f; }
            }
        }
        for (int s = 0; s < n; s++) { Outs[s] = merged[s] != null ? merged[s].ToArray() : null; }
    }
}

public static class P1ScanV2
{
    public static string[] ExactNeedles = new string[0];
    public static string[] StrongKeys = new string[0];
    public static string[] StrongNames = new string[0];
    public static string[] ObfNeedles = new string[0];
    public static string[] ObfNames = new string[0];
    public static string[] EntryPatterns = new string[0];
    public static Regex EntryRegex = null;

    static readonly string[] FlagNeedles = new string[] {
        "java/lang/Runtime", "getRuntime", "exec", "openConnection", "HttpURLConnection",
        "FileOutputStream", "setDoOutput", "getOutputStream", "getProperty",
        "defineClass", "java/lang/ClassLoader", "findClass", "addToClassPath", "FabricLauncher",
        "URLClassLoader", "defineHiddenClass", "org/spongepowered/asm/mixin/Mixins", "addConfiguration",
        "processedMods", "addURL", "java/awt/Robot" };

    static P1AutomatonV2 exAc, stAc, obAc, enAc;
    static volatile bool built = false;
    static readonly object buildLock = new object();

    [ThreadStatic] static byte[] tBuf;
    [ThreadStatic] static string nestPath;

    static void AddLoader(JarResultV2 r, string where, string reason)
    {
        if (r.LoaderHits.Count >= 12) { return; }
        string w = where;
        if (nestPath != null) { w = nestPath + "!" + where; }
        AddU(r.LoaderHits, reason + " [" + w + "]");
    }

    public static void SetEntryPatterns(string[] pats)
    {
        EntryPatterns = pats;
        List<string> esc = new List<string>();
        foreach (string p in pats) { esc.Add(Regex.Escape(p)); }
        EntryRegex = new Regex("(?<![A-Za-z])(" + string.Join("|", esc.ToArray()) + ")(?![A-Za-z])");
        built = false;
    }

    static void EnsureBuilt()
    {
        if (built) { return; }
        lock (buildLock)
        {
            if (built) { return; }
            exAc = new P1AutomatonV2(ExactNeedles, true);
            stAc = new P1AutomatonV2(StrongKeys, false);
            string[] ob = new string[ObfNeedles.Length + FlagNeedles.Length];
            Array.Copy(ObfNeedles, 0, ob, 0, ObfNeedles.Length);
            Array.Copy(FlagNeedles, 0, ob, ObfNeedles.Length, FlagNeedles.Length);
            obAc = new P1AutomatonV2(ob, false);
            enAc = new P1AutomatonV2(EntryPatterns, false);
            built = true;
        }
    }

    static void AddU(List<string> l, string s) { if (!l.Contains(s)) { l.Add(s); } }
    static void AddFw(JarResultV2 r, string s) { if (r.FwSeen.Add(s)) { r.FwRuns.Add(s); } }

    public static string Normalize(string text)
    {
        StringBuilder sb = new StringBuilder(text.Length);
        bool boundary = true;
        for (int i = 0; i < text.Length; i++)
        {
            char c = text[i];
            int code = (int)c;
            if (code >= 0xFF01 && code <= 0xFF5E) { c = (char)(code - 0xFEE0); }
            else if (code == 0x3000) { c = ' '; }
            if (c == ' ' || c == '\t' || c == '.' || c == '-' || c == '_') { continue; }
            if (c >= 'A' && c <= 'Z') { sb.Append((char)(c + 32)); boundary = false; }
            else if ((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9')) { sb.Append(c); boundary = false; }
            else { if (!boundary) { sb.Append('\n'); boundary = true; } }
        }
        return sb.ToString();
    }

    public static object[] ResolveFullwidth(string[] runs, string[] strongKeys, string[] strongVals, string[] fwKeys, string[] fwVals)
    {
        List<string> resolved = new List<string>();
        HashSet<string> resolvedSet = new HashSet<string>();
        HashSet<string> seen = new HashSet<string>();
        List<string> unkKeys = new List<string>();
        Dictionary<string, string> unkRuns = new Dictionary<string, string>();
        foreach (string run in runs)
        {
            string norm = Normalize(run).Replace("\n", "");
            if (norm.Length < 3) { continue; }
            if (!seen.Add(norm)) { continue; }
            string hit = null;
            for (int i = 0; i < strongKeys.Length; i++)
            {
                if (norm.IndexOf(strongKeys[i], StringComparison.Ordinal) >= 0) { hit = strongVals[i]; break; }
            }
            if (hit == null)
            {
                for (int i = 0; i < fwKeys.Length; i++)
                {
                    if (norm.IndexOf(fwKeys[i], StringComparison.Ordinal) >= 0) { hit = fwVals[i]; break; }
                }
            }
            if (hit != null)
            {
                string label = hit + " (fullwidth)";
                if (resolvedSet.Add(label)) { resolved.Add(label); }
                continue;
            }
            if (norm.Length >= 6) { unkKeys.Add(norm); unkRuns[norm] = run; }
        }
        unkKeys.Sort(delegate(string a, string b) { return b.Length.CompareTo(a.Length); });
        List<string> kept = new List<string>();
        List<string> final = new List<string>();
        foreach (string k in unkKeys)
        {
            bool redundant = false;
            for (int i = 0; i < kept.Count; i++)
            {
                if (kept[i].Length > k.Length && kept[i].IndexOf(k, StringComparison.Ordinal) >= 0) { redundant = true; break; }
            }
            if (!redundant) { kept.Add(k); final.Add(unkRuns[k]); }
        }
        return new object[] { resolved.ToArray(), final.ToArray() };
    }

    static bool EntryMayMatch(string n)
    {
        P1AutomatonV2 a = enAc;
        int[] nx = a.Next; byte[] cl = a.ClassOf; int st = a.Stride; int[][] outs = a.Outs;
        int s = 0;
        for (int i = 0; i < n.Length; i++)
        {
            s = nx[s * st + cl[n[i]]];
            if (outs[s] != null) { return true; }
        }
        return false;
    }

    static void ScanContent(string content, JarResultV2 r, string where)
    {
        int[] exNext = exAc.Next; byte[] exCls = exAc.ClassOf; int exStride = exAc.Stride; int[][] exOut = exAc.Outs;
        int[] stNext = stAc.Next; byte[] stCls = stAc.ClassOf; int stStride = stAc.Stride; int[][] stOut = stAc.Outs;
        int[] obNext = obAc.Next; byte[] obCls = obAc.ClassOf; int obStride = obAc.Stride; int[][] obOut = obAc.Outs;
        bool[] exHit = r.ExHit; bool[] stHit = r.StHit; bool[] obHit = r.ObHit;
        int obCount = ObfNeedles.Length;
        int mask = 0;
        int es = 0, ss = 0, os = 0;
        int runStart = -1, runEnd = -1, fwCount = 0;
        int len = content.Length;

        for (int i = 0; i < len; i++)
        {
            char raw = content[i];
            int code = (int)raw;
            int[] o;

            es = exNext[es * exStride + exCls[raw]];
            o = exOut[es];
            if (o != null) { for (int k = 0; k < o.Length; k++) { exHit[o[k]] = true; } }

            os = obNext[os * obStride + obCls[raw]];
            o = obOut[os];
            if (o != null)
            {
                for (int k = 0; k < o.Length; k++)
                {
                    int idx = o[k];
                    if (idx < obCount) { obHit[idx] = true; } else { mask |= 1 << (idx - obCount); }
                }
            }

            bool isFw = false;
            char c = raw;
            if (code >= 0xFF01 && code <= 0xFF5E) { c = (char)(code - 0xFEE0); isFw = true; }
            else if (code == 0x3000) { c = ' '; isFw = true; }

            if (c == ' ' || c == '\t' || c == '.' || c == '-' || c == '_') { }
            else if (c >= 'A' && c <= 'Z')
            {
                ss = stNext[ss * stStride + stCls[(char)(c + 32)]];
                o = stOut[ss];
                if (o != null) { for (int k = 0; k < o.Length; k++) { stHit[o[k]] = true; } }
            }
            else if ((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9'))
            {
                ss = stNext[ss * stStride + stCls[c]];
                o = stOut[ss];
                if (o != null) { for (int k = 0; k < o.Length; k++) { stHit[o[k]] = true; } }
            }
            else { ss = 0; }

            if (isFw)
            {
                if (runStart < 0) { runStart = i; fwCount = 0; }
                runEnd = i; fwCount++;
            }
            else if (runStart >= 0 && i == runEnd + 1 && (raw == ' ' || raw == '.' || raw == '-' || raw == '_'))
            {
            }
            else
            {
                if (runStart >= 0 && fwCount >= 2) { AddFw(r, content.Substring(runStart, runEnd - runStart + 1)); }
                runStart = -1; runEnd = -1; fwCount = 0;
            }
        }
        if (runStart >= 0 && fwCount >= 2) { AddFw(r, content.Substring(runStart, runEnd - runStart + 1)); }

        if ((mask & 0x007) == 0x007) { r.Exec = true; }
        if ((mask & 0x038) == 0x038) { r.Download = true; }
        if ((mask & 0x1C8) == 0x1C8) { r.Exfil = true; }
        if ((mask & 0x100000) != 0) { r.Robot = true; }

        if (where != null && (mask & 0xFFE00) != 0)
        {
            if ((mask & 0x200) != 0 && (mask & 0xC00) != 0) { AddLoader(r, where, "custom ClassLoader defining classes from raw bytes (defineClass) - can run code that is not in the jar's class list"); }
            if ((mask & 0x8000) != 0 && (mask & 0x400) != 0) { AddLoader(r, where, "defineHiddenClass - defines hidden classes from bytes at runtime"); }
            if ((mask & 0x1000) != 0 && (mask & 0x2000) != 0) { AddLoader(r, where, "injects a jar into the game classpath (FabricLauncher.addToClassPath)"); }
            if ((mask & 0x30000) == 0x30000) { AddLoader(r, where, "registers Mixin configs at runtime (Mixins.addConfiguration) - applies patches from code outside the mod list"); }
            if ((mask & 0x4000) != 0) { AddLoader(r, where, "URLClassLoader - loads external jar code"); }
            else if ((mask & 0x80000) != 0 && (mask & 0x400) != 0) { AddLoader(r, where, "addURL on a ClassLoader - appends external jars to the classpath"); }
            if ((mask & 0x40000) != 0) { AddLoader(r, where, "references Fabric's processedMods folder - loads a jar out of the loader's internal cache"); }
        }
    }

    static void Finish(JarResultV2 r)
    {
        for (int i = 0; i < ExactNeedles.Length; i++) { if (r.ExHit[i]) { AddU(r.Strings, ExactNeedles[i]); } }
        for (int i = 0; i < StrongKeys.Length; i++) { if (r.StHit[i]) { AddU(r.Strings, StrongNames[i]); } }
        for (int i = 0; i < ObfNeedles.Length; i++) { if (r.ObHit[i]) { AddU(r.Obfuscators, ObfNames[i]); } }
    }

    static void ClassStats(string name, JarResultV2 r)
    {
        r.Classes++;
        int slash = name.LastIndexOf('/');
        string cn = name.Substring(slash + 1);
        cn = cn.Substring(0, cn.Length - 6);

        if (cn.Length > 0)
        {
            bool allDigit = true, allAscii = true, uni = false, fw = false, jp = false, conf = true, under = true;
            foreach (char c in cn)
            {
                if (c < '0' || c > '9') { allDigit = false; }
                if (!((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z'))) { allAscii = false; }
                if (c > 127) { uni = true; }
                if ((c >= 0xFF10 && c <= 0xFF19) || (c >= 0xFF21 && c <= 0xFF3A) || (c >= 0xFF41 && c <= 0xFF5A)) { fw = true; }
                if (c >= 0x3040 && c <= 0x30FF) { jp = true; }
                if ("Il1O0".IndexOf(c) < 0) { conf = false; }
                if (c != '_') { under = false; }
            }
            if (allDigit) { r.Numeric++; }
            if (uni) { r.Unicode++; }
            if (fw) { r.Fullwidth++; }
            if (jp) { r.Japanese++; }
            if (conf || under) { r.Confusion++; }
            if (allAscii && cn.Length == 1) { r.Single1++; }
            if (allAscii && cn.Length == 2) { r.Two++; }
            if (allAscii && cn.Length >= 3 && cn.Length <= 8)
            {
                int vowels = 0, run = 0, maxRun = 0;
                foreach (char c in cn)
                {
                    if ("aeiouAEIOU".IndexOf(c) >= 0) { vowels++; run = 0; }
                    else { run++; if (run > maxRun) { maxRun = run; } }
                }
                if (vowels == 0) { r.NoVowel++; }
                if (maxRun >= 3 && ((double)vowels / cn.Length) < 0.3) { r.Gibberish++; }
            }
        }

        string[] segs = name.Substring(0, name.Length - 6).Split('/');
        int cons = 0, max = 0;
        for (int i = 0; i < segs.Length - 1; i++)
        {
            if (segs[i].Length == 1) { r.SinglePkg++; cons++; if (cons > max) { max = cons; } }
            else { cons = 0; }
        }
        if (max >= 3) { r.ObfPath++; }
    }

    static byte[] ReadBytes(ZipArchiveEntry e)
    {
        using (Stream s = e.Open())
        using (MemoryStream ms = new MemoryStream())
        {
            s.CopyTo(ms);
            return ms.ToArray();
        }
    }

    static int ReadShared(ZipArchiveEntry e)
    {
        byte[] b = tBuf;
        if (b == null) { b = new byte[262144]; tBuf = b; }
        int len = 0;
        using (Stream s = e.Open())
        {
            while (true)
            {
                if (len == b.Length) { Array.Resize(ref b, b.Length * 2); tBuf = b; }
                int n = s.Read(b, len, b.Length - len);
                if (n <= 0) { break; }
                len += n;
            }
        }
        return len;
    }

    static void ReadMeta(string n, string text, JarResultV2 r)
    {
        Match m;
        if (n == "fabric.mod.json")
        {
            r.Loader = "Fabric";
            m = Regex.Match(text, "\"id\"\\s*:\\s*\"([^\"]+)\""); if (m.Success) { r.ModId = m.Groups[1].Value; }
            m = Regex.Match(text, "\"name\"\\s*:\\s*\"([^\"]+)\""); if (m.Success) { r.Name = m.Groups[1].Value; }
            m = Regex.Match(text, "\"version\"\\s*:\\s*\"([^\"]+)\""); if (m.Success) { r.Version = m.Groups[1].Value; }
        }
        else
        {
            if (r.Loader == "") { r.Loader = "Forge/NeoForge"; }
            m = Regex.Match(text, "modId\\s*=\\s*\"([^\"]+)\""); if (m.Success && r.ModId == "") { r.ModId = m.Groups[1].Value; }
            m = Regex.Match(text, "displayName\\s*=\\s*\"([^\"]+)\""); if (m.Success && r.Name == "") { r.Name = m.Groups[1].Value; }
            m = Regex.Match(text, "(?m)^\\s*version\\s*=\\s*\"([^\"]+)\""); if (m.Success && r.Version == "") { r.Version = m.Groups[1].Value; }
        }
    }

    static void ScanArchive(ZipArchive z, JarResultV2 r, int depth)
    {
        foreach (ZipArchiveEntry e in z.Entries)
        {
            string n = e.FullName;
            if (n.EndsWith("/")) { continue; }

            if (EntryRegex != null && EntryMayMatch(n))
            {
                foreach (Match m in EntryRegex.Matches(n)) { AddU(r.PatternHits, m.Value); }
            }

            try
            {
                if (depth == 0 && (n == "fabric.mod.json" || n == "META-INF/mods.toml" || n == "META-INF/neoforge.mods.toml"))
                {
                    ReadMeta(n, Encoding.UTF8.GetString(ReadBytes(e)), r);
                }

                if (n.EndsWith(".class"))
                {
                    ClassStats(n, r);
                    if (depth == 0) { r.OwnClasses++; }
                    if (e.Length > 0 && e.Length < 6000000)
                    {
                        int len = ReadShared(e);
                        ScanContent(Encoding.UTF8.GetString(tBuf, 0, len), r, n);
                    }
                }
                else if (n.EndsWith(".json") || n.EndsWith("MANIFEST.MF"))
                {
                    if (e.Length > 0 && e.Length < 6000000)
                    {
                        int len = ReadShared(e);
                        ScanContent(Encoding.UTF8.GetString(tBuf, 0, len), r, null);
                    }
                }
                else if (depth < 3 && n.StartsWith("META-INF/") && n.EndsWith(".jar"))
                {
                    if (depth == 0) { r.NestedJars.Add(n.Substring(n.LastIndexOf('/') + 1)); }
                    if (e.Length > 0 && e.Length < 150000000)
                    {
                        using (MemoryStream ms = new MemoryStream(ReadBytes(e)))
                        using (ZipArchive nz = new ZipArchive(ms, ZipArchiveMode.Read))
                        {
                            string prevNest = nestPath;
                            nestPath = n.Substring(n.LastIndexOf('/') + 1);
                            try { ScanArchive(nz, r, depth + 1); }
                            finally { nestPath = prevNest; }
                        }
                    }
                }
            }
            catch (Exception) { }
        }
    }

    static void TolerantScan(string path, JarResultV2 r)
    {
        FileInfo fi = new FileInfo(path);
        if (fi.Length > 300000000) { return; }
        byte[] d = File.ReadAllBytes(path);
        for (long i = 0; i + 30 < d.LongLength; i++)
        {
            if (d[i] != 0x50 || d[i + 1] != 0x4B || d[i + 2] != 3 || d[i + 3] != 4) { continue; }
            int nl = d[i + 26] | (d[i + 27] << 8);
            if (nl == 0 || i + 30 + nl > d.LongLength) { continue; }
            string name = Encoding.UTF8.GetString(d, (int)i + 30, nl);
            if (name.EndsWith(".class"))
            {
                r.Classes++; r.OwnClasses++;
                if (EntryRegex != null && EntryMayMatch(name)) { foreach (Match m in EntryRegex.Matches(name)) { AddU(r.PatternHits, m.Value); } }
            }
        }
    }

    public static JarResultV2 ScanJar(string path)
    {
        EnsureBuilt();
        JarResultV2 r = new JarResultV2();
        r.ExHit = new bool[ExactNeedles.Length];
        r.StHit = new bool[StrongKeys.Length];
        r.ObHit = new bool[ObfNeedles.Length];
        try
        {
            using (ZipArchive z = ZipFile.OpenRead(path)) { ScanArchive(z, r, 0); }
        }
        catch (Exception ex)
        {
            r.Error = ex.Message; r.Malformed = true;
            try { TolerantScan(path, r); } catch (Exception) { }
        }
        Finish(r);
        return r;
    }

    static string Sha1Hex(string path)
    {
        try
        {
            using (FileStream fs = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete, 81920))
            using (SHA1 sha = SHA1.Create())
            {
                byte[] h = sha.ComputeHash(fs);
                StringBuilder sb = new StringBuilder(h.Length * 2);
                for (int i = 0; i < h.Length; i++) { sb.Append(h[i].ToString("x2")); }
                return sb.ToString();
            }
        }
        catch (Exception) { return null; }
    }

    public static ScanJobV2 StartScan(string[] paths, int threads)
    {
        EnsureBuilt();
        ScanJobV2 job = new ScanJobV2();
        job.Total = paths.Length;
        job.Results = new JarResultV2[paths.Length];
        job.Hashes = new string[paths.Length];
        job.Errors = new string[paths.Length];
        if (threads < 1) { threads = 1; }
        job.Task = Task.Factory.StartNew(delegate()
        {
            ParallelOptions po = new ParallelOptions();
            po.MaxDegreeOfParallelism = threads;
            Parallel.For(0, paths.Length, po, delegate(int i)
            {
                try
                {
                    job.Hashes[i] = Sha1Hex(paths[i]);
                    job.Results[i] = ScanJar(paths[i]);
                }
                catch (Exception ex) { job.Errors[i] = ex.Message; }
                Interlocked.Increment(ref job.Done);
            });
        }, TaskCreationOptions.LongRunning);
        return job;
    }

    public static bool HasZipMagic(string path)
    {
        try
        {
            using (FileStream fs = File.OpenRead(path))
            {
                byte[] b = new byte[4];
                if (fs.Read(b, 0, 4) < 4) { return false; }
                return b[0] == 0x50 && b[1] == 0x4B && (b[2] == 3 || b[2] == 5) && (b[3] == 4 || b[3] == 6);
            }
        }
        catch (Exception) { return false; }
    }
}
'@
if (-not ('P1ScanV2' -as [type])) {
    if ($PSVersionTable.PSVersion.Major -ge 6) { Add-Type -TypeDefinition $scanSource }
    else { Add-Type -TypeDefinition $scanSource -ReferencedAssemblies 'System.IO.Compression','System.IO.Compression.FileSystem' }
}

$cheatStrings = @(
    "isObsidianOrBedrock","isValidCrystalPosition","processAnchorPvP","isValidAnchorPosition","speedPotSlot","strengthPotSlot","preventSwordBlockBreaking","preventSwordBlockAttack",
    "Sw1tch","D3l4y","M1n","Pl4ce","T0t3m","Sl0t","Expl0de",
    "Cry5t4l","C11ckGu1","obsPos","crystalslot","findKnockbackSword","attackRegisteredThisClick","freecam","pushOutOfBlocks",
    "onPushOutOfBlocks","MAX_ESPERA_TICKS","posCristal","modifyDecrementAmount","preventSwordFromBlockAttack","preventSwordFromBlockBreaking","shouldBlockBlockHit","lwfh",
    "Donut","setBlockBreakingCooldown","getBlockBreakingCooldown","setItemUseCooldown","onBlockBreaking","invokeDoAttack","invokeDoItemUse","setSelectedSlot",
    "getSelectedSlot","swapBackToOriginalSlot","blockBreakingCooldown","invokeOnMouseButton","onSwapLastAttackedTicksReset","getVisualAttackCooldownProgressPerTick","getHandSwingDuration","onBeginRenderTick",
    "PlayerMoveC2SPacketAccessor","redirectSelectedSlot","hookCancelBlockBreaking","EndCrystalItemMixin","arrayOfString","lvstrng","dqrkis","StringObfuscator",
    "POT_CHEATS","onShouldRenderBlockOutline","predictCrystals","noOffhandTotem","getNearByCrystals","slotExplode","needToPlaceRails","findTotemSlot",
    "activateOnRightClick","crystalPlaceClock","isDeadBodyNearby","CrystalTwiceClock","mainHandStack","attackInAir","attackOnJump","onDestruct",
    "getGlowstoneChance","isAutoCharge","getPlaceChance","getSwitchDelay","getGlowstoneDelay","getExplodeDelay","getExplodeSlotIndex","getPlaceDelayTicks",
    "getBreakDelayTicks","getBreakChance","isSpawnersEnabled","isShulkersEnabled","onModuleDisabled","switchToBestTool","switchToBestWeapon","isLootProtect",
    "getMinHunger","isTracersEnabled","getSelectedBlocks","isChestsEnabled","4ctivat K3y","D4m4ge T1ck","Sw1tch D3lay","Ch4rg3 D3l4y",
    "inventoryToMenuSlot","throwPearl","isLeftHoldOnly","Automatically switches to sword when hitting with totem","Failed to switch to mace after axe!","Breaking shield with axe...","TrilliumSolutions","CwskKkUfHQYB",
    "HgsCDQ49KkUfHQYB","DhsnbQ0LDg0MDA","OhYHBQcOHw","EgQKDiUqRR8WChk","KjoFWRcEAx0M","Hx0GAVkcChwdDA","HSw7RQQIAQQ","BR0sFBcOGg4a",
    "Oh0yWR0MCA","pedroisgay","krloader","K3yAHC","Aut0 H1t Cryst4l M4cr0","D0ubl3 4nch0r","Aut0H1tCyst4l","Pr3Ch3ck",
    "Expl0d3 D3l4y","T0t3m Sl0t","Ch4rge D3l4y","M1ss Ch4nce","Expl0de Sl0t","Expl0d3 Sl0t","N0 Dglwst0ne","Clk Sim",
    "P34rl C4tch3r","4ctiv4tK3y","d4m4geT1ck","sw1tchD3lay","ch4rg3D3l4y","expl0d3D3l4y","t0t3mSl0t","simulateClicks",
    "Aut0 XP","Thr0w3 XP f4st","W1nd Ch4rg3","P34rl","4c7 K3y",
    "healPotSlot","holdCrystal","stopOnKill","placeInterval","breakInterval","POST_CYCLE_DELAY","PLACE_OBI","WAIT_OBI","DOUBLE_ESCAPE",
    "DOUBLE_RIGHTCLICK_FIRST","DOUBLE_RIGHTCLICK_SECOND","REOFFHAND_TOTEM","Places two anchors for massive damage",
    "Entity.isGlowing","Automatically axe and mace shielded players",
    "aHR0cDovL2FwaS5ub3ZhY2xpZW50LmxvbC93ZWJob29rLnR4dA==","api.novaclient.lol","dqrkis.xyz","vape.gg","prestigeclient.vip","doomsdayclient","intent.store","riseclient.com",
    "org/chainlibs/module/impl/modules","dev/gambleclient","xyz/greaj","dev/krypton","skid/krypton","com/cheatbreaker","net/ccbluex","today/opai","club/maxstats",
    "wtf/moonlight","me/zeroeightsix/kami","com/alan/clients","cc/novoline","net/minecraft/injection","meteordevelopment.meteorclient",
    "SessionStealer","TokenLogger","TokenGrabber","DiscordToken","ReverseShell","KeyLogger","JDWP.VirtualMachine.AllModules"
)

$strongNames = @(
    "AutoCrystal","AutoHitCrystal","CrystalAura","CrystalMacro","AutoCrystalPlaceClock",
    "DontPlaceCrystal","DontBreakCrystal","CanPlaceCrystalServer","KanPlaceKrystalServer",
    "EsperandoCristal","BuscarCristal",
    "clickSimulation","switchDelay","switchChance","placeChance","glowstoneDelay","glowstoneChance","explodeDelay","explodeChance",
    "explodeSlot","antiWeakness","damageTick","breakChance","breakDelay","stopOnCrystal","processCrystal","swapToWeapon",
    "AutoAnchor","DoubleAnchor","SafeAnchor","AirAnchor","AnchorMacro","AnchorAura","AnchorTweaks","AnchorAction",
    "AutoTotem","HoverTotem","InventoryTotem","LegitTotem","LegitReTotem","ForceTotem","OffhandTotem","TotemSwitch","ReOffhandTotem",
    "AutoPot","AutoPotRefill","AutoNethPot","AutoArmor","AutoDoubleHand","AutoClicker",
    "AutoFirework","AutoEat","AutoMine","AutoWeb","AntiWeb","WebMacro",
    "AutoMace","MaceSwap","SpearSwap","StunSlam","Macro198","AutoDtap",
    "AimAssist","TriggerBot","SilentAim","AimLock","KillAura","ClickAura","MultiAura",
    "LegitAura","BowAimbot","ShieldDisabler","ShieldBreaker","AxeSpam",
    "FakeLag","PingSpoof","FakeInv","FakePunch","PackSpoof","AntiKnockback",
    "ElytraSwap","KeyPearl","LootYeeter","AutoBreach","FastPlace","JumpReset","PopSwitch",
    "SprintReset","ChestSteal","BaseFinder","StashFinder","SelfDestruct",
    "WalksyOptimizer","WalskyOptimizer","WalksyCrystalOptimizerMod",
    "AuthBypass","LicenseCheckMixin","ObfuscatedAuth","GrimBypass","GrimDisabler",
    "GrimVelocity","VulcanBypass","MatrixBypass","WatchdogBypass","IntaveBypass","VerusDisabler","AACBypass",
    "DqrkisClient","NovaClient","DoomsdayClient","PrestigeClient","VapeClient","VapeLite",
    "LiquidBounce","MeteorClient","RusherHack","ImpactClient","FutureClient",
    "CatleanClient","AsteriaClient","XenonClient","GypsyClient",
    "Aut0Cryst3l","Aut0Cryst4l","Aut0H1tCryst3l","Aut0H1tCryst4l","Anch0rMacr0",
    "Anch0rM4cr0","4nch0rM4cr0","D0uble4nch0r","D0ubl3Anch0r","S4feAnch0r","S4fe4nch0r",
    "Aut0T0t3m","H0verT0t3m","L3g1tR3t0t3m","Aut0D0ubl3H4nd","Aut0Stun",
    "AutoTPA","AutoBed","BedAura","BedBomb","AnchorFill","AutoBow","BowSpam","AutoCrit","CritBypass","ReachHack","ExtendReach","HitboxExpand",
    "VelocitySpoof","AutoCity","SelfTrap","HoleFiller","TargetStrafe","PacketFly","BoatFly","ScaffoldWalk","InstantBreak","StorageESP","PlayerESP",
    "CaveFinder","OreFinder","TargetHUD","ButterflyClick","JitterClick","InvMovebypass","FakeLatency","SpoofRotation","PacketDupe","HideClient",
    "ChestStealer","CPSBoost","DoubleClicker","SpeedHack","FlyHack","WallHack"
)

$fwLabels = @(
    "Place Delay","Break Delay","Place Chance","Break Chance","Stop On Kill","Damage Tick","Anti Weakness","Switch Delay","Totem Slot","Silent Rotations",
    "Smooth Rotations","Glowstone Delay","Glowstone Chance","Explode Delay","Explode Chance","Explode Slot","Anchor Macro","Click Simulation","Activate Key",
    "Fake Punch","Hover Totem","Loot Yeeter","Mace Priority","Stun Slam","Auto Pot Refill","Predict Crystals","Trigger Key","Reach Distance","Web Delay",
    "Breach Delay","Require Elytra","Swap Speed","Min Totems","Min Pearls","Drop Interval","Force Totem","Auto Inventory Totem","Only On Pop","Include Head",
    "Horizontal Aim Speed","Vertical Aim Speed","Stay Open For","Particle Chance","Rotation Speed","Easing Strength","Check Shield","Totem First",
    "Random Pattern","No Bounce","No Count Glitch","Attack Delay","Hit Delay","Require Hold Axe","Not When Affects Player","Only Charge","Explode Slot",
    "Fast Mode","Strict One-Tick","Stop On Crystal","Predict Damage","Auto Switch Back","Check Line of Sight","Only When Falling","Require Crit","Show Status Display"
)

$obfSignatures = @(
    @{Sig="dev/skidfuscator";Name="Skidfuscator"}, @{Sig="skidfuscator.dev";Name="Skidfuscator"}, @{Sig="Skidfuscator";Name="Skidfuscator"},
    @{Sig="dev/paramorphism";Name="Paramorphism"}, @{Sig="paramorphism-";Name="Paramorphism"}, @{Sig="Paramorphism";Name="Paramorphism"},
    @{Sig="me/itzsomebody/radon";Name="Radon"}, @{Sig="ItzSomebody/Radon";Name="Radon"}, @{Sig="Radon Obfuscator";Name="Radon"},
    @{Sig="dev/sim0n/caesium";Name="Caesium"}, @{Sig="sim0n/Caesium";Name="Caesium"}, @{Sig="Caesium Obfuscator";Name="Caesium"},
    @{Sig="vimasig/Bozar";Name="Bozar"}, @{Sig="com/bozar";Name="Bozar"}, @{Sig="Bozar Obfuscator";Name="Bozar"},
    @{Sig="branchlock.dev";Name="Branchlock"}, @{Sig="Branchlock";Name="Branchlock"},
    @{Sig="com/binscure";Name="Binscure"}, @{Sig="Binscure";Name="Binscure"},
    @{Sig="superblaubeere27";Name="SuperBlaubeere27"}, @{Sig="superblaubeere";Name="SuperBlaubeere27"},
    @{Sig="Qprotect";Name="Qprotect"}, @{Sig="QProtect";Name="Qprotect"}, @{Sig="mdma.dev/qprotect";Name="Qprotect"},
    @{Sig="ZKMFLOW";Name="Zelix KlassMaster"}, @{Sig="ZelixKlassMaster";Name="Zelix KlassMaster"}, @{Sig="com/zelix";Name="Zelix KlassMaster"},
    @{Sig="StringerJavaObfuscator";Name="Stringer"}, @{Sig="com/licel/stringer";Name="Stringer"},
    @{Sig="jnic.obf";Name="JNIC"}, @{Sig="jnic-obfuscator";Name="JNIC"},
    @{Sig="ScutiObf";Name="Scuti"}, @{Sig="scuti.obf";Name="Scuti"},
    @{Sig="SmokeObf";Name="Smoke"}, @{Sig="smoke.obf";Name="Smoke"}
)

$entryPatterns = @(
    "AimAssist","AnchorTweaks","AutoAnchor","AutoCrystal","AutoDoubleHand","AutoHitCrystal","AutoPot","AutoTotem","AutoArmor","InventoryTotem",
    "LegitTotem","PingSpoof","SelfDestruct","ShieldBreaker","TriggerBot","AxeSpam","WebMacro","FastPlace","WalskyOptimizer","WalksyOptimizer",
    "walsky.optimizer","WalksyCrystalOptimizerMod","ShieldDisabler","SilentAim","FakeLag","BlockESP","AntiMissClick","LagReach","PopSwitch",
    "SprintReset","ChestSteal","ElytraSwap","FastXP","FastExp","AirAnchor","FakeInv","HoverTotem","AutoClicker","AutoFirework","PackSpoof",
    "Antiknockback","AuthBypass","AutoEat","AutoMine","MaceSwap","Macro198","StunSlam","SafeAnchor","DoubleAnchor","AutoTPA","BaseFinder",
    "AutoPotRefill","KeyPearl","AutoNethPot","AutoDtap","AutoWeb","AnchorAction","BowAim","FakeItem","ItemExploit","Hellion","LicenseCheckMixin",
    "obfuscatedAuth","phantom-refmap.json","client-refmap.json","cheat-refmap.json","dev/virel","dev.virel","dev.krypton","dev/krypton","skid.krypton","skid/krypton",
    "dev.gambleclient","dev/gambleclient","xyz.greaj","xyz/greaj","imgui.gl3","imgui.glfw","imgui.binding","jnativehook","JNativeHook","NativeKeyListener",
    "org.chainlibs.module.impl.modules","org/chainlibs/module/impl/modules","KillAura","CrystalAura","AnchorAura","BedAura","LootYeeter","StashFinder",
    "PacketFly","ScaffoldWalk","ChestStealer","TargetStrafe","SessionStealer","TokenGrabber","ReverseShell",
    "AutoHitCyst4l","Aut0Cryst4l","Aut0Cryst3l","Anch0rMacr0",
    ([string][char]0x3058 + ".class"),([string][char]0x3075 + ".class"),([string][char]0x3076 + ".class"),([string][char]0x3077 + ".class"),([string][char]0x305F + ".class"),
    ([string][char]0x306D + ".class"),([string][char]0x305D + ".class"),([string][char]0x306A + ".class"),([string][char]0x3069 + ".class"),([string][char]0x3050 + ".class"),
    ([string][char]0x305A + ".class"),([string][char]0x3067 + ".class"),([string][char]0x3064 + ".class"),([string][char]0x3079 + ".class"),([string][char]0x305B + ".class"),
    ([string][char]0x3068 + ".class"),([string][char]0x307F + ".class"),([string][char]0x3073 + ".class"),([string][char]0x3059 + ".class"),([string][char]0x306E + ".class")
)

$disallowedMods = @{
    "xeros-minimap"=@("Xero's Minimap","Xeros Minimap","xeros-minimap","XerosMinimap")
    "freecam"=@("Freecam","Free Cam")
    "health-indicators"=@("Health Indicators","HealthIndicators")
    "clickcrystals"=@("ClickCrystals","Click Crystals")
    "mousetweaks"=@("Mouse Tweaks","MouseTweaks")
    "itemscroller"=@("Item Scroller","ItemScroller")
    "inventory-profiles-next"=@("Inventory Profiles Next","InventoryProfilesNext","Inventory Profiles")
    "tweakeroo"=@("Tweakeroo")
    "kinds-crystal-optimizer"=@("Kind's Crystal Optimizer","Kinds Crystal Optimizer","KindsCrystalOptimizer","KindCrystalOptimizer")
    "g1ax-crystal-optimizer"=@("G1ax Crystal Optimizer","G1axCrystalOptimizer","G1ax")
    "shikarus-crystal-optimizer"=@("Shikaru's Crystal Optimizer","Shikarus Crystal Optimizer","ShikaruCrystalOptimizer","ShikarusCrystalOptimizer")
    "hcscr"=@("HCsCR","HCs Crystal Optimizer")
    "hazel-crystal-optimizer"=@("Hazel Crystal Optimizer","HazelCrystalOptimizer")
    "psychodreams-crystal-optimizer"=@("Psychodreams CrystalOptimizer","Psychodreams Crystal Optimizer","PsychodreamsCrystalOptimizer")
    "walksys-crystal-optimizer"=@("Walksy's Crystal Optimizer","Walksys Crystal Optimizer","WalksyCrystalOptimizer","Walksy Crystal Optimizer")
    "no-delay-optimizer"=@("No delay Optimizer","NoDelayOptimizer","No Delay Optimizer")
    "safe-crystals"=@("Safe Crystals","SafeCrystals")
    "nocrystalrefresh"=@("NoCrystalRefresh","No Crystal Refresh")
    "psychodreams-antirefreshcrystal"=@("Psychodreams Antirefreshcrystal","PsychodreamsAntirefreshcrystal","AntiRefreshCrystal","Anti Refresh Crystal")
    "crystal-macro"=@("Crystal Macro Mod","Crystal Macro","CrystalMacro")
    "auto-crystal-switcher"=@("Auto Crystal Switcher","AutoCrystalSwitcher")
    "kinds-anchor-optimizer"=@("Kind's Anchor Optimizer","Kinds Anchor Optimizer","KindsAnchorOptimizer","KindAnchorOptimizer")
    "tenites-anchor-optimizer"=@("Tenite's anchor optimizer","Tenites anchor optimizer","TenitesAnchorOptimizer","TeniteAnchorOptimizer")
    "vixsls-anchor-optimizer"=@("Vixsl's Anchor Optimizer","Vixsls Anchor Optimizer","VixslAnchorOptimizer","VixslsAnchorOptimizer")
    "diolez-anchor-optimizer"=@("DiolezAnchorOptimizer","Diolez Anchor Optimizer")
    "dokkos-hotbar-optimizer"=@("Dokko's hotbar optimizer","Dokkos hotbar optimizer","DokkosHotbarOptimizer","DokkoHotbarOptimizer")
    "bobs-hotbar-optimizer"=@("bob's hotbar optimizer","bobs hotbar optimizer","BobsHotbarOptimizer","BobHotbarOptimizer")
    "gloryis-keyboard-optimizer"=@("Gloryi's Keyboard Optimizer","Gloryis Keyboard Optimizer","GloryiKeyboardOptimizer","GloryisKeyboardOptimizer")
    "jellos-pvp-optimizer"=@("Jello's pvp optimizer","Jellos pvp optimizer","JellosPvpOptimizer","JelloPvpOptimizer")
    "pvp-optimizer"=@("PVP Optimizer","PVPOptimizer")
    "lunartweaks"=@("LunarTweaks","Lunar Tweaks")
    "no-shield-delay"=@("No Shield Delay","NoShieldDelay")
    "no-mining-cooldown"=@("No Mining Cooldown","NoMiningCooldown")
    "no-jump-delay"=@("No Jump Delay Enhanced","No Jump Delay","NoJumpDelay","NoJumpDelayEnhanced")
    "lwfh-airplace"=@("lwfh Airplace","lwfh","Airplace")
    "autototem-catchall"=@("AutoTotem","Auto Totem","auto-totem")
    "d-hand"=@("D-hand mod","D-hand","DHand","Double Hand Mod")
}

$falseFlagSlugs = @{
    "viafabricplus"   = "ViaFabricPlus is a known legit mod that contains these strings"
    "viafabricversion"= "ViaFabricVersion is a known legit mod that contains these strings"
    "simple-voice-chat"= "Simple Voice Chat is a known legit mod (contains freecam / switchDelay strings)"
    "herobot"         = "HeroBot is a known legit mod (contains ShieldDisabler string)"
    "inventory-profiles-next" = ""
    "inventoryprofilesnext"   = ""
}
$script:MinDownloads = 2000
$knownLegitModIds = @("vmp-fabric","vmp","lithium","sodium","iris","fabric-api","modmenu","ferrite-core","lazydfu","starlight","entityculling",
                      "memoryleakfix","krypton","c2me-fabric","smoothboot-fabric","immediatelyfast","noisium","threadtweak")
$legitAgents = @('jmxremote','yjp','jrebel','newrelic','jacoco','theseus')
$mavenPrefixes = @("com_","org_","net_","io_","dev_","gs_","xyz_","app_","me_","tv_","uk_","be_","fr_","de_")

$exactSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($s in $cheatStrings) { [void]$exactSet.Add($s) }

$strongMap = @{}
foreach ($n in $strongNames) {
    $k = ($n -replace '[^a-zA-Z0-9]','').ToLowerInvariant()
    if ($k.Length -ge 5 -and -not $strongMap.ContainsKey($k)) { $strongMap[$k] = $n }
}
$strongKeys = @($strongMap.Keys | Sort-Object -Property Length -Descending)
$fwMap = @{}
foreach ($s in ($fwLabels + $cheatStrings)) {
    if ($s -notmatch '[a-zA-Z]') { continue }
    $k = ($s -replace '[^a-zA-Z0-9]','').ToLowerInvariant()
    if ($k.Length -ge 5 -and -not $fwMap.ContainsKey($k) -and -not $strongMap.ContainsKey($k)) { $fwMap[$k] = $s }
}
$fwKeys = @($fwMap.Keys | Sort-Object -Property Length -Descending)
$script:StrongKeyArr = [string[]]$strongKeys
$script:StrongValArr = [string[]]@($strongKeys | ForEach-Object { $strongMap[$_] })
$script:FwKeyArr = [string[]]$fwKeys
$script:FwValArr = [string[]]@($fwKeys | ForEach-Object { $fwMap[$_] })

[P1ScanV2]::ExactNeedles = [string[]]@($exactSet)
[P1ScanV2]::StrongKeys   = [string[]]$strongKeys
[P1ScanV2]::StrongNames  = [string[]]@($strongKeys | ForEach-Object { $strongMap[$_] })
[P1ScanV2]::ObfNeedles   = [string[]]@($obfSignatures | ForEach-Object { $_.Sig })
[P1ScanV2]::ObfNames     = [string[]]@($obfSignatures | ForEach-Object { $_.Name })
[P1ScanV2]::SetEntryPatterns([string[]]$entryPatterns)

$jvmRules = @(
    @{ Cat='Fabric injection';        Rx='-Dfabric\.(addMods|loadMods|classPathGroups|gameJarPath|skipMcProvider|development|allowUnsupportedVersion|remapClasspathFile|skipIntermediary|customModList|resolve\.modFiles|skipDependencyResolution|loader\.entrypoints|language\.providers|mods\.toml\.path|mixin\.hotSwap|mixin\.configs|mixin\.debug\.export|debug\.dumpClasspath)=\S*' },
    @{ Cat='Forge injection';         Rx='-D(forge\.(addMods|mods|coreMods\.dir|modDir|modsDirectories|modList|disableModScan|mixin\.hotSwap)|fml\.(coreMods\.load|customModList))=\S*' },
    @{ Cat='Security bypass';         Rx='-Djava\.security\.(manager|policy)=\S*' },
    @{ Cat='Classpath manipulation';  Rx='(-Xbootclasspath[/:]?[pa]?[:=]?\S*|-Djava\.system\.class\.loader=\S*|-Djava\.class\.path=\S*)' },
    @{ Cat='Native agent';            Rx='-agentpath:\S+' },
    @{ Cat='Debug agent (JDWP)';      Rx='(-agentlib:jdwp\S*|-Xrunjdwp\S*)' },
    @{ Cat='Attach API blocked';      Rx='-XX:\+DisableAttachMechanism' },
    @{ Cat='Cheat client brand';      Rx='-D(client|launcher)\.brand=(Wurst|Aristois|Impact|Kilo|Future|Lambda|Rusher|Konas|Phobos|Salhack|ForgeHax|Mathax|Meteor|Async|Seppuku|Xatz|Wolfram|Huzuni|Jigsaw|Zamorozka|Moon|Rage|Exhibition|Virtue|Novoline|Rekt|Skid|Ares|Abyss|Thunder|Tenacity|Rise|Flux|Gamesense|Intent|Remix|Sight|Vape|Shield|Ghost|Crispy|Inertia)\S*' },
    @{ Cat='Cheat property';          Rx='-D(xray|fly|speed|killaura|reach|esp|wallhack|noclip|autoclick|aimbot|triggerbot|antiknockback|nofall|timer|step|fullbright|nightvision|cavefinder)\.\S*' },
    @{ Cat='Cheat client name';       Rx='(?i)(wurst|aristois|rusherhack|konas|phobos|salhack|forgehax|mathax|seppuku|huzuni|zamorozka|novoline|liquidbounce|meteor-?client|vapeclient|doomsday|prestigeclient)[\w\.\-]*' },
    @{ Cat='Encoded injection';       Rx='(%3B|%26%26|%7C%7C|%7C|%60|%24|%3C|%3E)' }
)

function Get-ProcessCurrentDirectory([int]$processId) {
    try { return [ProcessHelper]::GetCurrentDirectory($processId) } catch { return $null }
}
function Get-ProcessCommandLineNative([int]$processId) {
    try { return [ProcessHelper]::GetCommandLine($processId) } catch { return $null }
}

$script:WmiCmdByPid = $null
function Get-WmiCommandLineByName([int]$processId) {
    if ($null -eq $script:WmiCmdByPid) {
        $script:WmiCmdByPid = @{}
        foreach ($name in @('javaw.exe', 'java.exe')) {
            try {
                foreach ($w in @(Get-WmiObject Win32_Process -Filter "Name = '$name'" -ErrorAction SilentlyContinue)) {
                    if ($w.ProcessId -and $w.CommandLine) {
                        $script:WmiCmdByPid[[int]$w.ProcessId] = [string]$w.CommandLine
                    }
                }
            } catch {}
            try {
                foreach ($w in @(Get-CimInstance Win32_Process -Filter "Name = '$name'" -ErrorAction SilentlyContinue)) {
                    if ($w.ProcessId -and $w.CommandLine -and -not $script:WmiCmdByPid.ContainsKey([int]$w.ProcessId)) {
                        $script:WmiCmdByPid[[int]$w.ProcessId] = [string]$w.CommandLine
                    }
                }
            } catch {}
        }
    }
    if ($script:WmiCmdByPid.ContainsKey($processId)) { return $script:WmiCmdByPid[$processId] }
    return $null
}

function Get-LayoutBases([string]$path) {
    return @($path, (Join-Path $path ".minecraft"), (Join-Path $path "game"), (Join-Path $path "minecraft"))
}
function Resolve-ModsFolder([string]$cwd) {
    if (-not $cwd -or -not (Test-Path -LiteralPath $cwd -ErrorAction SilentlyContinue)) { return $null }
    foreach ($base in (Get-LayoutBases $cwd)) {
        $p = Join-Path $base "mods"
        if (Test-Path -LiteralPath $p -ErrorAction SilentlyContinue) { return (Get-Item -LiteralPath $p).FullName }
    }
    try {
        foreach ($entry in (Get-ChildItem -LiteralPath $cwd -Directory -ErrorAction SilentlyContinue)) {
            foreach ($base in (Get-LayoutBases $entry.FullName)) {
                $p = Join-Path $base "mods"
                if (Test-Path -LiteralPath $p -ErrorAction SilentlyContinue) { return (Get-Item -LiteralPath $p).FullName }
            }
        }
    } catch {}
    return $null
}
function Get-CleanDirectory([string]$raw) {
    if (-not $raw) { return $null }
    $p = $raw.Trim().Trim('"').Trim("'").Trim()
    if (-not $p) { return $null }
    try { $p = [System.Environment]::ExpandEnvironmentVariables($p) } catch {}
    try {
        if (Test-Path -LiteralPath $p -PathType Leaf -ErrorAction SilentlyContinue) { $p = [System.IO.Path]::GetDirectoryName($p) }
        if (-not $p -or -not (Test-Path -LiteralPath $p -PathType Container -ErrorAction SilentlyContinue)) { return $null }
        return (Get-Item -LiteralPath $p -ErrorAction Stop).FullName
    } catch { return $null }
}
function Request-ModsFolder([string]$reason, [string]$giveUp = "Press Enter on an empty line to give up.") {
    if ($reason) { Write-Warn $reason }
    Write-Dim "Enter the mods folder, the instance folder, or the .minecraft folder." 4
    Write-Dim $giveUp 4
    for ($try = 0; $try -lt 5; $try++) {
        Write-Host "    path $gPrompt " -NoNewline -ForegroundColor Cyan
        $raw = Read-Host
        if (-not $raw -or -not $raw.Trim()) { return $null }
        $dir = Get-CleanDirectory $raw
        if (-not $dir) { Write-Fail "That path does not exist on this machine." 4; continue }
        if ([System.IO.Path]::GetFileName($dir.TrimEnd('\','/')) -eq "mods") { Write-Ok "Using mods folder: $dir" 4; return $dir }
        $res = Resolve-ModsFolder $dir
        if ($res) { Write-Ok "Using mods folder: $res" 4; return $res }
        $jarCount = @(Get-ChildItem -LiteralPath $dir -Filter *.jar -Force -ErrorAction SilentlyContinue).Count
        Write-Warn "No mods folder under that path ($jarCount .jar file(s) directly inside)." 4
        Write-Host "    scan it anyway? [y/N] $gPrompt " -NoNewline -ForegroundColor Cyan
        $c = Read-Host
        if ($c -and $c.Trim() -match '^(y|yes)$') { Write-Ok "Using folder: $dir" 4; return $dir }
    }
    return $null
}
function Get-KnownLauncherRoots {
    $appData = $env:APPDATA; $local = $env:LOCALAPPDATA; $up = $env:USERPROFILE
    $roots = [System.Collections.Generic.List[string]]::new()
    if ($appData) {
        foreach ($s in @('.minecraft','ModrinthApp\profiles','PrismLauncher\instances','PolyMC\instances','MultiMC\instances','ATLauncher\instances',
                         '.feather\profiles','.dawn\profiles','gdlauncher_next\instances','.technic\modpacks','.ftba\instances')) { $roots.Add("$appData\$s") }
    }
    if ($local) { $roots.Add("$local\.minecraft") }
    if ($up) {
        $roots.Add("$up\curseforge\minecraft\Instances"); $roots.Add("$up\Documents\curseforge\minecraft\Instances")
        $roots.Add("$up\.lunarclient"); $roots.Add("$up\Documents\PrismLauncher\instances")
    }
    return ($roots | Select-Object -Unique)
}
function Find-LatestInstanceByLog {
    $bestBase = $null; $bestTime = [datetime]::MinValue; $checked = 0
    foreach ($root in (Get-KnownLauncherRoots)) {
        if (-not (Test-Path -LiteralPath $root -ErrorAction SilentlyContinue)) { continue }
        $bases = New-Object System.Collections.Generic.List[string]
        foreach ($b in (Get-LayoutBases $root)) { $bases.Add($b) }
        foreach ($e in (Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue)) { foreach ($b in (Get-LayoutBases $e.FullName)) { $bases.Add($b) } }
        foreach ($base in $bases) {
            $log = Join-Path $base "logs\latest.log"
            if (-not (Test-Path -LiteralPath $log -ErrorAction SilentlyContinue)) { continue }
            $checked++
            try { $t = (Get-Item -LiteralPath $log -ErrorAction Stop).LastWriteTime; if ($t -gt $bestTime) { $bestTime = $t; $bestBase = $base } } catch {}
        }
    }
    Write-Dim "Checked $checked instance log(s) across all known launchers" 4
    if ($bestBase) { Write-Dim "Newest latest.log: $bestTime  $gArrow  $bestBase" 4 }
    return $bestBase
}
function Get-PlayerFromInstanceLog([string]$modsFolder) {
    if (-not $modsFolder) { return $null }
    $dir = $modsFolder
    for ($i = 0; $i -lt 4 -and $dir; $i++) {
        foreach ($rel in @('logs\latest.log', 'minecraft\logs\latest.log')) {
            $log = Join-Path $dir $rel
            if (-not (Test-Path -LiteralPath $log -ErrorAction SilentlyContinue)) { continue }
            try {
                $lines = Get-Content -LiteralPath $log -Tail 400 -ErrorAction Stop
                $head = Get-Content -LiteralPath $log -TotalCount 80 -ErrorAction SilentlyContinue
                $blob = @($head) + @($lines)
                foreach ($line in $blob) {
                    if ($line -match 'Setting user:\s*(\S+)') { return $matches[1].Trim() }
                    if ($line -match 'Logged in as\s+(\S+)') { return $matches[1].Trim() }
                    if ($line -match '\[CHAT\]\s+(\S+)\s+joined') { return $matches[1].Trim() }
                }
            } catch {}
        }
        $dir = Split-Path -Parent $dir
    }
    return $null
}

function Resolve-ModsFromLibraryPath([string]$libPath) {
    if (-not $libPath) { return $null }
    $p = $libPath.Trim().Trim('"').Trim("'")
    foreach ($part in ($p -split ';')) {
        $part = $part.Trim()
        if (-not $part) { continue }
        try {
            if (-not (Test-Path -LiteralPath $part -ErrorAction SilentlyContinue)) { continue }
            $dir = (Get-Item -LiteralPath $part -ErrorAction Stop).FullName
            $cur = $dir
            for ($i = 0; $i -lt 5 -and $cur; $i++) {
                $hit = Resolve-ModsFolder $cur
                if ($hit) { return $hit }
                $parent = Split-Path -Parent $cur
                if ($parent) {
                    $hit = Resolve-ModsFolder $parent
                    if ($hit) { return $hit }
                }
                $cur = $parent
            }
        } catch {}
    }
    return $null
}

function Get-MinecraftInstances {
    $found = New-Object System.Collections.Generic.List[object]
    $procs = @(); $procs += @(Get-Process -Name javaw -ErrorAction SilentlyContinue); $procs += @(Get-Process -Name java -ErrorAction SilentlyContinue)

    $null = Get-WmiCommandLineByName 0

    foreach ($proc in $procs) {
        $cmd = $null; $cimCwd = $null; $cmdSrc = $null

        $cmd = Get-WmiCommandLineByName $proc.Id
        if ($cmd) { $cmdSrc = 'WMI (by Name)' }

        if (-not $cmd) {
            try {
                $info = Get-CimInstance Win32_Process -Filter "ProcessId = $($proc.Id)" -ErrorAction Stop
                if ($info) {
                    if (-not [string]::IsNullOrWhiteSpace($info.CommandLine)) { $cmd = [string]$info.CommandLine; $cmdSrc = 'WMI/CIM (by PID)' }
                    $cimCwd = $info.CurrentDirectory
                }
            } catch {}
        }
        if (-not $cmd) {
            try {
                $w = Get-WmiObject Win32_Process -Filter "ProcessId = $($proc.Id)" -ErrorAction Stop
                if ($w -and -not [string]::IsNullOrWhiteSpace($w.CommandLine)) { $cmd = [string]$w.CommandLine; $cmdSrc = 'WMI (by PID)' }
            } catch {}
        }

        if (-not $cmd) {
            $native = Get-ProcessCommandLineNative $proc.Id
            if ($native) { $cmd = $native; $cmdSrc = 'native PEB' }
        }

        $player = "Unknown"; $uuid = "N/A"; $ver = $null
        if ($cmd) {
            if     ($cmd -match '--username\s+"([^"]+)"') { $player = $matches[1] }
            elseif ($cmd -match "--username\s+'([^']+)'") { $player = $matches[1] }
            elseif ($cmd -match '--username\s+(\S+)')     { $player = $matches[1] }
            if     ($cmd -match '--uuid\s+"([^"]+)"')     { $uuid = $matches[1] }
            elseif ($cmd -match '--uuid\s+(\S+)')         { $uuid = $matches[1] }
            if     ($cmd -match '--version\s+(\S+)')      { $ver  = $matches[1] }
        }

        $mods = $null; $src = $null

        if ($cmd) {
            $gd = $null
            if     ($cmd -match '--gameDir\s+"([^"]+)"') { $gd = $matches[1] }
            elseif ($cmd -match "--gameDir\s+'([^']+)'") { $gd = $matches[1] }
            elseif ($cmd -match '--gameDir\s+(\S+)')     { $gd = $matches[1] }
            if ($gd) { $mods = Resolve-ModsFolder $gd; if ($mods) { $src = "--gameDir" } }

            if (-not $mods -and $cmd -match '-Djava\.library\.path=("[^"]+"|[^\s]+)') {
                $lib = $matches[1].Trim('"')
                $mods = Resolve-ModsFromLibraryPath $lib
                if ($mods) { $src = "-Djava.library.path" }
            }
        }

        if (-not $mods) {
            $cwd = Get-ProcessCurrentDirectory $proc.Id
            if ($cwd) { $mods = Resolve-ModsFolder $cwd; if ($mods) { $src = "Process CWD (PEB)" } }
        }
        if (-not $mods -and $cimCwd) { $mods = Resolve-ModsFolder $cimCwd; if ($mods) { $src = "Win32_Process CWD" } }

        if ($player -eq 'Unknown' -and $mods) {
            $logPlayer = Get-PlayerFromInstanceLog $mods
            if ($logPlayer) { $player = $logPlayer }
        }

        $looks = $mods -or ($cmd -and $cmd -match '(?i)(minecraft|net\.fabricmc|cpw\.mods|fabric-loader|forge|net\.minecraft|PrismLauncher|MultiMC|Modrinth)')
        if (-not $looks) { continue }

        $start = $null; try { $start = $proc.StartTime } catch {}
        $found.Add([PSCustomObject]@{
            ProcessId=$proc.Id; ProcessName=$proc.ProcessName; Player=$player; UUID=$uuid; LaunchVer=$ver
            ModsFolder=$mods; Source=$src; CommandLine=$cmd; CmdSource=$cmdSrc; StartTime=$start
        })
    }
    return $found
}
function New-OfflineInstance([string]$mods, [string]$src) {
    return [PSCustomObject]@{ ProcessId=$null; ProcessName="(not running)"; Player="Unknown"; UUID="N/A"; LaunchVer=$null
                              ModsFolder=$mods; Source=$src; CommandLine=$null; CmdSource=$null; StartTime=$null }
}

Write-Section "Detect instance"
$instances = @()
if ($ManualOnly) {
    $p = Request-ModsFolder "Manual folder scan selected."
    if ($p) { $instances = @(New-OfflineInstance $p "Manual entry") }
} else {
    Write-Info "Looking for running Minecraft processes (javaw / java)..."
    $instances = @(Get-MinecraftInstances)
    if ($instances.Count -eq 0) {
        Write-Warn "No running Minecraft process found."
        $p = Request-ModsFolder "" "Press Enter on an empty line to search every known launcher's logs instead."
        $src = "Manual entry"
        if (-not $p) {
            Write-Info "Falling back to the newest logs\latest.log across all launchers..."
            $lb = Find-LatestInstanceByLog
            if ($lb) { $p = Resolve-ModsFolder $lb; $src = "Newest latest.log"; if ($p) { Write-Ok "Using most recently played instance: $p" } }
        }
        if ($p) { $instances = @(New-OfflineInstance $p $src) }
    }
    foreach ($inst in $instances) {
        if ($inst.ModsFolder) { continue }
        $r = Request-ModsFolder "Could not auto-detect the mods folder for PID $($inst.ProcessId) (player: $($inst.Player))." "Press Enter on an empty line to skip this instance."
        if ($r) { $inst.ModsFolder = $r; $inst.Source = "Manual entry" }
    }
    $instances = @($instances | Where-Object { $_.ModsFolder })
    if ($instances.Count -eq 0) {
        $last = Request-ModsFolder "No mods folder could be resolved."
        if ($last) { $instances = @(New-OfflineInstance $last "Manual entry") }
    }
}
if ($instances.Count -eq 0) {
    Write-Fail "Nothing to scan. Make sure Minecraft is running, or pick option [2] and enter the mods folder."
    Wait-Key; exit 1
}
$groups = @($instances | Group-Object -Property ModsFolder)
Write-Ok "Detected $($instances.Count) process(es) across $($groups.Count) instance folder(s)"
foreach ($g in $groups) {
    Write-Host "    $gTri " -NoNewline -ForegroundColor Green
    Write-Host $g.Name -ForegroundColor White
    foreach ($i in $g.Group) {
        $up = "n/a"; if ($i.StartTime) { $ts = (Get-Date) - $i.StartTime; $up = "$($ts.Hours)h $($ts.Minutes)m $($ts.Seconds)s" }
        $cmdHint = if ($i.CmdSource) { "cmd:$($i.CmdSource)" } elseif ($i.CommandLine) { "cmd:yes" } else { "cmd:none" }
        Write-Dim "$($i.ProcessName)  PID $($i.ProcessId)  Player: $($i.Player)  Uptime: $up" 6
    }
}

function Get-ConfiguredJvmArgs([string]$modsFolder) {
    $parts = New-Object System.Collections.Generic.List[string]
    $dir = $modsFolder
    for ($i = 0; $i -lt 3 -and $dir; $i++) {
        $dir = Split-Path -Parent $dir
        if (-not $dir) { break }
        foreach ($cfg in @('instance.cfg')) {
            $fp = Join-Path $dir $cfg
            if (Test-Path -LiteralPath $fp -PathType Leaf -ErrorAction SilentlyContinue) {
                try { foreach ($line in (Get-Content -LiteralPath $fp -ErrorAction Stop)) { if ($line -match '^JvmArgs=(.+)$') { $parts.Add($matches[1]) } } } catch {}
            }
        }
        $lp = Join-Path $dir 'launcher_profiles.json'
        if (Test-Path -LiteralPath $lp -PathType Leaf -ErrorAction SilentlyContinue) {
            try { foreach ($m in [regex]::Matches((Get-Content -LiteralPath $lp -Raw -ErrorAction Stop), '"javaArgs"\s*:\s*"([^"]*)"')) { $parts.Add($m.Groups[1].Value) } } catch {}
        }
    }
    return ($parts -join ' ').Trim()
}
function Invoke-JvmArgScan($Inst, [string]$Override = '') {
    $out = New-Object System.Collections.Generic.List[object]
    $cmd = if ($Override) { $Override } else { $Inst.CommandLine }
    if (-not $cmd) { return $null }
    if ($cmd -match '^"([^"]+)"') { $cmd = $cmd.Substring($matches[1].Length + 2).Trim() }
    foreach ($rule in $jvmRules) {
        foreach ($m in [regex]::Matches($cmd, $rule.Rx)) {
            $v = $m.Value
            $out.Add([PSCustomObject]@{ Category = $rule.Cat; Arg = $v })
        }
    }
    foreach ($m in [regex]::Matches($cmd, '-javaagent:([^\s"]+)')) {
        $name = [System.IO.Path]::GetFileName($m.Groups[1].Value.Trim('"').Trim("'"))
        $legit = $false
        foreach ($la in $legitAgents) { if ($name -match $la) { $legit = $true; break } }
        if (-not $legit) { $out.Add([PSCustomObject]@{ Category = 'JVM agent'; Arg = $m.Value }) }
    }
    return $out
}
$jvmAll = @{}
Write-Section "JVM argument scan"
foreach ($g in $groups) {
    foreach ($inst in $g.Group) {
        if (-not $inst.ProcessId) { Write-Dim "Skipped (no running process for $($g.Name)) - JVM arguments can't be checked offline."; continue }

        $liveCmd = $inst.CommandLine
        $cmdSource = $null
        if ($liveCmd) { $cmdSource = 'instance' }

        if (-not $liveCmd) {
            try {
                $retry = [ProcessHelper]::GetCommandLine([int]$inst.ProcessId)
                if ($retry) { $liveCmd = $retry; $cmdSource = 'native PEB' }
            } catch {}
        }
        if (-not $liveCmd) {
            $wmiCmd = Get-WmiCommandLineByName ([int]$inst.ProcessId)
            if ($wmiCmd) { $liveCmd = $wmiCmd; $cmdSource = 'WMI (by Name)' }
        }
        if (-not $liveCmd) {
            try {
                $ci = Get-CimInstance Win32_Process -Filter "ProcessId = $($inst.ProcessId)" -ErrorAction Stop
                if ($ci -and -not [string]::IsNullOrWhiteSpace($ci.CommandLine)) {
                    $liveCmd = [string]$ci.CommandLine; $cmdSource = 'WMI/CIM (by PID)'
                }
            } catch {}
        }
        if (-not $liveCmd) {
            try {
                $w = Get-WmiObject Win32_Process -Filter "ProcessId = $($inst.ProcessId)" -ErrorAction Stop
                if ($w -and -not [string]::IsNullOrWhiteSpace($w.CommandLine)) {
                    $liveCmd = [string]$w.CommandLine; $cmdSource = 'WMI (by PID)'
                }
            } catch {}
        }

        $f = $null
        if ($liveCmd) {
            $inst.CommandLine = $liveCmd
            $f = Invoke-JvmArgScan $inst $liveCmd
            if ($null -eq $f) { $f = @() }
            if ($cmdSource -and $cmdSource -ne 'instance') {
                Write-Dim "PID $($inst.ProcessId): command line via $cmdSource" 4
            }
        } else {
            Write-Warn "PID $($inst.ProcessId): could not read a usable live command line."
            $why = ""
            try { $null = [ProcessHelper]::GetCommandLine([int]$inst.ProcessId); $why = [ProcessHelper]::Diag } catch { $why = "exception: $($_.Exception.Message)" }
            if (-not $why) { $why = "(no detail recorded)" }
            Write-Dim "Native: $why" 4
            Write-Dim "WMI/CIM CommandLine was empty for this PID (re-run as Admin if the process belongs to another user)." 4

            $extra = @()
            if ($why -match 'EMPTY') {
                $extra += [PSCustomObject]@{ Category = 'Command line blanked'; Arg = 'java process has an EMPTY command line - it was cleared or spoofed, JVM args cannot be verified' }
            }
            $cfgArgs = Get-ConfiguredJvmArgs $g.Name
            $f = @()
            if ($cfgArgs) {
                Write-Dim "Checking the JVM args configured for this instance instead (not the live process)." 4
                $scanned = Invoke-JvmArgScan $inst $cfgArgs
                if ($null -ne $scanned) { $f = @($scanned) }
            }
            $f = @($f) + @($extra)
            if ($f.Count -eq 0 -and -not $cfgArgs) {
                Write-Dim "No configured JVM args found either - JVM argument check skipped." 4
                continue
            }
        }

        $f = @($f | Sort-Object Category, Arg -Unique)
        $jvmAll[[string]$inst.ProcessId] = $f
        if ($f.Count -eq 0) {
            Write-Ok "PID $($inst.ProcessId): Clean"
        } else {
            Write-Note "PID $($inst.ProcessId): $($f.Count) suspicious JVM argument(s)"
            $groupsOut = @()
            foreach ($cat in ($f | Group-Object Category)) {
                $groupsOut += @{ Head = $cat.Name; Items = @($cat.Group | ForEach-Object { $_.Arg }); Color = 'Magenta' }
            }
            Write-Card 'JVM' 'DarkMagenta' "PID $($inst.ProcessId)" $groupsOut
        }
    }
}

$script:ProjCache = @{}; $script:GuessCache = @{}; $script:HashHits = @{}
function Invoke-Mr([string]$uri) { return Invoke-RestMethod -Uri $uri -UseBasicParsing -TimeoutSec 20 -Headers @{ 'User-Agent' = 'p1ae-mod-analyzer/1.0' } }
function Get-MrProject([string]$id) {
    if ($script:ProjCache.ContainsKey($id)) { return $script:ProjCache[$id] }
    $p = $null
    try { $p = Invoke-Mr "https://api.modrinth.com/v2/project/$id" } catch {}
    $script:ProjCache[$id] = $p
    if ($p) { if ($p.id) { $script:ProjCache[[string]$p.id] = $p }; if ($p.slug) { $script:ProjCache[[string]$p.slug] = $p } }
    return $p
}
function Invoke-BulkHashLookup($hashes) {
    $pending = @($hashes | Where-Object { $_ } | Select-Object -Unique)
    if ($pending.Count -eq 0) { return }
    try {
        for ($o = 0; $o -lt $pending.Count; $o += 400) {
            $chunk = @($pending[$o..([math]::Min($o + 399, $pending.Count - 1))])
            $body = @{ hashes = $chunk; algorithm = "sha1" } | ConvertTo-Json
            $raw = Invoke-RestMethod -Uri "https://api.modrinth.com/v2/version_files" -Method POST -ContentType "application/json" -Body $body -UseBasicParsing -TimeoutSec 30 -Headers @{ 'User-Agent' = 'p1ae-mod-analyzer/1.0' }
            $byHash = @{}; $ids = New-Object System.Collections.Generic.HashSet[string]
            foreach ($prop in $raw.PSObject.Properties) { $byHash[$prop.Name] = $prop.Value; if ($prop.Value.project_id) { [void]$ids.Add([string]$prop.Value.project_id) } }
            if ($ids.Count -gt 0) {
                try {
                    $idsJson = '[' + ((@($ids) | ForEach-Object { '"' + $_ + '"' }) -join ',') + ']'
                    $projects = Invoke-Mr ("https://api.modrinth.com/v2/projects?ids=" + [uri]::EscapeDataString($idsJson))
                    foreach ($p in $projects) { if ($p.id) { $script:ProjCache[[string]$p.id] = $p }; if ($p.slug) { $script:ProjCache[[string]$p.slug] = $p } }
                } catch {}
            }
            foreach ($h in $byHash.Keys) {
                $v = $byHash[$h]; $proj = Get-MrProject ([string]$v.project_id)
                if ($proj) { $script:HashHits[$h] = @{ Name = $proj.title; Slug = $proj.slug; Version = $v.version_number; Size = $v.files[0].size; Downloads = $proj.downloads; Url = "https://modrinth.com/mod/$($proj.slug)/version/$($v.id)" } }
            }
        }
    } catch { Write-Warn "Bulk hash lookup failed ($($_.Exception.Message)) - continuing with name-based lookups." }
}
function Find-ModrinthGuess([string]$FileName, [string]$ModId, [string]$LocalVer, [long]$ActualSize, [string]$McVer) {
    $key = "g:$FileName|$ModId|$ActualSize"
    if ($script:GuessCache.ContainsKey($key)) { return $script:GuessCache[$key] }
    $clean = $FileName -replace '(\.temp|\.tmp|_1)?\.jar$', '.jar'
    $base = [System.IO.Path]::GetFileNameWithoutExtension($clean)
    $ver = $LocalVer; $baseName = $base
    if ($base -match '^(.*?)[-_+]v?(\d[\w.+\-]*)$') { $baseName = $matches[1]; if (-not $ver) { $ver = $matches[2] } }
    $baseName = $baseName -replace '(?i)[-_](fabric|forge|neoforge|quilt)$', ''
    $cands = @($ModId, $baseName.ToLower(), $base.ToLower()) | Where-Object { $_ } | Select-Object -Unique
    $result = $null
    foreach ($slug in $cands) {
        $proj = Get-MrProject $slug
        if (-not $proj) { continue }
        try {
            $vers = @(Invoke-Mr "https://api.modrinth.com/v2/project/$($proj.id)/version")
            $exact = @()
            foreach ($v in $vers) {
                foreach ($file in $v.files) {
                    if ($file.filename -eq $clean -or $file.filename -eq $FileName -or ($ver -and $v.version_number -eq $ver -and $file.primary)) {
                        $exact += [PSCustomObject]@{ V = $v; F = $file }
                    }
                }
            }
            if ($exact.Count -gt 0) {
                $pick = $exact | Where-Object { $_.F.size -eq $ActualSize } | Select-Object -First 1
                if (-not $pick -and $McVer) { $pick = $exact | Where-Object { $_.V.game_versions -contains $McVer } | Select-Object -First 1 }
                if (-not $pick) { $pick = $exact | Select-Object -First 1 }
                $result = @{ Name = $proj.title; Slug = $proj.slug; Exact = $true; Downloads = $proj.downloads; Size = $pick.F.size; Version = $pick.V.version_number; Url = "https://modrinth.com/mod/$($proj.slug)/version/$($pick.V.id)" }
            } else {
                $result = @{ Name = $proj.title; Slug = $proj.slug; Exact = $false; Downloads = $proj.downloads; Size = 0; Version = ""; Url = "https://modrinth.com/mod/$($proj.slug)" }
            }
            break
        } catch { continue }
    }
    $script:GuessCache[$key] = $result
    return $result
}
function Get-SourceName([string]$url) {
    switch -regex ($url) {
        "modrinth\.com" { return "Modrinth" }
        "curseforge\.com" { return "CurseForge" }
        "github\.com" { return "GitHub" }
        "discord(app)?\.(com|net)" { return "Discord" }
        "mediafire\.com" { return "MediaFire" }
        "dropbox\.com" { return "Dropbox" }
        "drive\.google\.com" { return "Google Drive" }
        "mega\.(nz|co\.nz)" { return "MEGA" }
        "anydesk\.com" { return "AnyDesk" }
        "doomsdayclient\.com" { return "DoomsdayClient" }
        "prestigeclient\.vip" { return "PrestigeClient" }
        "198macros\.com" { return "198Macros" }
        "dqrkis\.xyz" { return "Dqrkis" }
        default { if ($url -match 'https?://(?:www\.)?([^/]+)') { return $matches[1] } else { return $url } }
    }
}
function Get-ZoneInfo([string]$p) {
    $r = @{ Source = 'Unknown'; Url = '' }
    try {
        $raw = Get-Content -LiteralPath $p -Raw -Stream Zone.Identifier -ErrorAction Stop
        $h = ''; $ref = ''
        if ($raw -match 'HostUrl=(.+)') { $h = $matches[1].Trim() }
        if ($raw -match 'ReferrerUrl=(.+)') { $ref = $matches[1].Trim() }
        $u = if ($h) { $h } else { $ref }
        if ($u) { $r.Url = $u; $r.Source = Get-SourceName $u }
    } catch {}
    return $r
}
function Resolve-Fullwidth($runs) {
    $r = [P1ScanV2]::ResolveFullwidth([string[]]@($runs), $script:StrongKeyArr, $script:StrongValArr, $script:FwKeyArr, $script:FwValArr)
    return @{ Resolved = @($r[0]); Unknown = @($r[1]) }
}
function Get-McVersion($Inst) {
    if ($Inst -and $Inst.CommandLine) {
        $c = $Inst.CommandLine
        if ($c -match '-Dfabric\.gameVersion=(\d+\.\d+(?:\.\d+)?)') { return $matches[1] }
        if ($c -match '--version\s+\S*?(\d+\.\d+(?:\.\d+)?)(?=\s|$)') { return $matches[1] }
        if ($c -match 'versions[/\\](\d+\.\d+(?:\.\d+)?)[/\\]') { return $matches[1] }
    }
    return $null
}

function Invoke-ModScan([string]$ModsFolder, $Inst) {
    $mcVer = Get-McVersion $Inst
    if ($mcVer) { Write-Info "Minecraft version: $mcVer (used to pick matching Modrinth releases)" }

    $jars = @(Get-ChildItem -LiteralPath $ModsFolder -Filter *.jar -File -Force -ErrorAction SilentlyContinue)
    $odd  = @(Get-ChildItem -LiteralPath $ModsFolder -File -Force -ErrorAction SilentlyContinue | Where-Object {
                $_.Extension -ne '.jar' -and $_.Extension -ne '.disabled' -and $_.Length -gt 1KB -and [P1ScanV2]::HasZipMagic($_.FullName) })
    $oddNames = @{}; foreach ($o in $odd) { $oddNames[$o.FullName] = $true }
    $targets = @($jars) + @($odd)
    if ($targets.Count -eq 0) {
        Write-Warn "No .jar files in this mods folder."
        $script:ModScanResults = @()
        return
    }
    if ($odd.Count -gt 0) { Write-Note "$($odd.Count) archive(s) with a non-.jar extension found in the mods folder - scanning them too" }

    $threads = [math]::Max(1, [math]::Min([Environment]::ProcessorCount, 6))
    Write-Info "Hashing + deep scanning $($targets.Count) file(s) on $threads thread(s)..."
    $job = [P1ScanV2]::StartScan([string[]]@($targets | ForEach-Object { $_.FullName }), $threads)
    $spin = @("|","/","-","\"); $tick = 0
    while (-not $job.Task.IsCompleted) {
        Write-Host ("`r  [{0}] {1}/{2} scanned" -f $spin[$tick % 4], $job.Done, $targets.Count) -NoNewline -ForegroundColor Yellow
        $tick++; Start-Sleep -Milliseconds 100
    }
    try { $job.Task.Wait() } catch {}
    Write-Host ("`r" + (' ' * 78) + "`r") -NoNewline

    $hashes = @{}
    for ($hi = 0; $hi -lt $targets.Count; $hi++) { $hashes[$targets[$hi].FullName] = $job.Hashes[$hi] }

    Invoke-BulkHashLookup @($hashes.Values)
    Write-Ok "$($script:HashHits.Count) exact-hash match(es) on Modrinth"

    Write-Info "Analyzing results..."
    $results = New-Object System.Collections.Generic.List[object]
    for ($i = 0; $i -lt $targets.Count; $i++) {
        $f = $targets[$i]
        $nm = if ($f.Name.Length -gt 38) { $f.Name.Substring(0, 35) + "..." } else { $f.Name }
        Write-Host ("`r  [{0}] {1}/{2}  {3}" -f $spin[$i % 4], ($i + 1), $targets.Count, $nm.PadRight(40)) -NoNewline -ForegroundColor Yellow

        try {
        $hash = $hashes[$f.FullName]
        $jr = $job.Results[$i]
        if ($null -eq $jr) { throw "scanner failed: $($job.Errors[$i])" }
        $zone = Get-ZoneInfo $f.FullName

        $vtype = 'None'; $modName = ''; $slug = ''; $expected = 0; $url = ''; $hint = ''; $dl = $null
        $tamper = New-Object System.Collections.Generic.List[string]
        if ($hash -and $script:HashHits.ContainsKey($hash)) {
            $h = $script:HashHits[$hash]; $vtype = 'Hash'; $modName = $h.Name; $slug = $h.Slug; $url = $h.Url; $expected = $h.Size; $dl = $h.Downloads
        } else {
            $gs = Find-ModrinthGuess $f.Name $jr.ModId $jr.Version $f.Length $mcVer
            if ($gs) {
                $modName = $gs.Name; $slug = $gs.Slug; $url = $gs.Url
                if ($gs.Exact) {
                    $expected = $gs.Size
                    if ([math]::Abs($f.Length - $gs.Size) -le 512) { $vtype = 'Name'; $dl = $gs.Downloads }
                    else {
                        $d = [math]::Round(($f.Length - $gs.Size) / 1KB, 2)
                        $sign = if ($d -gt 0) { "+" } else { "" }
                        $tamper.Add("File differs from the Modrinth release $($gs.Version) of '$($gs.Name)' ($sign$d KB, expected $([math]::Round($gs.Size/1KB,2)) KB) - hash does not match")
                    }
                } else { $hint = "Name resembles Modrinth project '$($gs.Name)' but no matching release/hash was found" }
            }
        }
        $exempt = ($vtype -eq 'Hash')

        $strings = New-Object System.Collections.Generic.List[string]
        foreach ($s in $jr.Strings) { [void]$strings.Add($s) }
        $fw = Resolve-Fullwidth $jr.FwRuns
        foreach ($r in $fw.Resolved) { if (-not $strings.Contains($r)) { [void]$strings.Add($r) } }
        $patterns = @($jr.PatternHits | Sort-Object -Unique)
        $fwUnknown = @($fw.Unknown)
        $notes = New-Object System.Collections.Generic.List[string]

        $ffKey = $null
        if ($slug -and $falseFlagSlugs.ContainsKey($slug.ToLower())) { $ffKey = $slug.ToLower() }
        elseif ($modName -and $falseFlagSlugs.ContainsKey(($modName -replace '[^a-zA-Z0-9]','').ToLower())) { $ffKey = ($modName -replace '[^a-zA-Z0-9]','').ToLower() }
        $isFalseFlag = $false
        if ($exempt -and $ffKey -and ($strings.Count + $patterns.Count + $fwUnknown.Count) -gt 0) {
            if ($falseFlagSlugs[$ffKey]) { $notes.Add("Known false-flag: " + $falseFlagSlugs[$ffKey] + " (hash verified)") }
            $isFalseFlag = $true
        }
        if ($exempt -and $jr.ModId -eq 'marlowcrystal' -and $strings.Contains('EndCrystalItemMixin')) {
            $notes.Add("Marlow's Crystal Optimizer has its own EndCrystalItemMixin - may be a false flag, decompile to confirm")
        }

        $tc = [double]$jr.Classes
        $obfReasons = New-Object System.Collections.Generic.List[string]
        $pf = if ($tc -ge 5) { 100.0 / $tc } else { 0.0 }
        if (-not $exempt) {
            $s1 = [math]::Round($jr.Single1 * $pf); $s2 = [math]::Round($jr.Two * $pf); $np = [math]::Round($jr.Numeric * $pf); $up = [math]::Round($jr.Unicode * $pf)
            $nv = [math]::Round($jr.NoVowel * $pf); $gp = [math]::Round($jr.Gibberish * $pf); $cf = [math]::Round($jr.Confusion * $pf)
            $op = if ($tc -ge 10) { [math]::Round($jr.ObfPath / $tc * 100) } else { 0 }
            if ($s1 -ge 15) { $obfReasons.Add("Single-letter class names ($s1%)") }
            if ($s2 -ge 20) { $obfReasons.Add("Two-letter class names ($s2%)") }
            if ($np -ge 20) { $obfReasons.Add("Numeric class names ($np%)") }
            if ($up -ge 10) { $obfReasons.Add("Unicode class names ($up%)") }
            if ($nv -ge 8)  { $obfReasons.Add("No-vowel class names ($nv%)") }
            if ($gp -ge 10 -and $tc -ge 50) { $obfReasons.Add("Gibberish class names ($gp%)") }
            if ($cf -ge 3)  { $obfReasons.Add("Confusion-char class names Il1O0/_ ($cf%)") }
            if ($jr.SinglePkg -ge 50 -and $tc -ge 10) { $obfReasons.Add("Single-char package paths ($($jr.SinglePkg) segments)") }
            if ($op -ge 25) { $obfReasons.Add("Obfuscated package structure ($op% of classes in a/b/c paths)") }
            if ($tc -ge 5 -and $jr.Fullwidth -gt 0) { $obfReasons.Add("Fullwidth unicode class names ($($jr.Fullwidth) classes)") }
            if ($tc -ge 5 -and $jr.Japanese -ge 3) { $obfReasons.Add("Japanese kana class names ($($jr.Japanese) classes)") }
            if ($jr.Obfuscators.Count -gt 0) { $tamper.Add("Known obfuscator signature: $($jr.Obfuscators -join ', ')") }
        }

        $bypass = New-Object System.Collections.Generic.List[string]
        if (-not $exempt) {
            $op2 = if ($tc -ge 10) { [math]::Round($jr.ObfPath / $tc * 100) } else { 0 }
            foreach ($nj in $jr.NestedJars) {
                $b = [System.IO.Path]::GetFileNameWithoutExtension($nj)
                $sus = $true
                if ($b -match '\d') { $sus = $false }
                foreach ($pfx in $mavenPrefixes) { if ($b.ToLower().StartsWith($pfx)) { $sus = $false } }
                if ($b.Length -gt 20) { $sus = $false }
                if ($sus) { $bypass.Add("Suspicious nested JAR - no version, unknown dependency: $nj") }
            }
            if ($jr.NestedJars.Count -eq 1 -and $jr.OwnClasses -lt 3) { $bypass.Add("Hollow shell - only $($jr.OwnClasses) own class(es), wraps: $($jr.NestedJars[0])") }
            if ($jr.Exec -and $op2 -ge 25) { $bypass.Add("Runtime.exec() in obfuscated code - can run arbitrary OS commands") }
            if ($jr.Download) { $bypass.Add("HTTP file download - fetches and writes files from a remote server at runtime") }
            if ($jr.Exfil)    { $bypass.Add("HTTP POST exfiltration - sends system data to an external server") }
            if ($jr.Robot)    { $bypass.Add("Java Robot (java.awt.Robot) - can simulate mouse/keyboard input and capture the screen; used by auto-clickers and input macros") }
            foreach ($lh in $jr.LoaderHits) { $bypass.Add("Custom class loading - $lh") }
            if ($jr.ModId -and ($knownLegitModIds -contains $jr.ModId) -and $bypass.Count -gt 0) { $bypass.Add("Fake mod identity - claims to be '$($jr.ModId)' but contains dangerous code") }
        }
        if ($jr.Malformed) {
            $bypass.Add("Malformed archive - central directory unreadable ($($jr.Error)); possible scanner evasion, scanned via local headers only")
        }
        if ($oddNames.ContainsKey($f.FullName)) {
            $bypass.Add("Archive hidden behind a '$($f.Extension)' extension inside the mods folder")
        }
        $attrHidden = @()
        if ($f.Attributes -band [System.IO.FileAttributes]::Hidden) { $attrHidden += 'Hidden' }
        if ($f.Attributes -band [System.IO.FileAttributes]::System) { $attrHidden += 'System' }
        if ($attrHidden.Count -gt 0) {
            $bypass.Add("Hidden file attribute enabled ($($attrHidden -join '+')) - mod is concealed from Explorer and normal directory listings; scanned anyway")
        }

        $disallowed = $null
        $fnL = $f.Name.ToLower(); $jid = $jr.ModId.ToLower(); $jnm = $jr.Name.ToLower()
        foreach ($slugD in $disallowedMods.Keys) {
            $sl = $slugD.ToLower(); $sn = $sl -replace '-', ''
            $hit = $false
            foreach ($name in $disallowedMods[$slugD]) {
                $nl = $name.ToLower(); $ns = ($name -replace ' ', '').ToLower()
                if ($fnL.Contains($nl) -or $fnL.Contains($ns) -or $fnL.Contains($sl) -or $fnL.Contains($sn)) { $hit = $true; break }
                if ($jid -and ($jid.Contains($ns) -or $jid.Contains($sn) -or $jid.Contains($sl))) { $hit = $true; break }
                if ($jnm -and ($jnm.Contains($nl) -or $jnm.Contains($ns) -or $jnm.Contains($sl))) { $hit = $true; break }
            }
            if ($hit) { $disallowed = $disallowedMods[$slugD][0]; break }
        }

        if ($Inst -and $Inst.StartTime -and $f.LastWriteTime -gt $Inst.StartTime) { $notes.Add("Modified/added AFTER the game launched ($($f.LastWriteTime))") }

        $results.Add([PSCustomObject]@{
            File=$f.Name; Path=$f.FullName; Hash=$hash; SizeKB=[math]::Round($f.Length/1KB, 2); ExpectedKB=[math]::Round($expected/1KB, 2)
            VType=$vtype; ModName=$modName; Slug=$slug; Url=$url; Hint=$hint; Downloads=$dl; Source=$zone.Source; SourceUrl=$zone.Url
            JarId=$jr.ModId; JarName=$jr.Name; JarVer=$jr.Version; Loader=$jr.Loader; Classes=$jr.Classes
            Strings=@($strings | Sort-Object); Patterns=$patterns; FwUnknown=$fwUnknown; Tamper=@($tamper); ObfReasons=@($obfReasons)
            Bypass=@($bypass); Disallowed=$disallowed; Notes=@($notes); FalseFlag=$isFalseFlag
        })
        } catch {
            $errMsg = "$($_.Exception.Message) (script line $($_.InvocationInfo.ScriptLineNumber))"
            $script:ScanErrors += "$($f.Name): $errMsg"
            Write-Host ("`r" + (' ' * 78) + "`r") -NoNewline
            Write-Fail "Scan error on $($f.Name): $errMsg"
            $results.Add([PSCustomObject]@{
                File=$f.Name; Path=$f.FullName; Hash=$null; SizeKB=[math]::Round($f.Length/1KB, 2); ExpectedKB=0
                VType='None'; ModName=''; Slug=''; Url=''; Hint=''; Downloads=$null; Source='Unknown'; SourceUrl=''
                JarId=''; JarName=''; JarVer=''; Loader=''; Classes=0
                Strings=@(); Patterns=@(); FwUnknown=@(); Tamper=@(); ObfReasons=@()
                Bypass=@(); Disallowed=$null; Notes=@("SCAN ERROR - file was NOT fully analyzed: $errMsg"); FalseFlag=$false
            })
        }
    }
    Write-Host ("`r" + (' ' * 78) + "`r") -NoNewline
    $script:ModScanResults = $results.ToArray()
}

$allRuns = @(); $gi = 0
$script:ScanErrors = @(); $script:ModScanResults = @()
foreach ($g in $groups) {
    $gi++
    Write-Section "Mod scan $gi/$($groups.Count)"
    Write-Dim $g.Name
    $inst0 = $g.Group[0]
    foreach ($i in $g.Group) { if ($i.StartTime) { $inst0 = $i; break } }
    $script:HashHits = @{}
    $script:ModScanResults = @()
    try { $null = Invoke-ModScan $g.Name $inst0 } catch { $script:ScanErrors += "Scan aborted: $($_.Exception.Message) (script line $($_.InvocationInfo.ScriptLineNumber))"; Write-Fail "Scan aborted: $($_.Exception.Message) (script line $($_.InvocationInfo.ScriptLineNumber))" }
    $res = @($script:ModScanResults)
    $allRuns += [PSCustomObject]@{ Folder = $g.Name; Instances = @($g.Group); Mods = $res }

    if ($res.Count -eq 0) { continue }

    $cheat    = @($res | Where-Object { -not $_.FalseFlag -and ($_.Strings.Count -gt 0 -or $_.Patterns.Count -gt 0 -or $_.FwUnknown.Count -gt 0) })
    $bypass   = @($res | Where-Object { $_.Bypass.Count -gt 0 })
    $tampered = @($res | Where-Object { $_.Tamper.Count -gt 0 })
    $disal    = @($res | Where-Object { $_.Disallowed })
    $obf      = @($res | Where-Object { $_.ObfReasons.Count -gt 0 })
    $flaggedFiles = @{}
    foreach ($x in @($cheat) + @($bypass) + @($tampered) + @($disal) + @($obf)) { $flaggedFiles[$x.File] = $true }
    $unknown  = @($res | Where-Object { $_.VType -eq 'None' -and -not $flaggedFiles.ContainsKey($_.File) })
    $verified = @($res | Where-Object { $_.VType -ne 'None' -and -not $flaggedFiles.ContainsKey($_.File) })

    Write-Section "Results"

    if ($verified.Count -gt 0) { Write-Sub "Verified mods" $verified.Count 'Green' }
    foreach ($m in $verified) {
        Write-Host "    $gCheck " -NoNewline -ForegroundColor Green
        Write-Host $m.ModName -NoNewline -ForegroundColor White
        Write-Host "  $gArrow  $($m.File)" -NoNewline -ForegroundColor DarkGray
        if ($m.VType -eq 'Name') { Write-Host "  (name+size match)" -NoNewline -ForegroundColor DarkGray }
        Write-Host ""
        if ($null -ne $m.Downloads) {
            if ([int64]$m.Downloads -lt $script:MinDownloads) {
                Write-Host ("        " + $gWarn + " LOW DOWNLOADS: only {0:N0} on Modrinth (under {1:N0}) - verify this mod manually" -f [int64]$m.Downloads, $script:MinDownloads) -ForegroundColor Magenta
            }
        } else {
            Write-Dim "Download count unavailable - could not check the 2k+ downloads rule" 8
        }
        foreach ($n in $m.Notes) { Write-ResultNote $n 8 }
        if ($m.FalseFlag) {
            $ffGroups = @(
                @{ Head = 'Detected cheat strings';      Items = $m.Strings },
                @{ Head = 'Cheat class / package names'; Items = $m.Patterns },
                @{ Head = 'Unknown fullwidth strings';   Items = @($m.FwUnknown | ForEach-Object { "FULLWIDTH: $_" }) }
            )
            foreach ($fg in $ffGroups) {
                $its = @($fg.Items | Where-Object { $_ })
                if ($its.Count -eq 0) { continue }
                Write-Line $gDot 'Magenta' $fg.Head 'Magenta' 8
                foreach ($it in $its) { Write-Line $gBullet 'Magenta' $it 'Magenta' 10 }
            }
        }
    }

    if ($unknown.Count -gt 0) { Write-Sub "Unknown mods" $unknown.Count 'Yellow' }
    foreach ($m in $unknown) {
        Write-Host "    ? " -NoNewline -ForegroundColor Yellow
        Write-Host $m.File -NoNewline -ForegroundColor White
        Write-Host "   $($m.SizeKB) KB   source: $($m.Source)" -ForegroundColor DarkGray
        if ($m.Hint) { Write-Line $gDot 'Blue' $m.Hint 'Blue' 8 }
        foreach ($n in $m.Notes) { Write-ResultNote $n 8 }
    }

    if ($obf.Count -gt 0) { Write-Sub "Obfuscated mods" $obf.Count 'Yellow' }
    foreach ($m in $obf) { Write-Card 'OBFUSCATED' 'DarkYellow' $m.File @(@{ Head = 'Indicators'; Items = $m.ObfReasons; Color = 'Yellow' }) }

    if ($disal.Count -gt 0) { Write-Sub "Disallowed mods" $disal.Count 'Red' }
    foreach ($m in $disal) { Write-Card 'DISALLOWED' 'DarkRed' $m.File @(@{ Head = 'Matched rule'; Items = @($m.Disallowed); Color = 'Red' }, @{ Head = 'Notes'; Items = $m.Notes; Color = 'Cyan' }) }

    if ($tampered.Count -gt 0) { Write-Sub "Tampered mods" $tampered.Count 'Yellow' }
    foreach ($m in $tampered) {
        $t = $m.File; if ($m.ModName) { $t += "   [$($m.ModName)]" }
        Write-Card 'TAMPERED' 'DarkYellow' $t @(@{ Head = 'Detected issues'; Items = $m.Tamper; Color = 'Red' })
    }

    if ($bypass.Count -gt 0) { Write-Sub "Bypass / injection" $bypass.Count 'Magenta' }
    foreach ($m in $bypass) { Write-Card 'INJECTION' 'DarkMagenta' $m.File @(@{ Head = 'Findings'; Items = $m.Bypass; Color = 'White' }) }

    if ($cheat.Count -gt 0) { Write-Sub "Cheat mods" $cheat.Count 'Red' }
    foreach ($m in $cheat) {
        $grp = @(
            @{ Head = 'Detected cheat strings';      Items = $m.Strings;   Color = 'Magenta' },
            @{ Head = 'Cheat class / package names'; Items = $m.Patterns;  Color = 'Red' },
            @{ Head = 'Unknown fullwidth strings';   Items = ($m.FwUnknown | ForEach-Object { "FULLWIDTH: $_" }); Color = 'Cyan' },
            @{ Head = 'Notes';                       Items = $m.Notes;     Color = 'DarkYellow' }
        )
        $title = $m.File; if ($m.ModName) { $title += "   [$($m.ModName)]" }
        Write-Card 'CHEAT' 'DarkRed' $title $grp
        Write-Host ("  " + $gV + "  ") -NoNewline -ForegroundColor DarkRed
        Write-Host ("size $($m.SizeKB) KB   source $($m.Source)" + $(if ($m.VType -ne 'None') { "   verified:$($m.VType)" } else { "" })) -ForegroundColor DarkGray
    }

    $stats = [PSCustomObject]@{ Cheat=$cheat.Count; Bypass=$bypass.Count; Tampered=$tampered.Count; Disallowed=$disal.Count; Obf=$obf.Count; Unknown=$unknown.Count; Verified=$verified.Count }
    $allRuns[-1] | Add-Member -NotePropertyName Stats -NotePropertyValue $stats
}

Write-Section "Summary"

$totalCheat = 0; $totalBypass = 0; $totalTamper = 0; $totalDis = 0; $totalJvm = 0
foreach ($run in $allRuns) {
    $s = $run.Stats
    $players = ($run.Instances | ForEach-Object { "$($_.Player) (PID $($_.ProcessId))" }) -join ", "
    if ($s) {
        $totalCheat += $s.Cheat; $totalBypass += $s.Bypass; $totalTamper += $s.Tampered; $totalDis += $s.Disallowed
        $col = if ($s.Cheat -gt 0 -or $s.Disallowed -gt 0 -or $s.Bypass -gt 0) { 'Red' } elseif ($s.Tampered -gt 0 -or $s.Obf -gt 0 -or $s.Unknown -gt 0) { 'Yellow' } else { 'Green' }
        $lines = @(
            "Players      $players",
            "Mods folder  $($run.Folder)",
            "",
            ("Verified     {0}" -f $s.Verified),
            ("Unknown      {0}" -f $s.Unknown),
            ("Obfuscated   {0}" -f $s.Obf),
            ("Tampered     {0}" -f $s.Tampered),
            ("Bypass       {0}" -f $s.Bypass),
            ("Cheat        {0}" -f $s.Cheat),
            ("Disallowed   {0}" -f $s.Disallowed)
        )
        Write-Host ""
        Write-Box $lines $col @('White','DarkGray','White','Green','Yellow','Yellow','Yellow','Magenta','Red','Red')
    }
}
foreach ($k in $jvmAll.Keys) { $totalJvm += @($jvmAll[$k]).Count }
exit
