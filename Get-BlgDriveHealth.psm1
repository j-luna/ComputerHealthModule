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
        New-Item -Path "C:\drivelogs" -ItemType Directory -Force | Out-Null
        $logfile = New-Item -Path "C:\drivelogs\BlgDriveHealth" -ItemType File -Force
    }

    PROCESS {
        foreach ($computer in $computers) {
            $problems = Get-BlgDriveStatus -Name $computer
            $problemcomputers.Add($problems) | Out-Null
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

function Get-BlgDriveStatus {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory=$true,
            ValueFromPipeline=$true,
            Position=0)]
        [Alias("Name")]
        [String]$computername
    )
    
    BEGIN {}
    PROCESS {
        
        Get-BlgDriveInfo -Name $computername | ForEach-Object {
            $smarthealth = $_.PhysicalDiskHealth
            $opstatus    = $_.VolumeOperationalStatus
            $healthstatus = $_.VolumeHealthStatus
            $availablespace = [math]::Round( ((1 - ($freespace / $totalsize) ) * 100 ),2)

            if (
                ($smarthealth -ne 'OK') -or
                ($opstatus -ne 'OK') -or
                ($healthstatus -ne 'Healthy') -or
                ($availablespace -le 10)
            ) { $_ | Select-Object *,@{n='SpaceUsed';e={ ([string]$availablespace + '%') } } }         
        }    
    }

    END{}

}

function Get-BlgDriveInfo {
    [CmdletBinding()]
    param(
        [Parameter(
            ValueFromPipeline=$true,
            Position=0
        )]
        [Alias("Name")]
        [String]$computername='localhost'
    )
    
    Get-CimInstance Win32_DiskDrive | ForEach-Object {
        $disk = $_
        $partitions = "ASSOCIATORS OF " +
                "{Win32_DiskDrive.DeviceID='$($disk.DeviceID)'} " +
                "WHERE AssocClass = Win32_DiskDriveToDiskPartition"
        Get-CimInstance -Query $partitions | ForEach-Object {
            $partition = $_
            $drives = "ASSOCIATORS OF " +
                "{Win32_DiskPartition.DeviceID='$($partition.DeviceID)'} " +
                "WHERE AssocClass = Win32_LogicalDiskToPartition"
            Get-CimInstance -Query $drives | ForEach-Object {
                New-Object -Type PSCustomObject -Property @{
                    ComputerName            = $computername
                    Disk                    = $disk.DeviceID
                    PhysicalDiskHealth      = $disk.Status
                    DiskSerialNumber        = $disk.SerialNumber
                    DiskSize                = $disk.Size
                    DiskModel               = $disk.Model
                    Partition               = $partition.Name
                    PartitionSize           = $partition.Size
                    DriveLetter             = $_.DeviceID
                    VolumeName              = $_.VolumeName
                    Size                    = $_.Size
                    FreeSpace               = $_.FreeSpace
                    VolumeSerialNumber      = $_.VolumeSerialNumber
                    VolumeOperationalStatus = ($_ | Select-Object *,@{l="DriveLetter";e={ ([char[]]$_.DeviceId)[0]} } | Get-Volume).OperationalStatus
                    VolumeHealthStatus      = ($_ | Select-Object *,@{l="DriveLetter";e={ ([char[]]$_.DeviceId)[0]} } | Get-Volume).HealthStatus
                }
            }
        }
    }
}


