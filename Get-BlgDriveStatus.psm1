
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