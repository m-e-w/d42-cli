WITH target_data AS (
    SELECT
        d.name AS name,
        (
            Select
                array_to_string(
                    array(
                        Select
                            da.alias_name
                        From
                            view_devicealias_v1 da
                        Where
                            da.device_fk = d.device_pk
                    ),
                    ' | '
                )
        ) alias,
        d.type AS type,
        hw.name AS hw_model,
        CASE
            WHEN d.type = 'physical' THEN CONCAT(
                INITCAP(d.type),
                ' | ',
                d.physicalsubtype,
                ' | ',
                hw.name
            )
            WHEN d.type = 'virtual' THEN CONCAT(INITCAP(d.type), ' | ', d.virtualsubtype)
            ELSE d.type
        END AS type_details,
        dvh.name AS hypervisor,
        CASE
            WHEN d.virtual_host_device_fk IS NOT NULL
            AND dvh.rack_fk IS NOT NULL THEN CONCAT(
                dvhb.name,
                ' | ',
                dvhro.name,
                ' | ',
                dvhra.name,
                ' | ',
                dvh.name
            )
            WHEN d.virtual_host_device_fk IS NOT NULL
            AND dvh.rack_fk IS NULL THEN dvh.name
            WHEN d.virtual_host_device_fk IS NULL
            AND d.rack_fk IS NOT NULL THEN CONCAT(b.name, ' | ', ro.name, ' | ', ra.name)
        END AS location_details,
        COALESCE(b.name, dvhb.name, 'none') AS building,
        d.os_name AS os_name,
        d.os_version AS os_version,
        CASE
            WHEN d.os_version IS NOT NULL THEN CONCAT(d.os_name, ' | ', d.os_version)
            ELSE d.os_name
        END AS os_details,
        d.total_cpus AS total_cpus,
        d.core_per_cpu AS core_per_cpu,
        d.threads_per_core AS threads_per_core,
        d.ram AS ram,
        d.ram_size_type as ram_size_type,
        round(
            (
                (
                    Select
                        sum(m.capacity - m.free_capacity) / 1024
                    From
                        view_mountpoint_v1 m
                    Where
                        m.device_fk = d.device_pk
                        and m.fstype_name <> 'nfs'
                        and m.fstype_name <> 'nfs4'
                        and m.filesystem not like '\\\\%'
                )
            ),
            2
        ) AS used_space,
        round(
            (
                (
                    Select
                        sum(m.capacity / 1024)
                    From
                        view_mountpoint_v1 m
                    Where
                        m.device_fk = d.device_pk
                        and m.fstype_name <> 'nfs'
                        and m.fstype_name <> 'nfs4'
                        and m.filesystem not like '\\\\%'
                )
            ),
            2
        ) AS total_space,
        round(
            (
                (
                    Select
                        sum(m.free_capacity / 1024)
                    From
                        view_mountpoint_v1 m
                    Where
                        m.device_fk = d.device_pk
                        and m.fstype_name <> 'nfs'
                        and m.fstype_name <> 'nfs4'
                        and m.filesystem not like '\\\\%'
                )
            ),
            2
        ) AS free_space,
        (
            Select
                array(
                    Select
                        ip.ip_address
                    From
                        view_ipaddress_v1 ip
                    Where
                        ip.device_fk = d.device_pk
                )
        ) ips,
        (
            Select
                array_to_string(
                    array(
                        Select
                            np.hwaddress
                        From
                            view_netport_v1 np
                        Where
                            np.device_fk = d.device_pk
                    ),
                    ' | '
                )
        ) macs,
        d.service_level AS service_level,
        oc.name as object_category,
        c.name as customer,
        d.notes AS notes,
        d.tags AS tags,
        CONCAT(
            'https://$($d42_host)/admin/rackraj/device_',
            d.type,
            '/',
            d.device_pk
        ) AS url,
        CONCAT(
            'Created: ',
            d.first_added,
            ' | Updated: ',
            d.last_edited
        ) AS time_stamps
    FROM
        view_device_v2 d
        LEFT JOIN view_hardware_v2 hw ON hw.hardware_pk = d.hardware_fk
        LEFT JOIN view_objectcategory_v1 oc ON oc.objectcategory_pk = d.objectcategory_fk
        LEFT JOIN view_customer_v1 c ON c.customer_pk = d.customer_fk
        LEFT JOIN view_device_v2 dvh ON dvh.device_pk = d.virtual_host_device_fk
        LEFT JOIN view_rack_v1 dvhra ON dvhra.rack_pk = dvh.rack_fk
        LEFT JOIN view_room_v1 dvhro ON dvhro.room_pk = dvhra.room_fk
        LEFT JOIN view_building_v1 dvhb ON dvhb.building_pk = dvhro.building_fk
        LEFT JOIN view_rack_v1 ra ON ra.rack_pk = d.rack_fk
        LEFT JOIN view_room_v1 ro ON ro.room_pk = ra.room_fk
        LEFT JOIN view_building_v1 b ON b.building_pk = ro.building_fk
)
SELECT
    name AS name,
    alias AS alias,
    type_details AS type,
    location_details AS location,
    os_details AS OS,
    CONCAT(
        'Processors: ',
        (core_per_cpu * total_cpus),
        ' (',
        total_cpus,
        ' sockets, ',
        core_per_cpu,
        ' cores), Memory: ',
        ram,
        ' ',
        ram_size_type,
        ', Storage: ',
        total_space,
        ' GB (',
        used_space,
        ' used, ',
        free_space,
        ' free)'
    ) AS resources,
    array_to_string(ips, ' | ') AS ip_addresses,
    macs AS macs,
    service_level AS service_level,
    object_category as object_category,
    customer as customer,
    tags AS tags,
    notes AS notes,
    url AS url,
    time_stamps AS time_stamps
FROM
    target_data
WHERE
    $($ where_clause)