-- drop function cuentas_cobrar.reporte_general_ventas_may_age_det(p_params text);

CREATE OR REPLACE FUNCTION cuentas_cobrar.reporte_general_ventas_may_age_res(p_params text)
    RETURNS table
            (
                vendedor        varchar,
                nombre_vendedor varchar,
                vtacosto        numeric,
                vtakilo         numeric,
                vtaprecio_may   numeric,
                cantidad_may    numeric
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    perform cuentas_cobrar.reporte_general_ventas(p_params);

    RETURN QUERY
        SELECT t.vendedor,
               t.nombre_vendedor,
               t.vtacosto,
               t.vtakilo,
               t.vtaprecio_may,
               t.cantidad_may
        FROM reporte_general_ventas_temp t;
END;
$function$;

SELECT '2025-06-30' as p_fecha_inicial,
  '2025-06-30' as p_fecha_final, *
    from cuentas_cobrar.reporte_general_ventas_may_age_res('{
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
  "es_tot_cliente": false,
  "es_tot_agente": true,
  "con_pedidos": false,
  "con_bodegas": false,
  "con_precios": false,
  "con_componentes": false
}');


