CREATE OR REPLACE FUNCTION mercantil_tosi.consulta_ventas_semanales_pendientes(p_fecha_inicio date,
                                                                               p_fecha_fin date)
    RETURNS table
            (
                item         varchar,
                descripcion  varchar,
                fecha        date,
                cantidad     numeric,
                precio       numeric,
                total_precio numeric
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN

    UPDATE mercantil_tosi.ventas_pasa_semanal as pvs
    SET item = cc.item_nuevo
    FROM control_inventarios.cambios_codigo cc
    WHERE pvs.item = cc.item_actual
      AND NOT pvs.procesado
      AND TO_DATE(pvs.fecha, 'DD/MM/YYYY') BETWEEN p_fecha_inicio AND p_fecha_fin;

    RETURN QUERY
        SELECT pvs.item,
               i.descripcion,
               TO_DATE(pvs.fecha, 'DD/MM/YYYY') AS fecha,
               pvs.qty                          AS cantidad,
               p.precio,
               (pvs.qty * p.precio)             AS total_precio
        FROM mercantil_tosi.ventas_pasa_semanal pvs
                 LEFT JOIN control_inventarios.items i ON pvs.item = i.item
                 LEFT JOIN control_inventarios.precios p ON i.item = p.item AND p.tipo = 'MER'
        WHERE NOT pvs.procesado
          AND TO_DATE(pvs.fecha, 'DD/MM/YYYY') BETWEEN p_fecha_inicio AND p_fecha_fin
        ORDER BY fecha, pvs.secuencial;
END;
$function$
;