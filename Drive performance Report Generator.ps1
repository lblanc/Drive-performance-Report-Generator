# Drive performance Report Generator
# Use at your own risk

# V2 combine latency in MB & IOPS graps
# V3 Add GUI
# V4 Add icon in GUI & Progress bar
# V5 New icon

# by Luc BLANC

# Load the Assembl
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")  | out-null


# Elevating PowerShell script
# Get the ID and security principal of the current user account
$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
 
# Get the security principal for the Administrator role
$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
 
# Check to see if we are currently running "as Administrator"
if ($myWindowsPrincipal.IsInRole($adminRole) -ne $true){
[System.Windows.Forms.MessageBox]::Show(“You must run this script as Administrator”,”Warning”, "Ok" , “Warning” , “Button1”)
Exit
}




$scriptpath = Split-Path -parent $MyInvocation.MyCommand.Definition 
Set-Location $scriptpath

$pathdiskspd = $scriptpath + "\diskspd.exe"

if (!(Test-Path $pathdiskspd)) {
[System.Windows.Forms.MessageBox]::Show(“You must have Diskspd.exe in the same folder as the script.”,”Warning”, "Ok" , “Warning” , “Button1”)
Invoke-Expression “cmd.exe /C start https://aka.ms/diskspd”
clear
Exit
}





# Datasources for Graph
$datasourceReadRandom = @()
$datasourceReadSequential = @()
$datasourceWriteRandom = @()
$datasourceWriteSequential = @()



# DataCore icon
$ico = "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"
$ico = [convert]::FromBase64String(($ico))


# Test to see if where are RAW disks
$disks = Get-disk  | Where {$_.partitionstyle -eq "RAW"}
$nbdisks = $disks | measure
if ($nbdisks.count -eq 0) {  
[System.Windows.Forms.MessageBox]::Show(“Where are no RAW disks on the system, RAW disks are needed to make this test.”,”Warning”, "Ok" , “Warning” , “Button1”)
Clear
Exit
}


