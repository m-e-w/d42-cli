<#
    d42-cli module.
#>

# Load the config (Values specified in $PROFILE)
$global:D42_CONFIG = @{
    Host  = $d42_host
    User  = $d42_user
    Pass  = $d42_password
    Debug = $d42_debug
}

# Load lib\d42-cli.json (Houses all command data)
$global:D42_CLI = Get-Content "$($PSScriptRoot)\lib\json\d42-cli.json" | ConvertFrom-Json

# Imports lib\doql\*.sql files using the query path specified in the commands
$global:D42_COMMANDS = $D42_CLI.commands
($D42_COMMANDS | ConvertTo-Json -Depth 5 | ConvertFrom-Json -AsHashtable).Keys | ForEach-Object {
    if ($D42_COMMANDS.$_.meta.type -eq 'remote') {
        $D42_COMMANDS.$_.doql.query = ((Get-Content "$($PSScriptRoot)\$($D42_COMMANDS.$_.doql.query)") -replace '(?:\t|\r|\n)', '')
    }
}

# Import a local copy of the Device42 data dictonary (https://docs.device42.com/device42-doql/db-viewer-schema/#section-3)
$global:D42_DD = Get-Content "$($PSScriptRoot)\lib\json\dd.json" | ConvertFrom-Json

# Function to call the Device42 CLI
function Get-D42() {
    param 
    (
        [string] $verb,
        [string] $noun,
        [string] $flag,
        [string] $value
    )
    # Dont make any API calls unless input is clean.
    $safety_check = $false

    if ($verb -eq '--help') {
        $D42_CLI.meta | ConvertTo-Json
    }
    elseif (Confirm-Verb -_verb $verb) {
        if ($verb -eq 'list') {
            if (Confirm-Noun -_noun $noun) {
                # Config is special because unlike every other noun, we aren't building any queries. So this is a special case.
                if ($noun -eq 'config') {
                    if ($flag -eq '--help') {
                        $D42_CLI.commands."$($verb)_$($noun)".meta | ConvertTo-Json -Depth 3
                    }
                    else {
                        Write-Host "`nConfig"
                        $($D42_CONFIG) | ConvertTo-Json
                        Write-Host
                    }
                }
                elseif ($noun -eq 'dd') {
                    if ($flag -eq '--help') {
                        $D42_CLI.commands."$($verb)_$($noun)".meta | ConvertTo-Json -Depth 3
                    }
                    elseif ($flag -eq '--views') {
                        if ($value) {
                            $D42_DD | Where-Object view -CLike "*$($value)*" | Select-Object view -Unique | Sort-Object { $_.view.length } 
                        }
                        else {
                            $D42_DD | Select-Object view -Unique | Sort-Object { $_.view }
                        }
                    }
                    else {
                        $D42_DD | Where-Object view -CLike "*$($flag)*" | Select-Object view, column, data_type, description | Sort-Object { $_.view.length } 
                    }
                }
                else {
                    if ($flag -eq '--help') {
                        $D42_CLI.commands."$($verb)_$($noun)".meta | ConvertTo-Json -Depth 3
                    }
                    # Check to see if a filter was specified
                    elseif ($flag -eq '--filter' ) {
                        if ($value) {
                            $split_filter = $value -split '='
                            $left = $split_filter[0]
                            $right = $split_filter[1]
    
                            if (Confirm-Filter -_noun $noun -_verb $verb -_filter $left) {
                                if ($right) {
                                    $query = ConvertTo-Doql -_noun $noun -_verb $verb -_filter $left -_value $right
                                    $safety_check = $true   
                                }
                                else {
                                    Write-Host 'No filter value specified'
                                }
                            }
                        }
                        else {
                            Write-Host 'No filter specified.'
                        }
                    }
                    elseif ($flag -eq '--exact') {
                        if ($value) {
                            $query = ConvertTo-Doql -_noun $noun -_verb $verb -_filter 'name-exact'-_value $value
                            $safety_check = $true
                        }
                        else {
                            Write-Host 'No value specified'
                        }
                    }
                    elseif ($flag -eq '--all') {
                        $query = ConvertTo-Doql -_noun $noun -_verb $verb
                        $safety_check = $true
                    }
                    # If we're here it means d42 was called without a flag
                    else {
                        if ($flag) {
                            $query = ConvertTo-Doql -_noun $noun -_verb $verb -_filter 'name-like' -_value $flag
                            $safety_check = $true
                        }
                        else {
                            Write-Host 'No flag or value specified'
                        }
                    }
                }
                if ($safety_check -eq $true) {
                    $d42_url = "https://$($d42_host)/services/data/v1.0/query/"
                    $response = $null

                    if($Iswindows)
                    {
                        $response = curl.exe -k -s -X POST -d "output_type=json&query=$query" -u "$($d42_user):$($d42_password)" $d42_url
                    }
                    else
                    {
                        $response = curl -k -s -X POST -d "output_type=json&query=$query" -u "$($d42_user):$($d42_password)" $d42_url
                    }
                    

                    $response = $response | ConvertFrom-Json

                    if($response.psobject.properties -ne $null)
                    {
                        $response
                    }
                    else 
                    {
                        Write-Host "No match found."
                    }
                }                
            }
        }
        elseif($verb -eq 'update'){
            if (Confirm-Noun -_noun $noun) {
                if($noun -eq 'dd'){
                    if ($flag -eq '--help') {
                        $D42_CLI.commands."$($verb)_$($noun)".meta | ConvertTo-Json -Depth 3
                    }
                    else {
                        UpdateDD -_host $d42_host -_username $d42_user -_password $d42_password
                    }
                }
            }
        }
    }
}

