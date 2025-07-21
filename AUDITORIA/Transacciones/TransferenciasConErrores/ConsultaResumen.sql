-- DROP FUNCTION puntos_venta.items_no_vendidos_consulta(p_bodega varchar, p_codigo_rotacion varchar, p_linea varchar, p_familia varchar);

CREATE OR REPLACE FUNCTION control_inventarios.transferencias_recibidas_con_errores(p_bodega varchar,
                                                                                    fecha_inicial date,
                                                                                    fecha_final date)
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
        SELECT t.transaccion, t.bodega, t.item, t.cantidad_recibida, t.fecha_recepcion
        FROM control_inventarios.transferencia_errores t
        WHERE (t.bodega = p_bodega OR p_bodega = '')
          AND t.fecha_recepcion BETWEEN fecha_inicial AND fecha_final
    and t.revisado;
END ;
$function$
;

