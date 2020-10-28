function Get-BlgDriveHealth {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0)]
        [Alias("Computer")]
        [String[]]$computers
    )

    BEGIN {
        $problemcomputers = [System.Collections.ArrayList]@()
        New-Item -Path "C:\drivelogs" -ItemType Directory -Force
        $logfile = New-Item -Path "C:\drivelogs\BlgDriveHealth" -ItemType File -Force
    }

    PROCESS {
        foreach ($computer in $computers) {
            $problems = Get-BlgDriveStatus -Name $computer
            $problemcomputers.Add($problems)
        }
    }

    END {        
        foreach ($problemcomputer in $problemcomputers) {
            Write-Output "Issues found on $($problemcomputer.ComputerName) on $($problemcomputer.DriveLetter)" | Out-File $logfile -Append -Force
            Write-Output "
                VolumeName         : $($problemcomputer.VolumeName)
                FreeSpace          : $($problemcomputer.SpaceUsed)
                S.M.A.R.T. status  : $($problemcomputer.PhysicalDiskHealth)
                Drive status       : $($problemcomputer.VolumeOperationalStatus)
                Drive health       : $($problemcomputer.VolumeHealthStatus) 
            " | Out-File $logfile -Append -Force
        }
        Write-Host "Problem drives written to C:\drivelogs\BlgDriveHealth"
    }
}


