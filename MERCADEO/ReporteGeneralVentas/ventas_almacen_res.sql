-- drop function cuentas_cobrar.reporte_general_ventas_almacen_det(p_params text);

CREATE OR REPLACE FUNCTION cuentas_cobrar.reporte_general_ventas_almacen_res(p_params text)
    RETURNS table
            (
                bodega varchar,
                nombre_bodega varchar,
                provincia varchar,
                region text,
                vtacosto numeric,
                vtakilo numeric,
                vtaprecio_alm numeric,
                cantidad_alm numeric
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    PERFORM cuentas_cobrar.reporte_general_ventas(p_params);

    RETURN QUERY
        SELECT t.bodega,
               t.nombre_bodega,
               t.provincia,
               t.region,
               t.vtacosto,
               t.vtakilo,
               t.vtaprecio_alm,
               t.cantidad_alm
        FROM reporte_general_ventas_temp t;
END;
$function$;

SELECT '2025-06-30' AS p_fecha_inicial,
       '2025-06-30' AS p_fecha_final,
       *
FROM cuentas_cobrar.reporte_general_ventas_almacen_res('{
  "fecha_inicial": "2025-06-01",
  "fecha_final": "2025-06-30",
  "item_inicial": "",
  "item_final": "",
  "cliente_inicial": "",
  "cliente_final": "",
  "linea": "",
  "familia": "",
  "codigos_agentes_bodegas": "{}",
  "tipo_ventas": "P",
  "tipo_reporte": "R",
  "es_tot_cliente": true,
  "es_tot_agente": true,
  "con_pedidos": false,
  "con_bodegas": false,
  "con_precios": false,
  "con_componentes": false
}');