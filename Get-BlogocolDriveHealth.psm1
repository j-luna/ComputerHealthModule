<#
.SYNOPSIS
    Determines the disk health of a given computer.

.DESCRIPTION
    Tests the health, operational status, S.M.A.R.T. status, and temperature each disk on a computer.

.PARAMETER data
    The computer name and (optional) log file path.

.OUTPUTS
    !! to-do !!

.EXAMPLE
    !! to-do !!
#>
function Get-BlogocolDriveHealth {
    [CmdletBinding()]
    param(
        [Parameter(
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            Position=0
        )]
        [String[]]$computername='localhost',
        [String]$logname='.\drive_health_log.log'
    )
    
    BEGIN {
        $alldiskreport = [System.Collections.ArrayList]@()

        if ( ($logname.Split('.'))[-1] -ne 'log' ) {
            throw { 'Error: Please enter a valid log name/path (must be .log file).' }
        }
        else {
            $logfile = New-Item $logname -Force
        }
    }

    PROCESS {

        $disks = Get-PhysicalDisk
        $tempmax = 3220 # Corresponds to around 50C -- recommended that hard drives do not reach/go beyond this point
    
        foreach ($disk in $disks) {
            Write-Host "Checking disk: $($disk.FriendlyName) ($($disk.MediaType.ToString())) from computer: $computername ..."
        
            $problemsfound = 0
            $diskstatus = $disk | Get-StorageReliabilityCounter

            $healthstatus = $disk.HealthStatus
            $operationalstatus = $disk.OperationalStatus

            $smartstatus = (Get-CimInstance `
                -ComputerName $computername `
                -Namespace 'root\WMI' `
                -ClassName 'MSStorageDriver_FailurePredictStatus').PredictFailure

            $temp = $diskstatus.Temperature
            $tempKelvin = 0
            $tempCelsius = 0

            if ($temp -eq 0) {
                Write-Verbose "Cannot get temperature reading of disk $($disk.FriendlyName) on $computername from WMI. Please contact the manufacturer for more information on interfacing with the disk temperature.`n"
            }
            else {
                $tempKelvin = ($temp) / 10.0
                $tempCelsius = $tempKelvin - 273.15
            }

            if ($healthstatus -ne "Healthy") {
                $problemsfound++
                $healthreport = "Warning -- status: $healthstatus"
            }
            else {
                $healthreport = "Passed"
            }

            if ($operationalstatus -ne "OK") {
                $problemsfound++
                $operationalreport = "Warning -- status: $operationalstatus"
            }
            else {
                $operationalreport = "Passed"
            }

            if ($temp -eq 0) {
                $tempreport = "Inconclusive"
            }
            elseif ($temp -ge $tempmax) {
                $problemsfound++
                $tempreport =  "Warning -- current temp: ($tempCelsius C)"
            }
            else {
                $tempreport = "Passed -- current temp: $tempCelsius C"
            }
        
            if ($smartstatus -eq $true) {
                $problemsfound++
                $smartreport = "Failed"
            }
            else {
                $smartreport = "Passed"
            }

            $reportfordisk = "For disk $($disk.FriendlyName) ($($disk.MediaType.ToString())) on $computername --
            Health status check: $healthreport
            Operational status check: $operationalreport
            Temperature check: $tempreport
            S.M.A.R.T. check: $smartreport"

            Write-Verbose $reportfordisk

            if ($problemsfound -gt 0) {
                $resultfordisk = "$problemsfound problems detected on the disk. Refer to logs for more information
                or choose the '-Verbose' parameter.`n"
            }
            else {
                $resultfordisk = "No problems found (though status may be inconclusive -- consult the log for more information).`n"
            }

            $alldiskreport.Add("$reportfordisk`n$resultfordisk") | Out-Null
        }
    }

    END {
        if ($logfile -ne $NULL) {
            try { 
                foreach ($diskreport in $alldiskreport) {
                    $diskreport | Out-File $logname -Force -Append
                }
            } catch {
                throw { "Write to log failed for a disk. Please enter a valid log path." }
            }
        }
        Write-Host "Process successful.`n"
        
        return $logfile.FullName
    }
}