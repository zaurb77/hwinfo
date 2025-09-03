# =========================
# Hardware Inventory Menu (CIM-based)
# Works in PowerShell 7+ and Windows PowerShell 5.1
# Output: TXT file with clean sections
# =========================

# --- Config / Helpers ---
$defaultOutFile = Join-Path $env:USERPROFILE "Desktop\hardware_info.txt"

function New-Report {
    param([string]$Path)
    New-Item -Path $Path -ItemType File -Force | Out-Null
    Add-Content -Path $Path -Value ("#" * 70)
    Add-Content -Path $Path -Value ("Hardware Inventory Report - " + (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"))
    Add-Content -Path $Path -Value ("Hostname: $env:COMPUTERNAME")
    Add-Content -Path $Path -Value ("User: $env:USERNAME")
    Add-Content -Path $Path -Value ("#" * 70 + "`r`n")
}

function Write-Section {
    param([string]$Path, [string]$Title)
    Add-Content -Path $Path -Value ""
    Add-Content -Path $Path -Value ("=" * 70)
    Add-Content -Path $Path -Value ("[ " + $Title + " ]")
    Add-Content -Path $Path -Value ("=" * 70)
}

function Append-Query {
    param(
        [string]$Path,
        [string]$Title,
        [scriptblock]$Block
    )
    try {
        Write-Section -Path $Path -Title $Title
        $data = & $Block | Out-String
        if ([string]::IsNullOrWhiteSpace($data)) {
            Add-Content -Path $Path -Value "(No data returned)"
        } else {
            Add-Content -Path $Path -Value $data
        }
    } catch {
        Add-Content -Path $Path -Value "Error collecting [$Title]: $($_.Exception.Message)"
    }
}

# --- Data Blocks (CIM queries) ---

$Blocks = @{
    "1" = @{
        Name  = "CPU"
        Block = {
            Get-CimInstance Win32_Processor |
                Select-Object Name, Manufacturer, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed, SocketDesignation, ProcessorId |
                Format-List
        }
    }
    "2" = @{
        Name  = "Physical Memory (RAM Modules)"
        Block = {
            Get-CimInstance Win32_PhysicalMemory |
                Select-Object BankLabel, DeviceLocator, Capacity, Speed, Manufacturer, PartNumber, SerialNumber |
                ForEach-Object {
                    $_ | Select-Object BankLabel, DeviceLocator,
                        @{n="Capacity(GB)";e={[math]::Round($_.Capacity/1GB,2)}},
                        Speed, Manufacturer, PartNumber, SerialNumber
                } | Format-Table -AutoSize
        }
    }
    "3" = @{
        Name  = "Disk Drives (Physical)"
        Block = {
            Get-CimInstance Win32_DiskDrive |
                Select-Object Model, MediaType, InterfaceType, SerialNumber, FirmwareRevision,
                              @{n="Size(GB)";e={[math]::Round($_.Size/1GB,2)}},
                              Status |
                Format-Table -AutoSize
        }
    }
    "4" = @{
        Name  = "Logical Disks (Volumes)"
        Block = {
            Get-CimInstance Win32_LogicalDisk |
                Select-Object DeviceID, VolumeName, FileSystem,
                              @{n="Size(GB)";e={[math]::Round($_.Size/1GB,2)}},
                              @{n="Free(GB)";e={[math]::Round($_.FreeSpace/1GB,2)}},
                              @{n="Free(%)";e={ if($_.Size){ [math]::Round(100*($_.FreeSpace/$_.Size),1)} else { $null } }},
                              DriveType |
                Format-Table -AutoSize
        }
    }
    "5" = @{
        Name  = "GPU (Video Controllers)"
        Block = {
            Get-CimInstance Win32_VideoController |
                Select-Object Name, DriverVersion, DriverDate, AdapterCompatibility,
                              @{n="AdapterRAM(GB)";e={ if($_.AdapterRAM){ [math]::Round($_.AdapterRAM/1GB,2)} else { $null } }},
                              VideoProcessor, Status |
                Format-Table -AutoSize
        }
    }
    "6" = @{
        Name  = "Motherboard (BaseBoard)"
        Block = {
            Get-CimInstance Win32_BaseBoard |
                Select-Object Manufacturer, Product, Version, SerialNumber |
                Format-Table -AutoSize
        }
    }
    "7" = @{
        Name  = "BIOS / UEFI"
        Block = {
            Get-CimInstance Win32_BIOS |
                Select-Object Manufacturer, SMBIOSBIOSVersion, ReleaseDate, SerialNumber, Version |
                Format-List
        }
    }
    "8" = @{
        Name  = "Computer System"
        Block = {
            Get-CimInstance Win32_ComputerSystem |
                Select-Object Manufacturer, Model, SystemType, TotalPhysicalMemory, Domain, Username |
                ForEach-Object {
                    $_ | Select-Object Manufacturer, Model, SystemType,
                        @{n="TotalPhysicalMemory(GB)";e={[math]::Round($_.TotalPhysicalMemory/1GB,2)}},
                        Domain, Username
                } | Format-List
        }
    }
    "9" = @{
        Name  = "Operating System"
        Block = {
            Get-CimInstance Win32_OperatingSystem |
                Select-Object Caption, Version, BuildNumber, OSArchitecture, InstallDate, LastBootUpTime, SerialNumber |
                Format-List
        }
    }
    "10" = @{
        Name  = "Network (Adapters & IP)"
        Block = {
            $adapters = Get-CimInstance Win32_NetworkAdapter -Filter "PhysicalAdapter=True"
            $cfg = Get-CimInstance Win32_NetworkAdapterConfiguration -Filter "IPEnabled=True"
            "== Adapters =="; $adapters | Select-Object Name, NetEnabled, MACAddress, Speed | Format-Table -AutoSize
            "`r`n== IP Configurations =="; $cfg | Select-Object Description, MACAddress, DHCPEnabled, IPAddress, IPSubnet, DefaultIPGateway, DNSServerSearchOrder | Format-List
        }
    }
    "11" = @{
        Name  = "Monitors / Displays"
        Block = {
            Get-CimInstance Win32_DesktopMonitor |
                Select-Object Name, MonitorType, ScreenHeight, ScreenWidth, PixelsPerXLogicalInch, PixelsPerYLogicalInch, Status |
                Format-Table -AutoSize
        }
    }
    "12" = @{
        Name  = "PnP Devices (summary)"
        Block = {
            Get-CimInstance Win32_PnPEntity |
                Select-Object ClassGuid, PNPClass, Name, Manufacturer, Status |
                Sort-Object PNPClass, Name |
                Format-Table -AutoSize
        }
    }
    "13" = @{
        Name  = "Hotfixes / Updates"
        Block = {
            Get-CimInstance Win32_QuickFixEngineering |
                Select-Object HotFixID, Description, InstalledOn |
                Sort-Object InstalledOn -Descending |
                Format-Table -AutoSize
        }
    }
}

function Show-Menu {
@"
================ Hardware Inventory Menu ================
Select one or more options (comma-separated), or choose:
  1) CPU
  2) RAM (modules)
  3) Disk Drives (physical)
  4) Logical Disks (volumes)
  5) GPU
  6) Motherboard
  7) BIOS/UEFI
  8) Computer System
  9) Operating System
 10) Network
 11) Monitors
 12) PnP Devices (summary)
 13) Hotfixes / Updates

  A) Export ALL
  Q) Quit
