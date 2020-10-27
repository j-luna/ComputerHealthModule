<#
.SYNOPSIS
    Determines the CPU health of a given computer.

.DESCRIPTION
    !! to-do !!

.PARAMETER data
    The computer name and (optional) log file path.

.OUTPUTS
    !! to-do !!

.EXAMPLE
    !! to-do !!
#>

function Get-BlogocolCpuHealth {
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