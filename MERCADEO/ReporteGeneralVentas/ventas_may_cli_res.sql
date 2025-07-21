-- drop function cuentas_cobrar.reporte_general_ventas_may_age_det(p_params text);

CREATE OR REPLACE FUNCTION cuentas_cobrar.reporte_general_ventas_may_cli_res(p_params text)
    RETURNS table
            (
                cliente        varchar,
                nombre_cliente varchar,
                vtacosto       numeric,
                vtakilo        numeric,
                vtaprecio_may  numeric,
                cantidad_may   numeric
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    PERFORM cuentas_cobrar.reporte_general_ventas(p_params);

    RETURN QUERY
        SELECT t.cliente,
               t.nombre_cliente,
               t.vtacosto,
               t.vtakilo,
               t.vtaprecio_may,
               t.cantidad_may
        FROM reporte_general_ventas_temp t;
END;
$function$;

SELECT '2025-06-30' AS p_fecha_inicial,
       '2025-06-30' AS p_fecha_final,
       *
FROM cuentas_cobrar.reporte_general_ventas_may_cli_res('{
  "fecha_inicial": "2025-06-01",
  "fecha_final": "2025-06-30",
  "item_inicial": "",
  "item_final": "",
  "cliente_inicial": "",
  "cliente_final": "",
  "linea": "",
  "familia": "",
  "codigos_agentes_bodegas": "{}",
  "tipo_ventas": "M",
  "tipo_reporte": "R",
  "es_tot_cliente": true,
  "es_tot_agente": false,
  "con_pedidos": false,
  "con_bodegas": false,
  "con_precios": false,
  "con_componentes": false
}');