# GUI
function GUI {

$Global:CancelResult = 1
$Global:testname = "NoName"
$Global:disk = 0
$Global:Time = 0

Add-Type -AssemblyName System.Windows.Forms

$DiskPerfTest = New-Object system.Windows.Forms.Form
$DiskPerfTest.Text = "Disk Perf Test"
#$DiskPerfTest.BackColor = "#f9fff4"
$DiskPerfTest.TopMost = $true
$DiskPerfTest.Width = 800
$DiskPerfTest.Height = 335
$DiskPerfTest.Icon = $ico


$Cancel = New-Object system.windows.Forms.Button
$Cancel.Text = "Cancel"
$Cancel.Width = 60
$Cancel.Height = 30
$Cancel.Add_Click({
$Global:CancelResult = 1
$DiskPerfTest.Close()
})
$Cancel.location = new-object system.drawing.point(144,221)
$Cancel.Font = "Verdana,10"
$DiskPerfTest.controls.Add($Cancel)

$1 = New-Object system.windows.Forms.RadioButton
$1.Text = "1 Second"
$1.AutoSize = $true
$1.Width = 104
$1.Height = 20
$1.Add_Click({
$Global:Time = "-d1"
})
$1.location = new-object system.drawing.point(266,76)
$1.Font = "Microsoft Sans Serif,10"
$DiskPerfTest.controls.Add($1)

$30 = New-Object system.windows.Forms.RadioButton
$30.Text = "30 Seconds"
$30.AutoSize = $true
$30.Width = 104
$30.Height = 20
$30.Validating
$30.Add_Click({
$Global:Time = "-d30"
})
$30.location = new-object system.drawing.point(266,102)
$30.Font = "Microsoft Sans Serif,10"
$DiskPerfTest.controls.Add($30)

$label7 = New-Object system.windows.Forms.Label
$label7.AutoSize = $true
$label7.Width = 100
$label7.Height = 30
$label7.location = new-object system.drawing.point(194,51)
$label7.Font = "Microsoft Sans Serif,10"
$DiskPerfTest.controls.Add($label7)

$testnamebox = New-Object system.windows.Forms.TextBox
$testnamebox.Text = "NoName"
$testnamebox.Width = 100
$testnamebox.Height = 20
$testnamebox.Add_Leave({
$Global:testname = $testnamebox.Text
})
$testnamebox.location = new-object system.drawing.point(22,77)
$testnamebox.Font = "Microsoft Sans Serif,10"
$DiskPerfTest.controls.Add($testnamebox)


$label9 = New-Object system.windows.Forms.Label
$label9.Text = "Give Test Name"
$label9.AutoSize = $true
$label9.Width = 25
$label9.Height = 10
$label9.location = new-object system.drawing.point(22,50)
$label9.Font = "Microsoft Sans Serif,10,style=Underline"
$DiskPerfTest.controls.Add($label9)

$label10 = New-Object system.windows.Forms.Label
$label10.Text = "Test Duration"
$label10.AutoSize = $true
$label10.Width = 25
$label10.Height = 10
$label10.location = new-object system.drawing.point(265,52)
$label10.Font = "Microsoft Sans Serif,10,style=Underline"
$DiskPerfTest.controls.Add($label10)

$60 = New-Object system.windows.Forms.RadioButton
$60.Text = "60 Seconds"
$60.AutoSize = $true
$60.Width = 104
$60.Height = 20
$60.Add_Click({
$Global:Time = "-d60"
})
$60.location = new-object system.drawing.point(267,128)
$60.Font = "Microsoft Sans Serif,10"
$DiskPerfTest.controls.Add($60)

$120 = New-Object system.windows.Forms.RadioButton
$120.Text = "120 Seconds"
$120.AutoSize = $true
$120.Width = 104
$120.Height = 20
$120.Add_Click({
$Global:Time = "-d120"
})
$120.location = new-object system.drawing.point(265,155)
$120.Font = "Microsoft Sans Serif,10"
$DiskPerfTest.controls.Add($120)

$listBox13 = New-Object system.windows.Forms.ListBox
$listBox13.Text = "listbox"
$listBox13.Width = 280
#$listBox13.Height =90
$disks = Get-disk  | Where {$_.partitionstyle -eq "RAW"}
$nbdisks = $disks | measure
$i = 0
while ($i -le ($nbdisks.Count -1)){
$item = "Disk #" + $disks[$i].Number + " | " + $disks[$i].FriendlyName + " | " + ($disks[$i].size /1024 /1024 /1024) + "GB"
[void] $listBox13.Items.Add($item)
$i++
}

$listBox13.Add_Leave({
$Global:disk = $listBox13.SelectedItem.substring(5,2)
})
$listBox13.location = new-object system.drawing.point(474,76)
$DiskPerfTest.controls.Add($listBox13)

$label14 = New-Object system.windows.Forms.Label
$label14.Text = "Select disk to test"
$label14.AutoSize = $true
$label14.Width = 25
$label14.Height = 10
$label14.location = new-object system.drawing.point(473,52)
$label14.Font = "Microsoft Sans Serif,10,style=Underline"
$DiskPerfTest.controls.Add($label14)

$Ok = New-Object system.windows.Forms.Button
$Ok.Text = "OK"
$Ok.Width = 60
$Ok.Height = 30
$Ok.Add_Click({
$Global:CancelResult = 0
$DiskPerfTest.Hide()
})
$Ok.location = new-object system.drawing.point(423,222)
$Ok.Font = "Microsoft Sans Serif,10"
$DiskPerfTest.controls.Add($Ok)

[void]$DiskPerfTest.ShowDialog()
$DiskPerfTest.Dispose()
}

GUI


# Test if items are selected
if ($CancelResult -eq 1) {Exit}
if ($disk -eq 0) {
$result = [System.Windows.Forms.MessageBox]::Show(“No Test Disk Selected !”,”Warning”, "Ok" , “Warning” , “Button1”) 
$Global:CancelResult = 1}
if ($Time -eq 0) {
$result = [System.Windows.Forms.MessageBox]::Show(“No Test Duration Selected !”,”Warning”, "Ok" , “Warning” , “Button1”)
$Global:CancelResult = 1}

