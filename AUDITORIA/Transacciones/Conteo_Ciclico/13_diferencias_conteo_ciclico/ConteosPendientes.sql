-- DROP FUNCTION control_inventarios.conteo_fisico_almacen_diferencia_fnc(text, date);

CREATE OR REPLACE FUNCTION control_inventarios.conteo_fisico_almacen_pendientes_fnc()
    RETURNS TABLE
            (
                bodega       character varying,
                fecha_conteo date
            )
    LANGUAGE plpgsql
AS
$function$

BEGIN
    RETURN QUERY
        SELECT idb.bodega, t.fecha_conteo
        FROM (SELECT ib.bodega
              FROM control_inventarios.id_bodegas ib
              WHERE ib.es_punto_venta
                 OR ib.bodega = '040') idb
                 INNER JOIN LATERAL
            (
            SELECT b.fecha_conteo
            FROM control_inventarios.bodegas b
            WHERE b.corte_conteo <> b.fisico_conteo
              AND b.fecha_conteo IS NOT NULL
              AND b.conteo_grabado
              AND b.auditoria_conteo = FALSE
              AND b.bodega = idb.bodega
              AND b.fecha_conteo > '2025-01-01'
            GROUP BY b.fecha_conteo
            ) t ON TRUE
        ORDER BY t.fecha_conteo, idb.bodega;

END;
$function$
;