# Helper Functions
function Confirm-Verb() {
    param 
    (
        [string] $_verb
    )
    if ($_verb) {
        if ($D42_CLI.meta.approved_verbs -contains $_verb ) {
            return $true
        }
        else {
            Write-Host "Unapproved verb: $($_verb)"
            return $false
        } 
    }
    else {
        Write-Host 'No verb specified'
        return $false
    }
}

function Confirm-Noun() {
    param 
    (
        [string] $_noun
    )
    if ($_noun) {
        if ($D42_CLI.meta.approved_nouns -contains $_noun) {
            return $true
        }
        else {
            Write-Host "Unapproved noun: $($_noun)"
            return $false
        }
    }
    else {
        Write-Host 'No noun specified'
        return $false
    }
}

function Confirm-Filter() {
    param 
    (
        [string] $_noun,
        [string] $_verb,
        [string] $_filter
    )
    if ($_filter) {
        if ($D42_CLI.commands."$($_verb)_$($_noun)".meta.flags.'--filter'.filters -contains $_filter) {
            return $true
        }
        else {
            Write-Host "Unapproved filter: $($_filter)"
            return $false
        }
    }
    else {
        Write-Host 'No filter specified'
        return $false
    }
}

function ConvertTo-Doql() {
    param 
    (
        [string] $_noun,
        [string] $_verb,
        [string] $_filter,
        [string] $_value
    )
    $_value = $_value.ToLower()
    $_query = $D42_COMMANDS."$($_verb)_$($_noun)".doql.query.Replace('$($d42_host)', $d42_host)
    if ($_filter) {
        $_where_clause = $D42_CLI.commands."$($_verb)_$($_noun)".doql.conditions."$($_filter)".Replace('$($_value)', $_value)
        $_query = $_query + " WHERE $($_where_clause)"
    }
    if ($D42_CONFIG.Debug) {
        Write-Host "`nDebug: Enabled`n`nQuery:`n$($_query)`n`nResponse:"
    }  
    return $_query
}

function UpdateDD() {
    param 
    (
        [string] $_host,
        [string] $_username,
        [string] $_password
    )
    $dd = $null
    if($Iswindows){
        $dd = curl.exe -k -s -u "$($_username):$($_password)" "https://$($_host)/services/data/v1.0/dd/" 
        $dd | ConvertFrom-Json | Select-Object -Property view -ExpandProperty columns | ConvertTo-Json -Depth 99 | Out-File "$($PSScriptRoot)\lib\json\dd.json"
    }
    else {
        $dd = curl -k -s -u "$($_username):$($_password)" "https://$($_host)/services/data/v1.0/dd/"
        $dd | ConvertFrom-Json | Select-Object -Property view -ExpandProperty columns | ConvertTo-Json -Depth 99 | Out-File "$($PSScriptRoot)/lib/json/dd.json"
    }   
}