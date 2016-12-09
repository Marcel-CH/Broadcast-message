# Broadcast script - 09.12.2016 - muw
# This script sends a message to all Computers Pattern1 or Pattern2 - 
# solved like this so I dont have to make sure the ActiveDirectory Module need to be loaded


Param($MaxThreads = 15,
    $SleepTimer = 300,
    $MaxWaitAtEnd = 120)
# Get Admin credentials for later
Get-Credential
CLS
Write-host "Checking Files necessary to create Computer-List!" -ForegroundColor DarkYellow 
# copy GetComputerList Batch Files to cocal TEMP
IF(Test-Path C:\Temp\GetComputerList -PathType Container){
    Write-host "GetComputerList-Folder exists!"} 
    else {
    Copy-Item -Path "\Path-to-Folder\GetComputerList*" -Destination "C:\Temp\" -Recurse
    Write-Host "ComputerList Files copied!" -ForegroundColor Green
    }

# PSEXEC ins system32 kopieren
Copy-Item -Path "Path-to-PSEXEC\SYSINTERNALS\PsExec.exe" -Destination "C:\Temp\GetComputerList\" -ErrorAction SilentlyContinue

Write-Host "PSEXEC copied!" -ForegroundColor Green
# make sure, old TXT Files are gone
Write-Host "make sure there are no old PC-List Files" -ForegroundColor Green
Remove-Item "C:\Temp\GetComputerList\cleanedPCNames.txt" -Force -ErrorAction SilentlyContinue
Remove-Item "C:\Temp\GetComputerList\UseNames.txt" -Force -ErrorAction SilentlyContinue
Remove-Item "C:\Temp\GetComputerList\PCnames4.txt" -Force -ErrorAction SilentlyContinue
Remove-Item "C:\Temp\GetComputerList\PCnames5.txt" -Force -ErrorAction SilentlyContinue
Remove-Item "C:\Temp\GetComputerList\PCnames28.txt" -Force -ErrorAction SilentlyContinue
Remove-Item "C:\Temp\GetComputerList\PCnames29.txt" -Force -ErrorAction SilentlyContinue

Write-Host "Creating ComputerList" -ForegroundColor Green
Start -Wait C:\Temp\GetComputerList\CreatePCList.bat

$LAN4 = (Get-Content C:\Temp\GetComputerList\PCnames4.txt)
$LAN5 = (Get-Content C:\Temp\GetComputerList\PCnames5.txt)
$LAN28 = (Get-Content C:\Temp\GetComputerList\PCnames28.txt)
$LAN29 = (Get-Content C:\Temp\GetComputerList\PCnames29.txt)

foreach($line in $LAN4){
    ($line.Remove(0,9) -split "\.")[0] | out-file C:\Temp\GetComputerList\cleanedPCNames.txt -Append
    }

foreach($line in $LAN5){
    ($line.Remove(0,9) -split "\.")[0] | out-file C:\Temp\GetComputerList\cleanedPCNames.txt -Append
    }

foreach($line in $LAN28){
    ($line.Remove(0,9) -split "\.")[0] | out-file C:\Temp\GetComputerList\cleanedPCNames.txt -Append
    }

foreach($line in $LAN29){
    ($line.Remove(0,9) -split "\.")[0] | out-file C:\Temp\GetComputerList\cleanedPCNames.txt -Append
    }

# here we can make sure we reach the right computers and put together a list
(Get-Content C:\Temp\GetComputerList\cleanedPCNames.txt | Select-String -pattern "Pattern1","Pattern2" | Sort-Object | Get-Unique) | out-file  C:\Temp\GetComputerList\UseNames.txt
(Get-Content C:\Temp\GetComputerList\UseNames.txt) | Foreach {$_.TrimEnd()} | where {$_ -ne ""} | Set-Content C:\Temp\GetComputerList\UseNames.txt

$ComputerList = "C:\Temp\GetComputerList\UseNames.txt"    
$Computers = Get-Content $ComputerList

"Killing existing jobs . . ."
Get-Job | Remove-Job -Force
"Done."

# ask for Broadcast-Message with input Box
[void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')

$title = 'Broadcast Message'
$msg   = 'Please enter your Message:'

$text = [Microsoft.VisualBasic.Interaction]::InputBox($msg, $title)

# this is the scriptblock for pinging the computers - as a means of testing the whole thing
#$sb = {param($p1) IF(Test-Connection $p1 -Count 1 -timetolive 1 -ea 0 -Quiet){Write-host "$p1 is online" -BackgroundColor green} else {Write-host "$p1 is offline" -BackgroundColor red}}

# this is the scriptblock for the message
$sb = {param($p1,$p2) C:\Temp\GetComputerList\psexec.exe \\$p1 cmd /C msg.exe * "$p2" 2>$null}

$i = 0

ForEach ($Computer in $Computers){
    While ($(Get-Job -state running).count -ge $MaxThreads){
    Write-Progress -Activity "Creating Computer List" -Status "Waiting for threads to close" -CurrentOperation "$i threads created - $($(Get-Job -state running).count) threads open" -PercentComplete ($i / $Computers.count * 100)
    Start-Sleep -Milliseconds $SleepTimer
    }

    #"Starting job - $Computer"
    $i++
    Start-Job -scriptblock $sb -ArgumentList $Computer,$text | Out-Null
    Write-Progress -Activity "Creating Computer List" -Status "Starting Threads" -CurrentOperation "$i threads created - $($(Get-Job -state running).count) threads open" -PercentComplete ($i / $Computers.count * 100) 
}

$Complete = Get-date

While ($(Get-Job -State Running).count -gt 0){
    $ComputersStillRunning = ""
    ForEach ($System in $(Get-Job -state running)){$ComputersStillRunning += ", $($System.name)"}
    $ComputersStillRunning = $ComputersStillRunning.Substring(2)
    Write-Progress -Activity "Creating Computer List" -Status "$($(Get-Job -State Running).count) threads remaining" -CurrentOperation "$ComputersStillRunning" -PercentComplete ($(Get-Job -State Completed).count / $(Get-Job).count * 100)
    If ($(New-TimeSpan $Complete $(Get-Date)).totalseconds -ge $MaxWaitAtEnd){"Killing all jobs still running . . .";Get-Job -State running | Remove-Job -Force}
    Start-Sleep -Milliseconds $SleepTimer
}
# Only activate if testing with the PING scriptblock activated
<#$pcCount = (Get-content C:\Temp\GetComputerList\UseNames.txt).count
""
""
Write-Host "********* Results *********" -BackgroundColor Yellow
""
""
Write-Host "Checked $pccount Computers, am finished!"
""
get-job | receive-job#>
# cleanup
Remove-Item -Path "C:\Temp\GetComputerList" -Recurse
Write-Host "GetComputerlist Folder deleted" -ForegroundColor Green
Read-Host -Prompt "Press Enter to close Window"
