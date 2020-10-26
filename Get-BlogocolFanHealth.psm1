<#
.SYNOPSIS
    Determines the fan health of a given computer.

.DESCRIPTION
    Tests the operational status of PC fans

.PARAMETER data
    The computer name and (optional) log file path.

.OUTPUTS
    !! to-do !!

.EXAMPLE
    !! to-do !!
#>

function Get-BlogocolFanHealth {
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

    BEGIN {

    }

    PROCESS {

    }

    END {

    }
}