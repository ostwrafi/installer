# DLL path Change Koro
$dllPath = "C:\Windows\twain_32.dll"


function Get-ProcessIdByName {
    param ([string]$processName)
    
    $process = Get-Process -Name $processName -ErrorAction SilentlyContinue
    if ($process) {
        return $process.Id
    } else {
        return $null
    }
}

# P/Invoke signatures
Add-Type @"
using System;
using System.Runtime.InteropServices;

public class Win32 {
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr OpenProcess(uint processAccess, bool bInheritHandle, int processId);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr VirtualAllocEx(IntPtr hProcess, IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);

    [DllImport("kernel32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool WriteProcessMemory(IntPtr hProcess, IntPtr lpBaseAddress, byte[] lpBuffer, uint nSize, out IntPtr lpNumberOfBytesWritten);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr CreateRemoteThread(IntPtr hProcess, IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, out IntPtr lpThreadId);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr GetModuleHandle(string lpModuleName);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr GetProcAddress(IntPtr hModule, string lpProcName);
}
"@

# Constants for memory allocation and process access
$PROCESS_ALL_ACCESS = 0x001F0FFF
$MEM_COMMIT = 0x1000
$MEM_RESERVE = 0x2000
$PAGE_READWRITE = 0x04

# Monitor for the BlueStacks HD Player process
$processName = "HD-Player"

while ($true) {
    $processId = Get-ProcessIdByName -processName $processName

    if ($processId -ne $null) {
        Write-Output "BlueStacks HD Player process found with PID $processId. Attempting DLL injection..."

        # Open the target process
        $hProcess = [Win32]::OpenProcess($PROCESS_ALL_ACCESS, $false, $processId)
        if ($hProcess -eq [IntPtr]::Zero) {
            Write-Output "Failed to open process."
            Start-Sleep -Seconds 5
            continue
        }

        # Allocate memory in the target process
        $allocMem = [Win32]::VirtualAllocEx($hProcess, [IntPtr]::Zero, [uint32][System.Text.Encoding]::ASCII.GetByteCount($dllPath), $MEM_COMMIT -bor $MEM_RESERVE, $PAGE_READWRITE)
        if ($allocMem -eq [IntPtr]::Zero) {
            Write-Output "Failed to allocate memory."
            Start-Sleep -Seconds 5
            continue
        }

        # Write the DLL path to the allocated memory
        $bytes = [System.Text.Encoding]::ASCII.GetBytes($dllPath)
        $outSize = [IntPtr]::Zero
        $writeResult = [Win32]::WriteProcessMemory($hProcess, $allocMem, $bytes, [uint32]$bytes.Length, [ref]$outSize)
        if (-not $writeResult) {
            Write-Output "Failed to write memory."
            Start-Sleep -Seconds 5
            continue
        }

        # Get the address of LoadLibraryA
        $hKernel32 = [Win32]::GetModuleHandle("kernel32.dll")
        $loadLibraryAddr = [Win32]::GetProcAddress($hKernel32, "LoadLibraryA")
        if ($loadLibraryAddr -eq [IntPtr]::Zero) {
            Write-Output "Failed to get LoadLibrary address."
            Start-Sleep -Seconds 5
            continue
        }

        # Create a remote thread to load the DLL
        $threadId = [IntPtr]::Zero
        $hThread = [Win32]::CreateRemoteThread($hProcess, [IntPtr]::Zero, 0, $loadLibraryAddr, $allocMem, 0, [ref]$threadId)
        if ($hThread -eq [IntPtr]::Zero) {
            Write-Output "Failed to create remote thread."
            Start-Sleep -Seconds 5
            continue
        }

        Write-Output "DLL injection successful."
    }

    # Wait for a short period before checking again
    Start-Sleep -Seconds 5
}
