# Load the config
$config = @{
    Host = $d42_host
    User = $d42_user
    Pass = $d42_password
}
# Load the command lib
$d42_cli = Get-Content "$($PSScriptRoot)\lib\d42-cli.json" | ConvertFrom-Json 
$APPROVED_VERBS = $d42_cli.meta.approved_verbs
$APPROVED_NOUNS = $d42_cli.meta.approved_nouns

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
        $d42_cli.meta | ConvertTo-Json
    }
    elseif (Confirm-Verb -_verb $verb) {
        if ($verb -eq 'list') {
            if (Confirm-Noun -_noun $noun) {
                # Config is special because unlike every other noun, we aren't building any queries. So this is a special case.
                if ($noun -eq 'config') {
                    if ($flag -eq '--help') {
                        $d42_cli.commands."$($verb)_$($noun)".meta | ConvertTo-Json -Depth 3
                    }
                    else {
                        Write-Host "`nConfig"
                        $($config) | ConvertTo-Json
                        Write-Host
                    }
                }
                else {
                    if ($flag -eq '--help') {
                        $d42_cli.commands."$($verb)_$($noun)".meta | ConvertTo-Json -Depth 3
                    }
                    # Check to see if a filter was specified
                    elseif ($flag -eq '--filter' ) {
                        if ($value) {
                            $split_filter = $value -split '='
                            $left = $split_filter[0]
                            $right = $split_filter[1]
    
                            if (Confirm-Filter -_noun $noun -_verb $verb -_filter $left) {
                                if ($right) {
                                    $query = ConvertTo-Doql -_noun $noun -_filter $left -_value $right
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
                            $query = ConvertTo-Doql -_noun $noun -_filter 'name-exact'-_value $value
                            $safety_check = $true
                        }
                        else {
                            Write-Host 'No value specified'
                        }
                    }
                    elseif ($flag -eq '--all') {
                        $query = ConvertTo-Doql -_noun $noun
                        $safety_check = $true
                    }
                    # If we're here it means d42 was called without a flag
                    else {
                        if ($flag) {
                            $query = ConvertTo-Doql -_noun $noun -_filter 'name-like' -_value $flag
                            $safety_check = $true
                        }
                        else {
                            Write-Host 'No flag or value specified'
                        }
                    }
                }
                if ($safety_check -eq $true) {
                    $d42_url = "https://$($d42_host)/services/data/v1.0/query/?query=$($query)&output_type=json"
                    $json = curl.exe -s -k -u "$($d42_user):$($d42_password)" $d42_url
                    $json = $json | ConvertFrom-Json
                    if ($json.name) {
                        $json | ConvertTo-Json
                    }
                    else {
                        Write-Host "No match found."
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
        if ($APPROVED_VERBS -contains $_verb ) {
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
        if ($APPROVED_NOUNS -contains $_noun) {
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
        if ($d42_cli.commands."$($verb)_$($_noun)".meta.flags.'--filter'.filters -contains $_filter) {
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
        [string] $_filter,
        [string] $_value
    )
    $_value = $_value.ToLower()
    $_query = $d42_cli.commands."$($verb)_$($noun)".doql.query.Replace('$($d42_host)', $d42_host)
    if ($_filter) {
        $_where_clause = $d42_cli.commands."$($verb)_$($noun)".doql.conditions."$($_filter)".Replace('$($_value)', $_value)
        $_query = $_query + " WHERE $($_where_clause)"
    }  
    return $_query
}