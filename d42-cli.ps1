$config = @{
    Host = $d42_host
    User = $d42_user
    Pass = $d42_password
}
# Function to call the Device42 CLI
function Get-D42() 
{
    param 
    (
        # Approved Verbs: list
        [string] $verb,
        # Approved Nouns: device
        [string] $noun,
        # Approved Flags: --filter
        [string] $flag,
        # Approved Filters: Device: {os_name, service_level, type, hw_model, virtual_host, ip}
        [string] $filter
    )
    $device_filters = @('os_name','service_level','type','hw_model','virtual_host','ip', 'object_category','customer')
    # Dont make any API calls unless input is clean.
    $safety_check = $false

    if($verb)
    {
        if($verb -eq 'list')
        {
            if($noun)
            {
                if($noun -eq 'device')
                {
                    # Check to see if a filter was specified
                    if($flag -eq '--filter' ) 
                    {
                        if($filter) 
                        {
                            $split_filter = $filter -split '='
                            $left = $split_filter[0]
                            $right = $split_filter[1]

                            if($right)
                            {
                                $right = $right.ToLower()
                                $where_clause= switch ($left) 
                                {
                                    'os_name' {"LOWER(os_name) = '$($right)'"}
                                    'service_level' {"LOWER(service_level) = '$($right)'"}
                                    'type' {"LOWER(type) = '$($right)'"}
                                    'hw_model' {"LOWER(hw_model) = '$($right)'"}
                                    'virtual_host' {"LOWER(hypervisor) = '$($right)'"}
                                    'ip' {"'$($right)' = ANY(ips)"}
                                    'object_category' {"LOWER(object_category) = '$($right)'"}
                                    'customer' {"LOWER(customer) = '$($right)'"}
                                    default {'default'}
                                }
                                if ($where_clause -eq 'default')
                                {
                                    # Do nothing
                                    Write-Host "Unapproved filter: $($left)"
                                }
                                else
                                {
                                    $safety_check = $true   
                                }
                            }
                            else
                            {
                                Write-Host 'No filter value specified'
                            }
                        }
                    }
                    elseif($flag -eq '--help') {
                        Write-Host "`nDescription:`nList properties about a specific device. Device name needs to match completely with one in Device42.`n`nExample:`nd42 list device esxi-9000`n`nYou can specify a filter by adding the filter flag after the noun as such:`nd42 list device --filter type=virtual`n`nWrap your filter value in ' ' if there are spaces in it.`nd42 list device --filter hw_model='PowerEdge R610'`n`nOnly one filter can be specified at a time and only EQUALS ( = ) comparisons are currently supported.`n`nThese are the currently available filters:"
                        $device_filters
                        Write-Host
                    }
                    # If we're here it means d42 was called without a approved flag
                    else
                    {
                        if($flag) 
                        {
                            # Because no flag was specified directly, $flag will hold the filter value instead of $filter due to the arguments positions
                            $left = 'name'
                            $right = $flag.ToLower()
                            $where_clause = "LOWER($($left)) = '$($right)'"
                            $safety_check = $true
                        }
                        else
                        {
                            Write-Host 'No flag specified.'
                        }
                    }
                    if($safety_check -eq $true)
                    {
                        $query = "WITH target_data AS (SELECT d.name AS name, (Select array_to_string(array(Select da.alias_name From view_devicealias_v1 da Where da.device_fk = d.device_pk ), ' | ') ) alias, d.type AS type, hw.name AS hw_model, CASE WHEN d.type = 'physical' THEN CONCAT(INITCAP(d.type), ' | ', d.physicalsubtype, ' | ', hw.name ) WHEN d.type = 'virtual' THEN CONCAT(INITCAP(d.type), ' | ', d.virtualsubtype) ELSE d.type END AS type_details, dvh.name AS hypervisor, CASE WHEN d.virtual_host_device_fk IS NOT NULL AND dvh.rack_fk IS NOT NULL THEN CONCAT(dvhb.name, ' | ', dvhro.name, ' | ', dvhra.name, ' | ', dvh.name ) WHEN d.virtual_host_device_fk IS NOT NULL AND dvh.rack_fk IS NULL THEN dvh.name WHEN d.virtual_host_device_fk IS NULL AND d.rack_fk IS NOT NULL THEN CONCAT(b.name, ' | ', ro.name, ' | ', ra.name) END AS location_details, d.os_name AS os_name, d.os_version AS os_version, CASE WHEN d.os_version IS NOT NULL THEN CONCAT(d.os_name, ' | ', d.os_version) ELSE d.os_name END AS os_details, d.total_cpus AS total_cpus, d.core_per_cpu AS core_per_cpu, d.threads_per_core AS threads_per_core, d.ram AS ram, d.ram_size_type as ram_size_type, round(((Select sum(m.capacity - m.free_capacity) / 1024 From view_mountpoint_v1 m Where m.device_fk = d.device_pk and m.fstype_name <> 'nfs'and m.fstype_name <> 'nfs4'and m.filesystem not like '\\\\%') ), 2 ) AS used_space, round(((Select sum(m.capacity / 1024) From view_mountpoint_v1 m Where m.device_fk = d.device_pk and m.fstype_name <> 'nfs'and m.fstype_name <> 'nfs4'and m.filesystem not like '\\\\%') ), 2 ) AS total_space, round(((Select sum(m.free_capacity / 1024) From view_mountpoint_v1 m Where m.device_fk = d.device_pk and m.fstype_name <> 'nfs'and m.fstype_name <> 'nfs4'and m.filesystem not like '\\\\%') ), 2 ) AS free_space, (Select array(Select ip.ip_address From view_ipaddress_v1 ip Where ip.device_fk = d.device_pk ) ) ips, (Select array_to_string(array(Select np.hwaddress From view_netport_v1 np Where np.device_fk = d.device_pk ), ' | ') ) macs, d.service_level AS service_level, oc.name as object_category, c.name as customer, d.notes AS notes, d.tags AS tags, CONCAT('https://$($d42_host)/admin/rackraj/device_', d.type, '/', d.device_pk ) AS url, CONCAT('Created: ', d.first_added, ' | Updated: ', d.last_edited ) AS time_stamps FROM view_device_v2 d LEFT JOIN view_hardware_v2 hw ON hw.hardware_pk = d.hardware_fk LEFT JOIN view_objectcategory_v1 oc ON oc.objectcategory_pk = d.objectcategory_fk LEFT JOIN view_customer_v1 c ON c.customer_pk = d.customer_fk LEFT JOIN view_device_v2 dvh ON dvh.device_pk = d.virtual_host_device_fk LEFT JOIN view_rack_v1 dvhra ON dvhra.rack_pk = dvh.rack_fk LEFT JOIN view_room_v1 dvhro ON dvhro.room_pk = dvhra.room_fk LEFT JOIN view_building_v1 dvhb ON dvhb.building_pk = dvhro.building_fk LEFT JOIN view_rack_v1 ra ON ra.rack_pk = d.rack_fk LEFT JOIN view_room_v1 ro ON ro.room_pk = ra.room_fk LEFT JOIN view_building_v1 b ON b.building_pk = ro.building_fk ) SELECT name AS name, alias AS alias, type_details AS type, location_details AS location, os_details AS OS, CONCAT('Processors: ', (core_per_cpu * total_cpus), ' (', total_cpus, ' sockets, ', core_per_cpu, ' cores), Memory: ', ram, ' ', ram_size_type, ', Storage: ', total_space, ' GB (', used_space, ' used, ', free_space, ' free)') AS resources, array_to_string(ips, ' | ') AS ip_addresses, macs AS macs, service_level AS service_level, object_category as object_category, customer as customer, tags AS tags, notes AS notes, url AS url, time_stamps AS time_stamps FROM target_data WHERE $($where_clause)"
                        $d42_url = "https://$($d42_host)/services/data/v1.0/query/?query=$($query)&output_type=json"
                        $json = curl.exe -s -k -u "$($d42_user):$($d42_password)" $d42_url
                        $json = $json | ConvertFrom-Json
                        if($json.name) 
                        {
                            $json | ConvertTo-Json
                        }
                        else 
                        {
                            Write-Host "No match found for: $($where_clause)"
                        }
                    }
                }
                elseif($noun -eq 'config') {
                    Write-Host "`nConfig"
                    $($config) | ConvertTo-Json
                    Write-Host
                }
                else
                {
                    Write-Host "Unapproved noun: $($noun)"
                }
            }
            else
            {
                Write-Host 'No noun specified'
            }
        }
        elseif($verb -eq '--help')
        {
            Write-Host "`n----------How to Use----------`n`nThere are 2 basic ways of calling a d42 cli command.`n`n1. d42 verb noun object_name`n2. d42 verb noun --filter key=value`n`nYou can only specify 1 filter at a time and only EQUALS ( = ) comparisons are supported.`n`nApproved Verbs`nlist`n`nApproved Nouns`ndevice`n`nTip: You can get more information on a command (as well as a list of all available filters) like so:`nd42 list device --help`n"
        }
        else
        {
            Write-Host "Unapproved verb: $($verb)"
        }  
    }
    else
    {
        Write-Host 'No verb specified'
    }
}