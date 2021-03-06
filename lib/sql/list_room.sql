WITH target_data AS (
    SELECT
        b.name AS building_name,
        ro.name as name,
        CONCAT(
            'Grid Size: ',
            ro.grid_cols * ro.grid_rows,
            ' (',
            ro.grid_cols,
            ' Columns, ',
            ro.grid_rows,
            ' Rows)'
        ) AS grid,
        ro.notes AS room_notes,
        ro.tags AS room_tags,
        CONCAT(
            'https://$($d42_host)/admin/rackraj/room/',
            ro.room_pk
        ) AS url
    FROM
        view_room_v1 ro
        JOIN view_building_v1 b ON b.building_pk = ro.building_fk
)
SELECT
    td.name AS name,
    td.grid,
    td.room_notes AS notes,
    td.room_tags AS tags,
    td.url
FROM
    target_data td