$version = '0.01'
$config = @{
    Host = $d42_host
    User = $d42_user
    Pass = $d42_password
}
$APPROVED_VERBS = @('list')
$APPROVED_NOUNS = @('building', 'config', 'device', 'rc')
$APPROVED_FILTERS = @{
    building = @('address', 'contact_name', 'contact_phone')
    device   = @('os_name', 'service_level', 'type', 'hw_model', 'virtual_host', 'ip', 'object_category', 'customer', 'building')
    rc       = @('enabled', 'connected', 'state', 'version', 'ip')
}
$APPROVED_FLAGS = @{
    building = @{
        '--all'    = 'Return all records.' 
        '--exact'  = 'Used to do a exact match instead of a partial match.'
        '--filter' = "options: { $($APPROVED_FILTERS['building']) }"
    }
    device   = @{
        '--all'    = 'Return all records.' 
        '--exact'  = 'Used to do a exact match instead of a partial match.'
        '--filter' = "options: { $($APPROVED_FILTERS['device']) }"
    }
    rc       = @{
        '--all'    = 'Return all records.' 
        '--exact'  = 'Used to do a exact match instead of a partial match.'
        '--filter' = "options: { $($APPROVED_FILTERS['rc']) }"
    }
}
$HELP_MESSAGES = @{
    list = @{
        building = "`nDescription:`nLookup building(s) by partial match and return their properties. Default is do perform a partial lookup so it may return 1 or more records.`n`nFlags:`n*Note: Only one flag can be used at a time*`n`n$(ConvertTo-Json $APPROVED_FLAGS['building'])"
        device   = "`nDescription:`nLookup device(s) by partial match and return their properties. Default is do perform a partial lookup so it may return 1 or more records.`n`nFlags:`n*Note: Only one flag can be used at a time*`n`n$(ConvertTo-Json $APPROVED_FLAGS['device'])"
        rc       = "`nDescription:`nLookup remote rollector(s) by partial match and return their properties. Default is do perform a partial lookup so it may return 1 or more records.`n`nFlags:`n*Note: Only one flag can be used at a time*`n`n$(ConvertTo-Json $APPROVED_FLAGS['rc'])"
    }
}
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
        Write-Host "`nVersion: $($version)`n`n----------How to Use----------`n`nThere are 2 basic ways of calling a d42 cli command.`n`n1. d42 verb noun value`n2. d42 verb noun flag value`n`nVerbs`n$($APPROVED_VERBS)`n`nNouns`n$($APPROVED_NOUNS)`n`nTip: You can get more information on a verb-noun pair (as well as a list of all available flags/filters) like so:`nd42 list device --help`n"
    }
    elseif (Confirm-Verb -_verb $verb) {
        if ($verb -eq 'list') {
            if (Confirm-Noun -_noun $noun) {
                if ($noun -eq 'config') {
                    Write-Host "`nConfig"
                    $($config) | ConvertTo-Json
                    Write-Host
                }
                else {
                    if ($flag -eq '--help') {
                        $HELP_MESSAGES[$verb][$noun] 
                    }
                    # Check to see if a filter was specified
                    elseif ($flag -eq '--filter' ) {
                        if ($value) {
                            $split_filter = $value -split '='
                            $left = $split_filter[0]
                            $right = $split_filter[1]
    
                            if (Confirm-Filter -_noun $noun -_filter $left) {
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
        [string] $_filter
    )
    if ($_filter) {
        if ($APPROVED_FILTERS[$_noun] -contains $_filter) {
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
    if ($_noun -eq 'device') {
        $_query = "WITH target_data AS (SELECT d.name AS name, (Select array_to_string(array(Select da.alias_name From view_devicealias_v1 da Where da.device_fk = d.device_pk ), ' | ') ) alias, d.type AS type, hw.name AS hw_model, CASE WHEN d.type = 'physical' THEN CONCAT(INITCAP(d.type), ' | ', d.physicalsubtype, ' | ', hw.name ) WHEN d.type = 'virtual' THEN CONCAT(INITCAP(d.type), ' | ', d.virtualsubtype) ELSE d.type END AS type_details, dvh.name AS hypervisor, CASE WHEN d.virtual_host_device_fk IS NOT NULL AND dvh.rack_fk IS NOT NULL THEN CONCAT(dvhb.name, ' | ', dvhro.name, ' | ', dvhra.name, ' | ', dvh.name ) WHEN d.virtual_host_device_fk IS NOT NULL AND dvh.rack_fk IS NULL THEN dvh.name WHEN d.virtual_host_device_fk IS NULL AND d.rack_fk IS NOT NULL THEN CONCAT(b.name, ' | ', ro.name, ' | ', ra.name) END AS location_details, COALESCE(b.name, dvhb.name, 'none') AS building, d.os_name AS os_name, d.os_version AS os_version, CASE WHEN d.os_version IS NOT NULL THEN CONCAT(d.os_name, ' | ', d.os_version) ELSE d.os_name END AS os_details, d.total_cpus AS total_cpus, d.core_per_cpu AS core_per_cpu, d.threads_per_core AS threads_per_core, d.ram AS ram, d.ram_size_type as ram_size_type, round(((Select sum(m.capacity - m.free_capacity) / 1024 From view_mountpoint_v1 m Where m.device_fk = d.device_pk and m.fstype_name <> 'nfs'and m.fstype_name <> 'nfs4'and m.filesystem not like '\\\\%') ), 2 ) AS used_space, round(((Select sum(m.capacity / 1024) From view_mountpoint_v1 m Where m.device_fk = d.device_pk and m.fstype_name <> 'nfs'and m.fstype_name <> 'nfs4'and m.filesystem not like '\\\\%') ), 2 ) AS total_space, round(((Select sum(m.free_capacity / 1024) From view_mountpoint_v1 m Where m.device_fk = d.device_pk and m.fstype_name <> 'nfs'and m.fstype_name <> 'nfs4'and m.filesystem not like '\\\\%') ), 2 ) AS free_space, (Select array(Select ip.ip_address From view_ipaddress_v1 ip Where ip.device_fk = d.device_pk ) ) ips, (Select array_to_string(array(Select np.hwaddress From view_netport_v1 np Where np.device_fk = d.device_pk ), ' | ') ) macs, d.service_level AS service_level, oc.name as object_category, c.name as customer, d.notes AS notes, d.tags AS tags, CONCAT('https://$($d42_host)/admin/rackraj/device_', d.type, '/', d.device_pk ) AS url, CONCAT('Created: ', d.first_added, ' | Updated: ', d.last_edited ) AS time_stamps FROM view_device_v2 d LEFT JOIN view_hardware_v2 hw ON hw.hardware_pk = d.hardware_fk LEFT JOIN view_objectcategory_v1 oc ON oc.objectcategory_pk = d.objectcategory_fk LEFT JOIN view_customer_v1 c ON c.customer_pk = d.customer_fk LEFT JOIN view_device_v2 dvh ON dvh.device_pk = d.virtual_host_device_fk LEFT JOIN view_rack_v1 dvhra ON dvhra.rack_pk = dvh.rack_fk LEFT JOIN view_room_v1 dvhro ON dvhro.room_pk = dvhra.room_fk LEFT JOIN view_building_v1 dvhb ON dvhb.building_pk = dvhro.building_fk LEFT JOIN view_rack_v1 ra ON ra.rack_pk = d.rack_fk LEFT JOIN view_room_v1 ro ON ro.room_pk = ra.room_fk LEFT JOIN view_building_v1 b ON b.building_pk = ro.building_fk ) SELECT name AS name, alias AS alias, type_details AS type, location_details AS location, os_details AS OS, CONCAT('Processors: ', (core_per_cpu * total_cpus), ' (', total_cpus, ' sockets, ', core_per_cpu, ' cores), Memory: ', ram, ' ', ram_size_type, ', Storage: ', total_space, ' GB (', used_space, ' used, ', free_space, ' free)') AS resources, array_to_string(ips, ' | ') AS ip_addresses, macs AS macs, service_level AS service_level, object_category as object_category, customer as customer, tags AS tags, notes AS notes, url AS url, time_stamps AS time_stamps FROM target_data"
        if ($_filter) {
            $_where_clause = switch ( $_filter ) {
                'name-exact' { "LOWER(name) = '$($_value)'" }
                'name-like' { "LOWER(name) LIKE '%$($_value)%'" }
                'os_name' { "LOWER(os_name) = '$($_value)'" }
                'service_level' { "LOWER(service_level) = '$($_value)'" }
                'type' { "LOWER(type) = '$($_value)'" }
                'hw_model' { "LOWER(hw_model) = '$($_value)'" }
                'virtual_host' { "LOWER(hypervisor) = '$($_value)'" }
                'ip' { "'$($_value)' = ANY(ips)" }
                'object_category' { "LOWER(object_category) = '$($_value)'" }
                'customer' { "LOWER(customer) = '$($_value)'" }
                'building' { "LOWER(building) = '$($_value)'" }
                default { 'default' }
            }
            $_query = $_query + " WHERE $($_where_clause)"
        }
    }
    elseif ($_noun -eq 'rc') {
        $_query = "select * from view_remotecollector_v1"
        if ($_filter) {
            $_where_clause = switch ( $_filter ) {
                'name-exact' { "LOWER(name) = '$($_value)'" }
                'name-like' { "LOWER(name) LIKE '%$($_value)%'" }
                'enabled' { "LOWER(enabled) = '$($_value)'" }
                'connected' { "LOWER(connected) = '$($_value)'" }
                'state' { "LOWER(state) = '$($_value)'" }
                'version' { "version = '$($_value)'" }
                'ip' { "ip = '$($_value)'" }
                default { 'default' }
            }
            $_query = $_query + " WHERE $($_where_clause)"
        }
    }
    elseif ($_noun -eq 'building') {
        $_query = "select * from view_building_v1"
        if ($_filter) {
            $_where_clause = switch ( $_filter ) {
                'name-exact' { "LOWER(name) = '$($_value)'" }
                'name-like' { "LOWER(name) LIKE '%$($_value)%'" }
                'address' { "LOWER(address) = '$($_value)'" }
                'contact_name' { "LOWER(contact_name) = '$($_value)'" }
                'contact_phone' { "LOWER(contact_phone) = '$($_value)'" }
                default { 'default' }
            }
            $_query = $_query + " WHERE $($_where_clause)"
        }
    }
    return $_query
}