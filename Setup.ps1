# get the ID and security principal of the current user account
$myWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($myWindowsID)

# get the security principal for the Administrator role
$adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator

# check to see if we are not currently running "as Administrator"
if (!$myWindowsPrincipal.IsInRole($adminRole))
{
  # create a new process object that starts PowerShell
  $newProcess = New-Object System.Diagnostics.ProcessStartInfo "PowerShell";

  # store the path to the current script in the arguments
  $newProcess.Arguments = [System.String]::Format("&'{0}'", $myInvocation.MyCommand.Definition)

  # indicate that the process should be elevated
  $newProcess.Verb = "runas";

  # start the new process
  [System.Diagnostics.Process]::Start($newProcess);

  # exit from the current, unelevated, process
  exit
}

# determine folder paths
$PSScriptRoot = split-path -parent $MyInvocation.MyCommand.Definition
$shared = Get-Item -Path "$PSScriptRoot\Scripts"
$missions = Get-ChildItem -Path $PSScriptRoot -Filter 'CtrlC-*.*'

# iterate through the missions
ForEach ($mission in $missions) {
  # determine path to mission scripts directory
  $common = $mission.FullName + '\cc'

  # remove the item if it exists
  If (Test-Path $common) {
    cmd /C rmdir "$common"
  }

  # create a symbolic link to the common scripts directory
  cmd /C mklink /J "$common" "$shared"
}
