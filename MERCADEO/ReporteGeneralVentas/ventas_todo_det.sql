-- drop function cuentas_cobrar.reporte_general_ventas_todo_det(p_params text);

CREATE OR REPLACE FUNCTION cuentas_cobrar.reporte_general_ventas_todo_det(p_params text)
    RETURNS table
            (
                item            varchar,
                descripcion     varchar,
                unidad_medida   varchar,
                familia         varchar,
                linea           varchar,
                creacion_fecha  date,
                codigo_rotacion varchar,
                ultima_venta    date,
                existencia      numeric,
                peso            numeric,
                vtacosto        numeric,
                vtakilo         numeric,
                cantidad_total  numeric,
                vtaprecio_total numeric,
                vtaprecio_may   numeric,
                cantidad_may    numeric,
                vtaprecio_alm   numeric,
                cantidad_alm    numeric
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    PERFORM cuentas_cobrar.reporte_general_ventas(p_params);

    RETURN QUERY
        SELECT t.item,
               t.descripcion,
               t.unidad_medida,
               t.familia,
               t.linea,
               t.creacion_fecha,
               t.codigo_rotacion,
               t.ultima_venta,
               t.existencia,
               t.peso,
               t.vtacosto,
               t.vtakilo,
               (t.cantidad_may + t.cantidad_alm)   AS cantidad_total,
               (t.vtaprecio_may + t.vtaprecio_alm) AS vtaprecio_total,
               t.vtaprecio_may,
               t.cantidad_may,
               t.vtaprecio_alm,
               t.cantidad_alm
        FROM reporte_general_ventas_temp t;
END;
$function$;

SELECT '2025-06-30' AS p_fecha_inicial,
       '2025-06-30' AS p_fecha_final,
       *
FROM cuentas_cobrar.reporte_general_ventas_todo_det('{
  "fecha_inicial": "2025-06-01",
  "fecha_final": "2025-06-30",
  "item_inicial": "",
  "item_final": "",
  "cliente_inicial": "",
  "cliente_final": "",
  "linea": "",
  "familia": "",
  "codigos_agentes_bodegas": "{}",
  "tipo_ventas": "T",
  "tipo_reporte": "D",
  "es_tot_cliente": true,
  "es_tot_agente": true,
  "con_pedidos": false,
  "con_bodegas": false,
  "con_precios": false,
  "con_componentes": false
}');