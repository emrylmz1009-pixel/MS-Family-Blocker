#Requires -RunAsAdministrator
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$ServiceName = 'WpcMonSvc'
$TaskPath = '\Microsoft\Windows\Shell'
$TaskNames = @('FamilySafetyMonitor', 'FamilySafetyRefresh')

function Get-ServiceStatus {
    try {
        $svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($svc) { return @{ Exists = $true; Status = $svc.Status; StartType = $svc.StartType } }
    } catch {}
    return @{ Exists = $false }
}

function Get-TaskStatus {
    $result = @{}
    foreach ($taskName in $TaskNames) {
        try {
            $task = Get-ScheduledTask -TaskPath $TaskPath -TaskName $taskName -ErrorAction SilentlyContinue
            if ($task) { $result[$taskName] = @{ State = $task.State; Enabled = ($task.State -ne 'Disabled') } }
            else { $result[$taskName] = $null }
        } catch { $result[$taskName] = $null }
    }
    return $result
}

function Invoke-Block {
    $log = [System.Collections.ArrayList]::new()
    $svcInfo = Get-ServiceStatus
    if ($svcInfo.Exists) {
        if ($svcInfo.Status -eq 'Running') {
            Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
            [void]$log.Add('Service stopped: ' + $ServiceName)
        }
        Set-Service -Name $ServiceName -StartupType Disabled -ErrorAction SilentlyContinue
        [void]$log.Add('Service startup: Disabled')
    }
    foreach ($taskName in $TaskNames) {
        try {
            $task = Get-ScheduledTask -TaskPath $TaskPath -TaskName $taskName -ErrorAction SilentlyContinue
            if ($task) {
                Disable-ScheduledTask -TaskPath $TaskPath -TaskName $taskName | Out-Null
                [void]$log.Add('Task disabled: ' + $taskName)
            }
        } catch {}
    }
    [void]$log.Add('')
    [void]$log.Add('MS Family BLOCKED (stopped).')
    return ($log -join "`r`n")
}

function Invoke-Unblock {
    $log = [System.Collections.ArrayList]::new()
    $svcInfo = Get-ServiceStatus
    if ($svcInfo.Exists) {
        Set-Service -Name $ServiceName -StartupType Manual -ErrorAction SilentlyContinue
        Start-Service -Name $ServiceName -ErrorAction SilentlyContinue
        [void]$log.Add('Service started: ' + $ServiceName)
        [void]$log.Add('Service startup: Manual')
    }
    foreach ($taskName in $TaskNames) {
        try {
            $task = Get-ScheduledTask -TaskPath $TaskPath -TaskName $taskName -ErrorAction SilentlyContinue
            if ($task) {
                Enable-ScheduledTask -TaskPath $TaskPath -TaskName $taskName | Out-Null
                [void]$log.Add('Task enabled: ' + $taskName)
            }
        } catch {}
    }
    [void]$log.Add('')
    [void]$log.Add('MS Family RUNNING (unblocked).')
    return ($log -join "`r`n")
}

function Get-CurrentState {
    $svc = Get-ServiceStatus
    if (-not $svc.Exists) { return 'Unknown' }
    if ($svc.StartType -eq 'Disabled') { return 'BLOCKED' }
    if ($svc.Status -eq 'Running') { return 'RUNNING' }
    return 'Stopped'
}

function Get-StatusText {
    $log = [System.Collections.ArrayList]::new()
    $svcInfo = Get-ServiceStatus
    if ($svcInfo.Exists) {
        [void]$log.Add('Service: ' + $ServiceName)
        [void]$log.Add('  Status: ' + $svcInfo.Status)
        [void]$log.Add('  Startup: ' + $svcInfo.StartType)
    } else {
        [void]$log.Add('Service not found: ' + $ServiceName)
    }
    $taskStatus = Get-TaskStatus
    foreach ($name in $TaskNames) {
        $t = $taskStatus[$name]
        if ($t) {
            $en = if ($t.Enabled) { 'Enabled' } else { 'Disabled' }
            [void]$log.Add('Task ' + $name + ': ' + $t.State + ' (' + $en + ')')
        }
    }
    return ($log -join "`r`n")
}

function Update-StatusLabel {
    param($lbl)
    $state = Get-CurrentState
    $lbl.Text = 'Current: ' + $state
    if ($state -eq 'BLOCKED') {
        $lbl.ForeColor = [System.Drawing.Color]::FromArgb(200, 70, 70)
    } elseif ($state -eq 'RUNNING') {
        $lbl.ForeColor = [System.Drawing.Color]::FromArgb(50, 130, 70)
    } else {
        $lbl.ForeColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
    }
}

$form = New-Object System.Windows.Forms.Form
$form.Text = 'MS Family Blocker'
$form.Size = New-Object System.Drawing.Size(420, 380)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedSingle'
$form.MaximizeBox = $false
$form.BackColor = [System.Drawing.Color]::FromArgb(245, 245, 250)

