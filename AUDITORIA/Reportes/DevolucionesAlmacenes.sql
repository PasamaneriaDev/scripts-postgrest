-- drop function auditoria.reporte_devoluciones_almacenes(p_almacen varchar, diferencias boolean, p_cod_rotacion varchar);

CREATE OR REPLACE FUNCTION auditoria.reporte_devoluciones_almacenes(p_almacen varchar, diferencias boolean, p_cod_rotacion varchar)
    RETURNS TABLE
            (
                fecha             date,
                bodega            varchar,
                item              varchar,
                descripcion       varchar,
                codigo_rotacion   varchar,
                cantidad_devolver numeric,
                cantidad_devuelta numeric,
                diferencia        numeric,
                operador          varchar,
                fecha_devolucion  date
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    RETURN QUERY
        SELECT d.creacion_fecha::date                      AS fecha,
               d.bodega,
               d.item,
               i.descripcion,
               i.codigo_rotacion,
               d.cantidad_devolver,
               d.cantidad_devuelta,
               (d.cantidad_devolver - d.cantidad_devuelta) AS diferencia,
               d.operador,
               d.fecha_devolucion
        FROM control_inventarios.devoluciones d
                 JOIN control_inventarios.items i ON i.item = d.item
        WHERE (p_almacen = '' OR d.bodega = p_almacen)
          AND (NOT diferencias OR d.cantidad_devolver <> d.cantidad_devuelta)
          AND (p_cod_rotacion = 'TODO' OR i.codigo_rotacion = p_cod_rotacion);
END;
$function$
;