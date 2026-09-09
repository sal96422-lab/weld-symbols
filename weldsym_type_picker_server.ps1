param(
  [Parameter(Mandatory=$true)][string]$RequestPath,
  [Parameter(Mandatory=$true)][string]$ImageDir,
  [Parameter(Mandatory=$true)][string]$ReadyPath,
  [Parameter(Mandatory=$true)][string]$StopPath
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

$groups = @{
  Fillet = @(
    @{ Label = 'Arrow';      Image = 'type_arrow.png';       Value = '0|0|0|0' },
    @{ Label = 'Other';      Image = 'type_other.png';       Value = '1|0|0|0' },
    @{ Label = 'Double';     Image = 'type_both.png';        Value = '2|0|0|0' },
    @{ Label = 'Arrow + L';  Image = 'type_arrow_len.png';   Value = '0|1|0|0' },
    @{ Label = 'Other + L';  Image = 'type_other_len.png';   Value = '1|1|0|0' },
    @{ Label = 'Double + L'; Image = 'type_both_len.png';    Value = '2|1|0|0' },
    @{ Label = 'Stag + L';   Image = 'type_stagger_len.png'; Value = '2|1|1|0' }
  )
  Bevel = @(
    @{ Label = 'Groove Bevel Arrow'; Image = 'type_bevel_arrow.png'; Value = '0|0|0|6' },
    @{ Label = 'Groove Bevel Other'; Image = 'type_bevel_other.png'; Value = '1|0|0|6' },
    @{ Label = 'Groove Bevel Both';  Image = 'type_bevel_both.png';  Value = '2|0|0|6' }
  )
  Groove = @(
    @{ Label = 'Groove Arrow'; Image = 'type_groove_arrow.png'; Value = '0|0|0|7' },
    @{ Label = 'Groove Other'; Image = 'type_groove_other.png'; Value = '1|0|0|7' },
    @{ Label = 'Groove Both'; Image = 'type_groove_both.png'; Value = '2|0|0|7' }
  )
  UGroove = @(
    @{ Label = 'U-Groove Arrow'; Image = 'type_ugroove_arrow.png'; Value = '0|0|0|8' },
    @{ Label = 'U-Groove Other'; Image = 'type_ugroove_other.png'; Value = '1|0|0|8' },
    @{ Label = 'U-Groove Both'; Image = 'type_ugroove_both.png'; Value = '2|0|0|8' }
  )
  SquareGroove = @(
    @{ Label = 'Square Groove Arrow'; Image = 'type_square_groove_arrow.png'; Value = '0|0|0|9' },
    @{ Label = 'Square Groove Other'; Image = 'type_square_groove_other.png'; Value = '1|0|0|9' },
    @{ Label = 'Square Groove Both'; Image = 'type_square_groove_both.png'; Value = '2|0|0|9' }
  )
  FlareVGroove = @(
    @{ Label = 'Flare V Groove Arrow'; Image = 'type_flare_v_groove_arrow.png'; Value = '0|0|0|10' },
    @{ Label = 'Flare V Groove Other'; Image = 'type_flare_v_groove_other.png'; Value = '1|0|0|10' }
  )
  FlareBevelGroove = @(
    @{ Label = 'Flare Bevel Arrow'; Image = 'type_flare_bevel_groove_arrow.png'; Value = '0|0|0|11' },
    @{ Label = 'Flare Bevel Other'; Image = 'type_flare_bevel_groove_other.png'; Value = '1|0|0|11' },
    @{ Label = 'Flare Bevel Both';  Image = 'type_flare_bevel_groove_both.png';  Value = '2|0|0|11' }
  )
}

$imageCache = @{}
foreach ($group in $groups.Values) {
  foreach ($item in $group) {
    if (-not $imageCache.ContainsKey($item.Image)) {
      $loaded = [System.Drawing.Image]::FromFile((Join-Path $ImageDir $item.Image))
      try {
        $imageCache[$item.Image] = New-Object System.Drawing.Bitmap($loaded)
      }
      finally {
        $loaded.Dispose()
      }
    }
  }
}

function Select-WeldValue {
  param([string]$Value)
  Set-Content -LiteralPath $script:outputPath -Value $Value -Encoding ASCII
  $script:form.DialogResult = [System.Windows.Forms.DialogResult]::OK
  $script:form.Close()
}

function Add-DiagramCell {
  param(
    [System.Windows.Forms.TableLayoutPanel]$Panel,
    [hashtable]$Item
  )

  $cell = New-Object System.Windows.Forms.Panel
  $cell.Dock = 'Fill'
  $cell.BackColor = [System.Drawing.Color]::White
  $cell.Cursor = [System.Windows.Forms.Cursors]::Hand
  $cell.Tag = $Item.Value

  $pic = New-Object System.Windows.Forms.PictureBox
  $pic.Image = New-Object System.Drawing.Bitmap($imageCache[$Item.Image])
  $pic.SizeMode = 'Zoom'
  $pic.Location = New-Object System.Drawing.Point(8, 6)
  $pic.Size = New-Object System.Drawing.Size(190, 95)
  $pic.Tag = $Item.Value
  $pic.Cursor = [System.Windows.Forms.Cursors]::Hand

  $label = New-Object System.Windows.Forms.Label
  $label.Text = $Item.Label
  $label.TextAlign = 'MiddleCenter'
  $label.Location = New-Object System.Drawing.Point(4, 104)
  $label.Size = New-Object System.Drawing.Size(198, 24)
  $label.Font = New-Object System.Drawing.Font('Segoe UI', 9)
  $label.Tag = $Item.Value
  $label.Cursor = [System.Windows.Forms.Cursors]::Hand

  $click = {
    param($sender, $eventArgs)
    $value = $sender.Tag
    if (-not $value -and $sender.Parent) { $value = $sender.Parent.Tag }
    Select-WeldValue -Value $value
  }

  $cell.Add_Click($click)
  $pic.Add_Click($click)
  $label.Add_Click($click)

  $cell.Controls.Add($pic)
  $cell.Controls.Add($label)
  [void]$Panel.Controls.Add($cell)
}

function Show-Group {
  param([string]$GroupName)

  foreach ($button in $script:groupButtons.Values) {
    $button.BackColor = [System.Drawing.Color]::FromArgb(238,238,238)
    $button.Font = New-Object System.Drawing.Font('Segoe UI', 11, [System.Drawing.FontStyle]::Regular)
  }
  $script:groupButtons[$GroupName].BackColor = [System.Drawing.Color]::FromArgb(210,225,245)
  $script:groupButtons[$GroupName].Font = New-Object System.Drawing.Font('Segoe UI', 11, [System.Drawing.FontStyle]::Bold)

  $script:diagramPanel.SuspendLayout()
  $script:diagramPanel.Controls.Clear()
  foreach ($item in $groups[$GroupName]) {
    Add-DiagramCell -Panel $script:diagramPanel -Item $item
  }
  $script:diagramPanel.ResumeLayout()
}

function Show-WeldPicker {
  param([string]$OutputPath)

  $script:outputPath = $OutputPath
  if (Test-Path -LiteralPath $OutputPath) {
    Remove-Item -LiteralPath $OutputPath -Force
  }

  $script:form = New-Object System.Windows.Forms.Form
  $script:form.Text = 'Weld Type'
  $script:form.StartPosition = 'CenterScreen'
  $script:form.FormBorderStyle = 'FixedDialog'
  $script:form.MaximizeBox = $false
  $script:form.MinimizeBox = $false
  $script:form.ShowInTaskbar = $true
  $script:form.WindowState = [System.Windows.Forms.FormWindowState]::Normal
  $script:form.TopMost = $true
  $script:form.ClientSize = New-Object System.Drawing.Size(760, 520)
  $script:form.BackColor = [System.Drawing.Color]::FromArgb(245,245,245)
  $script:form.Add_Shown({
    $script:form.WindowState = [System.Windows.Forms.FormWindowState]::Normal
    $script:form.Activate()
    $script:form.BringToFront()
    $script:form.TopMost = $false
  })

  $title = New-Object System.Windows.Forms.Label
  $title.Text = 'Choose weld type, then select diagram'
  $title.AutoSize = $true
  $title.Location = New-Object System.Drawing.Point(14, 12)
  $title.Font = New-Object System.Drawing.Font('Segoe UI', 10)
  $script:form.Controls.Add($title)

  $leftPanel = New-Object System.Windows.Forms.Panel
  $leftPanel.Location = New-Object System.Drawing.Point(14, 42)
  $leftPanel.Size = New-Object System.Drawing.Size(155, 420)
  $leftPanel.BackColor = [System.Drawing.Color]::White
  $leftPanel.BorderStyle = 'FixedSingle'
  $script:form.Controls.Add($leftPanel)

  $leftLabel = New-Object System.Windows.Forms.Label
  $leftLabel.Text = 'Weld type'
  $leftLabel.Location = New-Object System.Drawing.Point(12, 12)
  $leftLabel.Size = New-Object System.Drawing.Size(130, 24)
  $leftLabel.Font = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
  $leftPanel.Controls.Add($leftLabel)

  $script:groupButtons = @{}
  $filletButton = New-Object System.Windows.Forms.Button
  $filletButton.Text = 'Fillet weld'
  $filletButton.Location = New-Object System.Drawing.Point(12, 48)
  $filletButton.Size = New-Object System.Drawing.Size(130, 42)
  $filletButton.FlatStyle = 'Flat'
  $filletButton.Add_Click({ Show-Group -GroupName 'Fillet' })
  $leftPanel.Controls.Add($filletButton)
  $script:groupButtons.Fillet = $filletButton

  $bevelButton = New-Object System.Windows.Forms.Button
  $bevelButton.Text = 'Groove Bevel Welds'
  $bevelButton.Location = New-Object System.Drawing.Point(12, 100)
  $bevelButton.Size = New-Object System.Drawing.Size(130, 42)
  $bevelButton.FlatStyle = 'Flat'
$bevelButton.Add_Click({ Show-Group -GroupName 'Bevel' })
$leftPanel.Controls.Add($bevelButton)
$script:groupButtons.Bevel = $bevelButton

$grooveButton = New-Object System.Windows.Forms.Button
$grooveButton.Text = 'Groove V Weld'
$grooveButton.Location = New-Object System.Drawing.Point(12, 152)
$grooveButton.Size = New-Object System.Drawing.Size(130, 42)
$grooveButton.FlatStyle = 'Flat'
$grooveButton.Add_Click({ Show-Group -GroupName 'Groove' })
$leftPanel.Controls.Add($grooveButton)
$script:groupButtons.Groove = $grooveButton

$uGrooveButton = New-Object System.Windows.Forms.Button
$uGrooveButton.Text = 'U-Groove Weld'
$uGrooveButton.Location = New-Object System.Drawing.Point(12, 204)
$uGrooveButton.Size = New-Object System.Drawing.Size(130, 42)
$uGrooveButton.FlatStyle = 'Flat'
$uGrooveButton.Add_Click({ Show-Group -GroupName 'UGroove' })
$leftPanel.Controls.Add($uGrooveButton)
$script:groupButtons.UGroove = $uGrooveButton

$squareGrooveButton = New-Object System.Windows.Forms.Button
$squareGrooveButton.Text = 'Square Groove Weld'
$squareGrooveButton.Location = New-Object System.Drawing.Point(12, 256)
$squareGrooveButton.Size = New-Object System.Drawing.Size(130, 42)
$squareGrooveButton.FlatStyle = 'Flat'
$squareGrooveButton.Add_Click({ Show-Group -GroupName 'SquareGroove' })
$leftPanel.Controls.Add($squareGrooveButton)
$script:groupButtons.SquareGroove = $squareGrooveButton

$flareVGrooveButton = New-Object System.Windows.Forms.Button
$flareVGrooveButton.Text = 'Flare V Groove Weld'
$flareVGrooveButton.Location = New-Object System.Drawing.Point(12, 308)
$flareVGrooveButton.Size = New-Object System.Drawing.Size(130, 42)
$flareVGrooveButton.FlatStyle = 'Flat'
$flareVGrooveButton.Add_Click({ Show-Group -GroupName 'FlareVGroove' })
$leftPanel.Controls.Add($flareVGrooveButton)
$script:groupButtons.FlareVGroove = $flareVGrooveButton

$flareBevelGrooveButton = New-Object System.Windows.Forms.Button
$flareBevelGrooveButton.Text = 'Flare Bevel Weld'
$flareBevelGrooveButton.Location = New-Object System.Drawing.Point(12, 360)
$flareBevelGrooveButton.Size = New-Object System.Drawing.Size(130, 42)
$flareBevelGrooveButton.FlatStyle = 'Flat'
$flareBevelGrooveButton.Add_Click({ Show-Group -GroupName 'FlareBevelGroove' })
$leftPanel.Controls.Add($flareBevelGrooveButton)
$script:groupButtons.FlareBevelGroove = $flareBevelGrooveButton

  $script:diagramPanel = New-Object System.Windows.Forms.TableLayoutPanel
  $script:diagramPanel.Location = New-Object System.Drawing.Point(182, 42)
  $script:diagramPanel.Size = New-Object System.Drawing.Size(564, 420)
  $script:diagramPanel.ColumnCount = 3
  $script:diagramPanel.RowCount = 3
  $script:diagramPanel.BackColor = [System.Drawing.Color]::White
  $script:diagramPanel.CellBorderStyle = [System.Windows.Forms.TableLayoutPanelCellBorderStyle]::Single
  0..2 | ForEach-Object { [void]$script:diagramPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 33.33))) }
  0..2 | ForEach-Object { [void]$script:diagramPanel.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 33.33))) }
  $script:form.Controls.Add($script:diagramPanel)

  $cancel = New-Object System.Windows.Forms.Button
  $cancel.Text = 'Cancel'
  $cancel.Size = New-Object System.Drawing.Size(90, 28)
  $cancel.Location = New-Object System.Drawing.Point(656, 478)
  $cancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
  $script:form.CancelButton = $cancel
  $script:form.Controls.Add($cancel)

  Show-Group -GroupName 'Fillet'
  [void]$script:form.ShowDialog()

  if (-not (Test-Path -LiteralPath $OutputPath)) {
    Set-Content -LiteralPath $OutputPath -Value 'CANCEL' -Encoding ASCII
  }
}

Set-Content -LiteralPath $ReadyPath -Value $PID -Encoding ASCII

while (-not (Test-Path -LiteralPath $StopPath)) {
  if (Test-Path -LiteralPath $RequestPath) {
    try {
      $outputPath = Get-Content -LiteralPath $RequestPath -Raw
      $outputPath = $outputPath.Trim()
      Remove-Item -LiteralPath $RequestPath -Force
      if ($outputPath) {
        Show-WeldPicker -OutputPath $outputPath
      }
    }
    catch {
      Start-Sleep -Milliseconds 250
    }
  }
  Start-Sleep -Milliseconds 120
}
