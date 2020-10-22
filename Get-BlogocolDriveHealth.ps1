function Get-BlogocolDriveHealth {
    [CmdletBinding()]
    param(
        [Parameter(
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            Position=0)]
        [String[]]$computername='localhost',

        [Parameter(
            Position=1)]
        [String]$logname
    )    

    $disks = Get-PhysicalDisk
    $tempmax = 3220 # Corresponds to around 50C -- recommended that hard drives do not reach/go beyond this point

    foreach ($disk in $disks) {
        Write-Output "Checking disk: $($disk.FriendlyName) ($($disk.MediaType.ToString())) from computer: $computername ..."
        
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
            Write-Output "Cannot get temperature reading of disk from WMI. Please contact the manufacturer for more information on interfacing with the disk temperature.`n"
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

        $reportfordisk = "For disk $($disk.FriendlyName) on $computername --
        Health status check: $healthreport
        Operational status check: $operationalreport
        Temperature check: $tempreport
        S.M.A.R.T. check: $smartreport"

        Write-Verbose $reportfordisk
        if ($problemsfound -gt 0) {
            $resultfordisk = "$problemsfound problems detected on the disk. Refer to logs for more information
            or choose the '-Verbose' parameter."
        }
        else {
            $resultfordisk = "No problems found. All tests passed."
        }
        
        if ($logname -ne $NULL) {
            try { 
                $reportfordisk.toString() + "`n" + $resultfordisk.toString() | Out-File $logname -Force -Append
            }catch {
                Write-Host "Write to log failed. Please enter a valid log path."
            }  
        }
    }
}