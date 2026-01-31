# MS Family Blocker

A small Windows tool to **stop** or **start** Microsoft Family Safety (Parental Controls) on the current PC. It controls the related Windows service and scheduled tasks so you can temporarily disable or re-enable the feature without uninstalling anything.

---

## What it does

- **Block (Stop):** Stops the Parental Controls service (`WpcMonSvc`), sets its startup type to **Disabled**, and disables the Family Safety scheduled tasks (`FamilySafetyMonitor`, `FamilySafetyRefresh`). Family Safety is effectively turned off until you unblock.
- **Unblock (Start):** Sets the service startup type to **Manual**, starts the service, and re-enables the same scheduled tasks. Family Safety is active again.

No files are deleted; only service state and task enable/disable are changed. You can switch back and forth at any time.

---

## Requirements

- **Windows 10 or 11**
- **Administrator rights** (required to change services and scheduled tasks)
- **PowerShell** (built-in; no extra install)

---

## Files in this folder

| File | Description |
|------|--------------|
| **MS-Family-Blocker.ps1** | Core script. Handles Block, Unblock, and Status. Used by the batch files and the GUI. |
| **MS-Family-Blocker-GUI.ps1** | GUI version. Window with STOP / START buttons, status label, and log area. Runs the same logic as the core script. |
| **Calistir-Blocker.bat** | Menu launcher (console). Run as Administrator; choose 1=Block, 2=Unblock, 3=Status, 0=Exit. |
| **MS-Family-STOP.bat** | One-click: block MS Family (stops service and tasks). Asks for admin if needed. |
| **MS-Family-START.bat** | One-click: unblock MS Family (starts service and tasks). Asks for admin if needed. |
| **MS-Family-Blocker-GUI.bat** | Launcher for the GUI. Double-click to open the window; elevates to admin if required. |

---

## How to use

### GUI (recommended)

1. Double-click **MS-Family-Blocker-GUI.bat**.
2. If Windows asks for administrator permission, click **Yes**.
3. In the window:
   - **STOP (Block)** — turn off MS Family.
   - **START (Unblock)** — turn it back on.
   - **Refresh status (F5)** — update the status text.
4. The **Current:** label shows whether MS Family is **BLOCKED** or **RUNNING**.
5. Keyboard shortcuts: **Ctrl+B** = Block, **Ctrl+U** = Unblock, **F5** = Refresh.

### Console menu

1. Right-click **Calistir-Blocker.bat** → **Run as administrator** (or run it and approve UAC).
2. Choose **1** to block, **2** to unblock, or **3** to see current status.

### One-click batch files

- **MS-Family-STOP.bat** — run (as admin) to block only.
- **MS-Family-START.bat** — run (as admin) to unblock only.

---

## What gets changed

- **Service:** `WpcMonSvc` (Parental Controls)  
  - Block: stopped, startup type = Disabled.  
  - Unblock: startup type = Manual, service started.
- **Scheduled tasks** (under `\Microsoft\Windows\Shell`):  
  - `FamilySafetyMonitor`  
  - `FamilySafetyRefresh`  
  Block disables them; unblock enables them.

Nothing is removed from the system; only the running state and startup/task settings are toggled.

---

## Notes

- Use only on your own computer. Administrator access is required.
- If the service or tasks are missing (e.g. different Windows edition), the script skips those steps and continues with the rest.
- After blocking, Family Safety features (screen time, activity reporting, etc.) will not run until you unblock.

---

## Technical summary

The tool uses PowerShell to:

1. **Block:** `Stop-Service` + `Set-Service -StartupType Disabled` for `WpcMonSvc`, and `Disable-ScheduledTask` for the two Family Safety tasks.
2. **Unblock:** `Set-Service -StartupType Manual` + `Start-Service` for `WpcMonSvc`, and `Enable-ScheduledTask` for the same tasks.
3. **Status:** `Get-Service` and `Get-ScheduledTask` to show current state.

The GUI is built with **Windows Forms** (System.Windows.Forms) and runs the same PowerShell commands when you click STOP or START.
