-- DROP FUNCTION puntos_venta.vales_pendientes_x_almacen(p_almacen character varying)

CREATE OR REPLACE FUNCTION puntos_venta.vales_pendientes_x_almacen(p_almacen character varying)
    RETURNS TABLE
            (
                numero_vale        varchar,
                nombre_cliente     varchar,
                razon              varchar,
                monto              numeric,
                saldo              numeric,
                fecha              date,
                caja               varchar,
                vendedor           varchar,
                numero_caja        numeric,
                referencia         varchar,
                almacen            varchar,
                migracion          char,
                fecha_inicial      date,
                fecha_final        date,
                referencia_factura varchar
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    RETURN QUERY
        SELECT pv.numero_vale,
               pv.nombre_cliente,
               pv.razon,
               pv.monto,
               pv.saldo,
               pv.fecha,
               pv.caja,
               pv.vendedor,
               pv.numero_caja,
               pv.referencia,
               pv.almacen,
               pv.migracion,
               pv.fecha_inicial::date,
               pv.fecha_final::date,
               pv.referencia_factura
        FROM puntos_venta.vales pv
        WHERE pv.almacen = p_almacen
          AND pv.saldo > 0
        ORDER BY pv.fecha;

END
$function$
;