$fontTitle = New-Object System.Drawing.Font('Segoe UI', 11, [System.Drawing.FontStyle]::Bold)
$fontBtn = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
$fontLog = New-Object System.Drawing.Font('Consolas', 9)

$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = 'MS Family Blocker'
$lblTitle.Location = New-Object System.Drawing.Point(20, 16)
$lblTitle.Size = New-Object System.Drawing.Size(220, 24)
$lblTitle.Font = $fontTitle
$lblTitle.ForeColor = [System.Drawing.Color]::FromArgb(50, 50, 80)
$form.Controls.Add($lblTitle)

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Location = New-Object System.Drawing.Point(250, 18)
$lblStatus.Size = New-Object System.Drawing.Size(130, 22)
$lblStatus.Font = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($lblStatus)

$btnStop = New-Object System.Windows.Forms.Button
$btnStop.Text = 'STOP (Block)'
$btnStop.Location = New-Object System.Drawing.Point(24, 52)
$btnStop.Size = New-Object System.Drawing.Size(170, 44)
$btnStop.Font = $fontBtn
$btnStop.BackColor = [System.Drawing.Color]::FromArgb(220, 80, 80)
$btnStop.ForeColor = [System.Drawing.Color]::White
$btnStop.FlatStyle = 'Flat'
$btnStop.Cursor = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($btnStop)

$btnStart = New-Object System.Windows.Forms.Button
$btnStart.Text = 'START (Unblock)'
$btnStart.Location = New-Object System.Drawing.Point(208, 52)
$btnStart.Size = New-Object System.Drawing.Size(170, 44)
$btnStart.Font = $fontBtn
$btnStart.BackColor = [System.Drawing.Color]::FromArgb(70, 160, 90)
$btnStart.ForeColor = [System.Drawing.Color]::White
$btnStart.FlatStyle = 'Flat'
$btnStart.Cursor = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($btnStart)

$btnRefresh = New-Object System.Windows.Forms.Button
$btnRefresh.Text = 'Refresh status (F5)'
$btnRefresh.Location = New-Object System.Drawing.Point(24, 108)
$btnRefresh.Size = New-Object System.Drawing.Size(354, 28)
$btnRefresh.FlatStyle = 'Flat'
$btnRefresh.Cursor = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($btnRefresh)

$lblKeys = New-Object System.Windows.Forms.Label
$lblKeys.Text = 'Ctrl+B Block  |  Ctrl+U Unblock'
$lblKeys.Location = New-Object System.Drawing.Point(24, 140)
$lblKeys.Size = New-Object System.Drawing.Size(354, 18)
$lblKeys.ForeColor = [System.Drawing.Color]::FromArgb(120, 120, 120)
$lblKeys.Font = New-Object System.Drawing.Font('Segoe UI', 8)
$form.Controls.Add($lblKeys)

$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Location = New-Object System.Drawing.Point(24, 162)
$txtLog.Size = New-Object System.Drawing.Size(354, 151)
$txtLog.Multiline = $true
$txtLog.ReadOnly = $true
$txtLog.ScrollBars = 'Vertical'
$txtLog.Font = $fontLog
$txtLog.BackColor = [System.Drawing.Color]::FromArgb(252, 252, 252)
$txtLog.BorderStyle = 'FixedSingle'
$form.Controls.Add($txtLog)

$btnStop.Add_Click({
    $txtLog.Text = 'Running STOP...' + "`r`n"
    try {
        $txtLog.AppendText((Invoke-Block))
        Update-StatusLabel $lblStatus
    } catch {
        $txtLog.AppendText('Error: ' + $_.Exception.Message)
    }
})

$btnStart.Add_Click({
    $txtLog.Text = 'Running START...' + "`r`n"
    try {
        $txtLog.AppendText((Invoke-Unblock))
        Update-StatusLabel $lblStatus
    } catch {
        $txtLog.AppendText('Error: ' + $_.Exception.Message)
    }
})

$btnRefresh.Add_Click({
    $txtLog.Text = Get-StatusText
    Update-StatusLabel $lblStatus
})

$form.KeyPreview = $true
$form.Add_KeyDown({
    param($sender, $e)
    if ($e.Control -and $e.KeyCode -eq 'B') { $btnStop.PerformClick(); $e.Handled = $true }
    if ($e.Control -and $e.KeyCode -eq 'U') { $btnStart.PerformClick(); $e.Handled = $true }
    if ($e.KeyCode -eq 'F5') { $btnRefresh.PerformClick(); $e.Handled = $true }
})

$form.Add_Load({
    $txtLog.Text = Get-StatusText
    Update-StatusLabel $lblStatus
})

[void]$form.ShowDialog()
