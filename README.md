````markdown
# 🖥️ Windows Hardware Inventory Script (PowerShell + CIM)

This project provides a **menu-driven PowerShell script** to gather detailed **hardware and system information** from Windows PCs.  
It uses modern `Get-CimInstance` queries (instead of deprecated `Get-WmiObject`) and exports the results to a clean **TXT report**.  

Perfect for:
- System administrators
- IT asset inventory
- Troubleshooting & diagnostics
- Documentation of hardware configs

---

## ✨ Features
- Interactive **menu** with 13 hardware/software categories
- One-shot **Export All** option
- Outputs formatted **TXT report** (default: Desktop\hardware_info.txt)
- Queries include:
  - CPU
  - RAM modules
  - Disk drives (physical & logical)
  - GPU (video controllers)
  - Motherboard & BIOS/UEFI
  - Computer system info
  - Operating System
  - Network (adapters & IP configs)
  - Monitors
  - Plug-and-Play devices
  - Installed hotfixes/updates

---

## 🛠 Requirements
- Windows 10 / 11 (works with both PowerShell 5.1 and PowerShell 7+)
- Execution policy that allows running local scripts:
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
````

---

## 🚀 Installation & Usage

1. Clone the repository or download the script:

   ```powershell
   git clone https://github.com/<your-username>/hardware-inventory.git
   cd hardware-inventory
   ```

2. Launch PowerShell and run the script:

   ```powershell
   .\hardware_inventory.ps1
   ```

3. At startup, you’ll be asked for an **output file path**.

   * Press **Enter** to accept the default: `Desktop\hardware_info.txt`
   * Or type your own path.

4. Select menu options:

   * Enter a single number (e.g., `1`)
   * Multiple numbers separated by commas (e.g., `1,2,5`)
   * `A` for **Export All**
   * `Q` to quit

---

## 📄 Example Outputs

### Example: CPU Information

```
Name              : Intel(R) Core(TM) i7-9750H CPU @ 2.60GHz
Manufacturer      : GenuineIntel
NumberOfCores     : 6
NumberOfLogicalProcessors : 12
MaxClockSpeed     : 2601
SocketDesignation : U3E1
ProcessorId       : BFEBFBFF000906EA
```

### Example: Disk Drives

```
Model                    MediaType   InterfaceType SerialNumber  Size(GB) Status
-----                    ---------   ------------- ------------  -------- ------
Samsung SSD 970 EVO 500GB SSD        NVMe          S3Z6NB0K123456 500      OK
ST1000LM035-1RK172       HDD         SATA          ZDE1B2KD       1000     OK
```

### Example: Network (Adapters & IP)

```
== Adapters ==
Name                          NetEnabled MACAddress        Speed
----                          ---------- ----------        -----
Intel(R) Ethernet Connection  True       00-1A-2B-3C-4D-5E 1000000000
Intel(R) Wi-Fi 6 AX200        True       12-34-56-78-9A-BC 866700000

== IP Configurations ==
Description : Intel(R) Wi-Fi 6 AX200
MACAddress  : 12-34-56-78-9A-BC
DHCPEnabled : True
IPAddress   : {192.168.1.42}
IPSubnet    : {255.255.255.0}
Gateway     : {192.168.1.1}
DNS         : {8.8.8.8, 1.1.1.1}
```

---

## 📊 Usage Scenarios

* Run once on a PC → attach TXT report to helpdesk tickets
* Export all systems in your fleet via **WinRM** or **PsExec**
* Keep reports for **audit / compliance** documentation
* Compare TXT reports before/after hardware upgrades

---

## 🔧 Advanced Notes

* To **list all available CIM classes**:

  ```powershell
  Get-CimClass | Select-Object CimClassName | Sort-Object CimClassName
  ```
* To export disks/volumes in **CSV** instead of TXT, add:

  ```powershell
  Get-CimInstance Win32_LogicalDisk | Export-Csv disks.csv -NoTypeInformation
  ```

---

## 🤝 Contributing

PRs are welcome! If you’d like to add:

* JSON/CSV export
* Remote execution support
* GUI front-end (WinForms/WPF)

…feel free to open an issue or submit a PR.

---

## 📜 License

MIT License. See [LICENSE](LICENSE) for details.

```
