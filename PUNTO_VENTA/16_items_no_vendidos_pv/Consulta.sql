-- DROP FUNCTION puntos_venta.items_no_vendidos_consulta(p_bodega varchar, p_codigo_rotacion varchar, p_linea varchar, p_familia varchar);

CREATE OR REPLACE FUNCTION puntos_venta.items_no_vendidos_consulta(p_bodega varchar, p_codigo_rotacion varchar,
                                                                   p_linea varchar, p_familia varchar)
    RETURNS TABLE
            (
                item            varchar,
                descripcion     varchar,
                codigo_rotacion varchar,
                linea           varchar,
                familia         varchar,
                existencia      numeric,
                ultima_venta    date,
                unidad_medida   varchar
            )
    LANGUAGE plpgsql
AS
$function$
DECLARE
BEGIN
    RETURN QUERY
        SELECT t1.item,
               t2.descripcion,
               t2.codigo_rotacion,
               t2.linea,
               t2.familia,
               t1.existencia,
               t1.ultima_venta,
               t2.unidad_medida
        FROM control_inventarios.bodegas t1
                 INNER JOIN control_inventarios.items t2 ON t1.item = t2.item AND CURRENT_DATE - t2.creacion_fecha > 90
        WHERE t1.bodega = p_bodega
          AND t1.existencia > 0
          AND CURRENT_DATE - t1.ultima_venta > 180
          AND (t2.linea = p_linea OR p_linea = '')
          AND (t2.familia = p_familia OR p_familia = '')
          AND (t2.codigo_rotacion = p_codigo_rotacion OR p_codigo_rotacion = '')
        ORDER BY t1.ultima_venta;
END ;
$function$
;

