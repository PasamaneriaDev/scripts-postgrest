-- drop function cuentas_cobrar.reporte_general_ventas_todo_det(p_params text);

CREATE OR REPLACE FUNCTION cuentas_cobrar.reporte_general_ventas_todo_res(p_params text)
    RETURNS table
            (
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
        SELECT t.vtacosto,
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
FROM cuentas_cobrar.reporte_general_ventas_todo_res('{
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
  "tipo_reporte": "R",
  "es_tot_cliente": true,
  "es_tot_agente": true,
  "con_pedidos": false,
  "con_bodegas": false,
  "con_precios": false,
  "con_componentes": false
}');



SELECT '2025-07-04' AS p_fecha_inicial, '2025-07-04' AS p_fecha_final, *
FROM cuentas_cobrar.reporte_general_ventas_may_age_det(
        'SELECT cuentas_cobrar.reporte_general_ventas('{"fecha_inicial":"2025-07-04", "fecha_final":"2025-07-04",
        "item_inicial":"", "item_final":"", "cliente_inicial":"", "cliente_final":"", "linea":"", "familia":"",
        "codigos_agentes_bodegas":"{}", "tipo_ventas":"M", "tipo_reporte":"D", "es_tot_cliente":false,
        "es_tot_agente":true, "con_pedidos":false, "con_bodegas":false, "con_precios":false, "con_componentes":false}')')