========================================================
"@
}

# --- Main ---
$OutFile = Read-Host "Enter output file path or press [Enter] for default ($defaultOutFile)"
if ([string]::IsNullOrWhiteSpace($OutFile)) { $OutFile = $defaultOutFile }

New-Report -Path $OutFile

while ($true) {
    Clear-Host
    Show-Menu
    $choice = Read-Host "Your choice"

    if ([string]::IsNullOrWhiteSpace($choice)) { continue }

    switch ($choice.ToUpper()) {
        "Q" { Write-Host "Bye 👋"; break }

        "A" {
            foreach ($key in ($Blocks.Keys | Sort-Object {[int]$_})) {
                Append-Query -Path $OutFile -Title $Blocks[$key].Name -Block $Blocks[$key].Block
            }
            Write-Host "All sections exported to:`n$OutFile" -ForegroundColor Green
            Read-Host "Press Enter to continue"
        }

        default {
            $parts = $choice.Split(",") | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
            $valid = $true
            foreach ($p in $parts) {
                if (-not $Blocks.ContainsKey($p)) {
                    Write-Host "Invalid option: $p" -ForegroundColor Yellow
                    $valid = $false
                }
            }
            if (-not $valid) { Read-Host "Press Enter to continue"; continue }

            foreach ($p in ($parts | Sort-Object {[int]$_})) {
                Append-Query -Path $OutFile -Title $Blocks[$p].Name -Block $Blocks[$p].Block
            }
            Write-Host "Selected sections exported to:`n$OutFile" -ForegroundColor Green
            Read-Host "Press Enter to continue"
        }
    }
}