if ($CancelResult -eq 1) {Exit}


# Initialize disk for test 
$result = get-disk| where {$_.Number  -eq $disk.substring(1,1) }  | Initialize-Disk -PartitionStyle GPT -PassThru


# Reset test counter
$counter = 0


# Use 1 thread / core
$Thread = “-t”+(Get-WmiObject -Class Win32_ComputerSystem).NumberOfLogicalProcessors


# Outstanding IOs
# Should be 2 times the number of disks in the RAID
# Between  8 and 16 is generally fine
$OutstandingIO = “-o16”




# Initialize outpout file
$date = get-date
$filenamedate = Get-Date -Format yyyyMMdd-HHmm
$logfile = "./" + $filenamedate + "-" + $testname + "-output.txt"
 

# Add the tested disk and the date in the output file
“$testname, Disque $disk, $date” >> $logfile


# Add the headers to the output file
“Test N#, Drive, Operation, Access, Blocks, Run N#, IOPS, MB/sec, Latency ms, CPU %” >> $logfile



# Number of tests
# Multiply the number of loops to change this value
# By default there are : (7 blocks sizes) X (2 for read 100% and write 100%) X (2 for Sequential and Random)
$NumberOfTests = 28



# Start Progress bar
#title for the winform
$Title = "Test Running"
#winform dimensions
$height=100
$width=400
#winform background color
$color = "White"

#create the form
$form1 = New-Object System.Windows.Forms.Form
$form1.Text = $title
$form1.Height = $height
$form1.Width = $width
$form1.BackColor = $color

$form1.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle 
#display center screen
$form1.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen

# create label
$label1 = New-Object system.Windows.Forms.Label
$label1.Text = "Test 1"
$label1.Left=5
$label1.Top= 10
$label1.Width= $width - 20
#adjusted height to accommodate progress bar
$label1.Height=15
$label1.Font= "Verdana"
#optional to show border 
#$label1.BorderStyle=1

#add the label to the form
$form1.controls.add($label1)
$form1.Icon = $ico

$progressBar1 = New-Object System.Windows.Forms.ProgressBar
$progressBar1.Name = 'progressBar1'
$progressBar1.Value = 0
$progressBar1.Style="Continuous"

$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = $width - 40
$System_Drawing_Size.Height = 20
$progressBar1.Size = $System_Drawing_Size

$progressBar1.Left = 5
$progressBar1.Top = 40
$form1.Controls.Add($progressBar1)
$form1.Show()| out-null

#give the form focus
$form1.Focus() | out-null




# Begin Tests loops

# We will run the tests with 4K, 8K, 32K, 64K, 128K, 256K, 512K and 1024K blocks


