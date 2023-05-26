add-type -name user32 -namespace win32 -memberDefinition '[DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);'
[win32.user32]::showWindow((get-process -id $pid).mainWindowHandle, 0)

# Load the Winforms assembly
[reflection.assembly]::LoadWithPartialName( "System.Windows.Forms") | out-null

# Create the form
$form = New-Object Windows.Forms.Form

#Configure the form
$form.text = ""
$form.AutoScaleMode = 2
$form.FormBorderStyle = 0
$form.ControlBox = $false
$form.BackColor = [System.Drawing.Color]::Black
$form.TransparencyKey = [System.Drawing.Color]::Black
$form.AllowTransparency = $true
$form.Width = 400
$form.ShowInTaskbar = $false

#Systray Icon
$notifyIcon = New-Object Windows.Forms.NotifyIcon
$notifyIcon.Icon = [System.Drawing.SystemIcons]::Information
$notifyIcon.Text = "DesktopInfo POSH"
$notifyIcon.Visible = $true


#define a context menu
$contextMenu = New-Object Windows.Forms.ContextMenu
$contextMenuExit = New-Object Windows.Forms.MenuItem
$contextMenuExit.Text = "E&xit"
$contextMenuExit.Add_Click({
    $form.Close()
})
#Out-Null is added to suppress output of index
$contextMenu.MenuItems.Add($contextMenuExit) | Out-Null
$notifyIcon.ContextMenu = $contextMenu


$point = New-Object System.Drawing.Point
$point.Y = 0
$point.X = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Right - $form.Width
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::Manual
$form.DesktopLocation = $point


# Create the hostName label control and set text, size and location
$hostName = New-Object Windows.Forms.Label
$hostName.Location = New-Object System.Drawing.Point(10,10)
$hostName.Size = New-Object System.Drawing.Size(100,25)
$hostName.Width = 300
$hostName.Font = New-Object System.Drawing.Font($hostName.font.Name,16,[System.Drawing.FontStyle]::Bold)
$hostName.ForeColor = [System.Drawing.Color]::White
$hostName.text = "Host Name: $($env:COMPUTERNAME)"

# Create the userName label control and set text, size and location
$userName = New-Object Windows.Forms.Label
$userName.Location = New-Object System.Drawing.Point(10,40)
$userName.Size = New-Object System.Drawing.Size(100,25)
$userName.Width = 300
$userName.Font = New-Object System.Drawing.Font($hostName.font.Name,16,[System.Drawing.FontStyle]::Bold)
$userName.ForeColor = [System.Drawing.Color]::White
$userName.text = "Username: $($env:USERNAME)"


$NetAdapters = Get-NetAdapter
$IPLabel = @()
$i = 70

foreach($na in $NetAdapters){
        $IP = New-Object Windows.Forms.Label
        $IP.Location = New-Object System.Drawing.Point(10,$i)
        $IP.Size = New-Object System.Drawing.Size(100,25)
        $IP.Width = 500
        $IP.Font = New-Object System.Drawing.Font($hostName.font.Name,16,[System.Drawing.FontStyle]::Bold)
        $IP.ForeColor = [System.Drawing.Color]::White
        $IP | Add-Member -NotePropertyName ifIndex -NotePropertyValue $na.ifIndex
        $AdapterAlias = $na.ifAlias
        if($adapterAlias.length -gt 15){
            $adapterAlias = "$($na.ifAlias)".Substring(0,15)
        }
        $IP.text = "$($AdapterAlias): $((Get-NetIPAddress -InterfaceIndex $na.ifIndex).IPv4Address)"
        $IPLabel+=$IP
        $i+=30
}

#refresh form every 2 seconds
$Timer = New-Object System.Windows.Forms.Timer
$Timer.Interval = 2000
$Timer.Add_Tick({
    $hostName.text = "Host Name: $($env:COMPUTERNAME)"
    $userName.text = "Username: $($env:USERNAME)"
    
    #cycle through known interfaces by index
    foreach($l in $IPLabel){
        $na = Get-NetAdapter -InterfaceIndex $l.ifIndex
        $AdapterAlias = $na.ifAlias
        if($adapterAlias.length -gt 15){
            $adapterAlias = "$($na.ifAlias)".Substring(0,15)
        }
        $l.text = "$($AdapterAlias): $((Get-NetIPAddress -InterfaceIndex $na.ifIndex).IPv4Address)"
    }
    $form.SendToBack()
})
$Timer.Enabled = $true


# Add the controls to the Form
$form.controls.add($hostName)
$form.controls.add($userName)
foreach($l in $IPLabel){
    $form.controls.add($l)
}

# Display the dialog
$form.SendToBack()
$form.ShowDialog()
$timer.Stop()
$notifyIcon.Dispose()
