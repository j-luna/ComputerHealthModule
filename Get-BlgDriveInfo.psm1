
# -----------------------------------------------------------
# Credit to Ansgar Wiechers for the logical structure for extracting key properties.
# Uses WMI queries to tie specific physical disks to their corresponding partitions,
# and those partitions to their corresponding volumes.
# Source: https://stackoverflow.com/questions/31088930/combine-get-disk-info-and-logicaldisk-info-in-powershell
# -----------------------------------------------------------

<#
.SYNOPSIS
    Retrieves disk properties for a computer.

.DESCRIPTION
    Takes the name of a computer and returns properties of the physical disks, partitions, and volumes associated with lettered drives.

.PARAMETER data
    The name of the computer.

.OUTPUTS
    A PSCustomObject containing the disk properties.

.EXAMPLE
    Retrieves disk information for all disks available to localhost.

    $report = Get-BlgDriveHealth
#>
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