# (4,8,16,32,64,128,256,512,1024) 
(4,8,16,32,64,128,256) | % { 


$BlockParameter = (“-b”+$_+”K”)


$Blocks = (““+$_+”K”)


 


# We will do Read tests and Write tests


  (0,100) | % {


      if ($_ -eq 0){$IO = “Read”}


      if ($_ -eq 100){$IO = “Write”}


      $WriteParameter = “-w”+$_


 


# We will do random and sequential IO tests


  (“r”,”si”) | % {


      if ($_ -eq “r”){$type = “Random”}


      if ($_ -eq “si”){$type = “Sequential”}


      $AccessParameter = “-“+$_


 


# Each run will be done 1 times

  (1) | % {


     


      # The test itself (finally !!)

         
         $result =  .\diskspd.exe  $Time $AccessParameter $WriteParameter $Thread $OutstandingIO $BlockParameter -h -L $Disk


     


      # Now we will break the very verbose output of DiskSpd in a single line with the most important values


      foreach ($line in $result) {if ($line -like “total:*”) { $total=$line; break } }


      foreach ($line in $result) {if ($line -like “avg.*”) { $avg=$line; break } }


      $mbps = $total.Split(“|”)[2].Trim()


      $iops = $total.Split(“|”)[3].Trim()


      $latency = $total.Split(“|”)[4].Trim()


      $cpu = $avg.Split(“|”)[1].Trim()


      $counter = $counter + 1

      # Add values to $datasources
      if ($IO -like “Read” -and $type -like "Random" )
      {
       $values = New-Object System.Object
       $values | Add-Member -type NoteProperty -name Name -value $Blocks
       $values | Add-Member -type NoteProperty -name MB -value $mbps
       $values | Add-Member -type NoteProperty -name IOPS -value $iops
       $values | Add-Member -type NoteProperty -name Latency -value $latency
       $datasourceReadRandom += $values
       }
       if ($IO -like “Read” -and $type -like "Sequential" )
       {
       $values = New-Object System.Object
       $values | Add-Member -type NoteProperty -name Name -value $Blocks
       $values | Add-Member -type NoteProperty -name MB -value $mbps
       $values | Add-Member -type NoteProperty -name IOPS -value $iops
       $values | Add-Member -type NoteProperty -name Latency -value $latency
       $datasourceReadSequential += $values
       }

      if ($IO -like “Write” -and $type -like "Random")
      {
       $values = New-Object System.Object
       $values | Add-Member -type NoteProperty -name Name -value $Blocks
       $values | Add-Member -type NoteProperty -name MB -value $mbps
       $values | Add-Member -type NoteProperty -name IOPS -value $iops
       $values | Add-Member -type NoteProperty -name Latency -value $latency
       $datasourceWriteRandom += $values
       }
       if ($IO -like “Write” -and $type -like "Sequential")
       {
       $values = New-Object System.Object
       $values | Add-Member -type NoteProperty -name Name -value $Blocks
       $values | Add-Member -type NoteProperty -name MB -value $mbps
       $values | Add-Member -type NoteProperty -name IOPS -value $iops
       $values | Add-Member -type NoteProperty -name Latency -value $latency
       $datasourceWriteSequential += $values
       }


      # Refressh progress bar, for the fun
      $pct = ($counter / $NumberofTests * 100)
      $progressbar1.Value =  $pct 
      $label1.text="Test $Counter / $NumberofTests"
      $form1.Refresh()
      $form1.Focus() | out-null


      # We output the values to the text file


      “Test $Counter,$Disk,$IO,$type,$Blocks,Run $_,$iops,$mbps,$latency,$cpu”  >> $logfile


}


}


}


}




# Loop to generate graph
Add-Type -assemblyName System.Windows.Forms  | out-null
Add-Type -assemblyName System.Windows.Forms.DataVisualization  | out-null
("Random","Sequential") | % { 

$graphtype = $_


("MB","IOPS") | % { 

$graphvalue = $_

$result = [void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms.DataVisualization")

 
# chart object
   $chart1 = New-object System.Windows.Forms.DataVisualization.Charting.Chart
   $chart1.Width = 1500
   $chart1.Height = 600
   $chart1.BackColor = [System.Drawing.Color]::White
 
# title 
   [void]$chart1.Titles.Add("Test: $testname / Disk $Disk / Performance Report by $graphtype $graphvalue") 
   $chart1.Titles[0].Font = "Arial,13pt"
   $chart1.Titles[0].Alignment = "topCenter"
 
# chart area 
   $chartarea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
   $chartarea.Name = "ChartArea1"
   $chartarea.AxisY.Title = "$graphvalue"
   $chartarea.AxisY2.Title = "Latency ms"
   $chartarea.AxisX.Title = "Block Size"
  # $chartarea.AxisY.Interval = 100
   $chartarea.AxisX.Interval = 1
   $chart1.ChartAreas.Add($chartarea)
 
# legend 
   $legend = New-Object system.Windows.Forms.DataVisualization.Charting.Legend
   $legend.name = "Legend1"
   $chart1.Legends.Add($legend)

 
# data series
   $dataseriename = "$graphtype"+"Read"
   [void]$chart1.Series.Add("$dataseriename") 
   $chart1.Series["$dataseriename"].ChartType = "Column"
   $chart1.Series["$dataseriename"].BorderWidth  = 3
   $chart1.Series["$dataseriename"].IsVisibleInLegend = $true
   $chart1.Series["$dataseriename"].chartarea = "ChartArea1"
   $chart1.Series["$dataseriename"].Legend = "Legend1"
   $chart1.Series["$dataseriename"].color = "#04B404"
   $chart1.Series["$dataseriename"].LegendText = "Read"
   $chart1.Series["$dataseriename"].IsValueShownAsLabel = $true
   $datasource = Get-Variable -Name "datasourceRead$graphtype" -ValueOnly 
   $datasource | ForEach-Object {$chart1.Series["$dataseriename"].Points.addxy( $_.Name,$_.$graphvalue) }

 
# data series
   $dataseriename = "$graphtype"+"Write"
   [void]$chart1.Series.Add("$dataseriename")
   $chart1.Series["$dataseriename"].ChartType = "Column"
   $chart1.Series["$dataseriename"].IsVisibleInLegend = $true
   $chart1.Series["$dataseriename"].BorderWidth  = 3
   $chart1.Series["$dataseriename"].chartarea = "ChartArea1"
   $chart1.Series["$dataseriename"].Legend = "Legend1"
   $chart1.Series["$dataseriename"].color = "#DF0101"
   $chart1.Series["$dataseriename"].LegendText = "Write"
   $chart1.Series["$dataseriename"].IsValueShownAsLabel = $true
   $datasource = Get-Variable -Name "datasourceWrite$graphtype" -ValueOnly 
   $datasource  | ForEach-Object {$chart1.Series["$dataseriename"].Points.addxy( $_.Name,$_.$graphvalue) }

# data series
   $dataseriename = "$graphtype"+"RLatency"
   [void]$chart1.Series.Add("$dataseriename") 
   $chart1.Series["$dataseriename"].YAxisType = "Secondary";
   $chart1.Series["$dataseriename"].ChartType = "spline"
   $chart1.Series["$dataseriename"].IsVisibleInLegend = $true
   $chart1.Series["$dataseriename"].BorderWidth  = 3
   $chart1.Series["$dataseriename"].chartarea = "ChartArea1"
   $chart1.Series["$dataseriename"].Legend = "Legend1"
   $chart1.Series["$dataseriename"].color = "#3104B4"
   $chart1.Series["$dataseriename"].LegendText = "Read Latency ms"
   $chart1.Series["$dataseriename"].IsValueShownAsLabel = $true
   $datasource = Get-Variable -Name "datasourceRead$graphtype" -ValueOnly 
   $datasource  | ForEach-Object {$chart1.Series["$dataseriename"].Points. addxy( $_.Name,$_.Latency) }

# data series
   $dataseriename = "$graphtype"+"WLatency"
   [void]$chart1.Series.Add("$dataseriename") 
   $chart1.Series["$dataseriename"].YAxisType = "Secondary";
   $chart1.Series["$dataseriename"].ChartType = "spline"
   $chart1.Series["$dataseriename"].IsVisibleInLegend = $true
   $chart1.Series["$dataseriename"].BorderWidth  = 3
   $chart1.Series["$dataseriename"].chartarea = "ChartArea1"
   $chart1.Series["$dataseriename"].Legend = "Legend1"
   $chart1.Series["$dataseriename"].color = "#B40431"
   $chart1.Series["$dataseriename"].LegendText = "Write Latency ms"
   $chart1.Series["$dataseriename"].IsValueShownAsLabel = $true
   $datasource = Get-Variable -Name "datasourceWrite$graphtype" -ValueOnly 
   $datasource  | ForEach-Object {$chart1.Series["$dataseriename"].Points. addxy( $_.Name,$_.Latency) }

# save chart
   $pngfile = $scriptpath + "\" + $filenamedate + "-" + $testname + "-" + $_ + "-" + $graphtype + ".png"
   $chart1.SaveImage("$pngfile","png") 

    Clear

}


}



# Close Progress bar
$form1.Close() | out-null

# Clean Disk
$result = Clear-Disk $disk.substring(1,1) -PassThru -RemoveData -RemoveOEM -Confirm:$False