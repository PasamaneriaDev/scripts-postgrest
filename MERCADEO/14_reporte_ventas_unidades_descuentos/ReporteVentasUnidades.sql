-- DROP FUNCTION puntos_venta.reporte_ventas_ps_my_unidades(varchar, varchar);

CREATE OR REPLACE FUNCTION puntos_venta.reporte_ventas_ps_my_unidades(periodo_inicial character varying, periodo_final character varying)
 RETURNS TABLE(periodo character varying, item character varying, descripcion character varying, linea character varying, familia character varying, codigo_rotacion character varying, unidad_medida character varying, costo_promedio numeric, precio_mayoreo numeric, precio_publico numeric, precio_cadena numeric, creacion_fecha date, primera_venta date, almvtauns numeric, almvtaues numeric, almvtados numeric, mayvtauns numeric, mayvtaues numeric, mayvtados numeric, total_ventas numeric, existencia_999 numeric, existencia_100 numeric)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_uni_equivalente NUMERIC(10, 2);
BEGIN

    SELECT p.numero
    INTO v_uni_equivalente
    FROM sistema.parametros p
    WHERE p.CODIGO = 'UNIDAD_EQUIVALE'
      AND p.modulo_id = 'TRABPROC';

    RETURN QUERY
        WITH cte AS (SELECT r1.periodo,
                            i.item,
                            i.ruta,
                            SUM(r1.cantidad_ps)  AS cantidad_ps,
                            SUM(r1.total_ps)     AS total_ps,
                            SUM(r1.cantidad_may) AS cantidad_may,
                            SUM(r1.total_may)    AS total_may,
                            i.descripcion,
                            i.linea,
                            i.familia,
                            i.codigo_rotacion,
                            i.unidad_medida,
                            i.costo_promedio,
                            i.creacion_fecha,
                            i.primera_venta
                     FROM (SELECT fd.item,
                                  fd.periodo,
                                  SUM(fd.cantidad)     AS cantidad_ps,
                                  SUM(fd.total_precio) AS total_ps,
                                  0                    AS cantidad_may,
                                  0                    AS total_may
                           FROM puntos_venta.facturas_detalle fd
                           WHERE LEFT(fd.item, 1) IN ('1', '5')
                             --AND COALESCE(status, '') <> 'V'
                             AND fd.periodo BETWEEN periodo_inicial AND periodo_final
                           GROUP BY fd.item, fd.periodo
                           UNION ALL
                           SELECT fd.item,
                                  fd.periodo,
                                  0                    AS cantidad_ps,
                                  0                    AS total_ps,
                                  SUM(fd.cantidad)     AS cantidad_may,
                                  SUM(fd.total_precio) AS total_may
                           FROM cuentas_cobrar.facturas_detalle fd
                           WHERE LEFT(fd.item, 1) IN ('1', '5')
                             --AND COALESCE(status, '') <> 'V'
                             AND fd.periodo BETWEEN periodo_inicial AND periodo_final
                           GROUP BY fd.item, fd.periodo) AS r1
                              JOIN control_inventarios.items i ON i.item = r1.item
                     WHERE i.unidad_medida IN ('UN', 'PQ')
                     GROUP BY i.item, r1.periodo),

             -- PONER EN FUNCION APARTE ESTE QUERY QUE CALCULA EL TIEMPO -> procsist.prg ("UnidadesEquivalentes")
             ruta_tiempo AS (SELECT r.ruta,
                                    SUM(CASE
                                            WHEN c.departamento = '11' AND RIGHT(TRIM(r.operacion), 1) <> '1'
                                                THEN CASE
                                                         WHEN r.unidades = 'UNO' THEN r.minutos
                                                         WHEN r.unidades = 'CIEN' THEN r.minutos / 100
                                                         WHEN r.unidades = 'MIL' THEN r.minutos / 1000
                                                END
                                            ELSE 0
                                        END) AS tiempo
                             FROM rutas.rutas r
                                      JOIN rutas.centros c ON c.codigo = r.centro
                                      JOIN (SELECT DISTINCT ruta FROM cte) AS distinct_cte ON distinct_cte.ruta = r.ruta
                             GROUP BY r.ruta)
        SELECT cte.periodo,
               cte.item,
               REPLACE(REPLACE(cte.descripcion, ',', ''), ';', '')::varchar AS descripcion,
               cte.linea,
               cte.familia,
               cte.codigo_rotacion,
               cte.unidad_medida,
               cte.costo_promedio,
               pm.precio                                                                 AS precio_mayoreo,
               pp.precio                                                                 AS precio_publico,
               pc.precio                                                                 AS precio_cadena,
               cte.creacion_fecha,
               cte.primera_venta,
               cte.cantidad_ps                                                           AS AlmVtaUnS,
               COALESCE(ROUND((cte.cantidad_ps * rt.tiempo) / v_uni_equivalente, 2), 0)  AS AlmVtaUES,
               cte.total_ps                                                              AS AlmVtaDoS,
               cte.cantidad_may                                                          AS MayVtaUnS,
               COALESCE(ROUND((cte.cantidad_may * rt.tiempo) / v_uni_equivalente, 2), 0) AS MayVtaUES,
               cte.total_may                                                             AS MayVtaDoS,
               (cte.cantidad_ps + cte.cantidad_may)                                      AS TOTAL_VENTAS,
               COALESCE(b999.existencia, 0)                                              AS existencia_999,
               COALESCE(b100.existencia, 0)                                              AS existencia_100
        FROM cte
                 LEFT JOIN ruta_tiempo AS rt ON rt.ruta = cte.ruta
                 LEFT JOIN control_inventarios.precios pm ON pm.item = cte.item AND pm.tipo = 'MAY'
                 LEFT JOIN control_inventarios.precios pp ON pp.item = cte.item AND pp.tipo = 'PVP'
                 LEFT JOIN control_inventarios.precios pc ON pc.item = cte.item AND pc.tipo = 'CAD'
                 LEFT JOIN control_inventarios.bodegas b999
                           ON b999.item = cte.item AND b999.bodega = '999'
                 LEFT JOIN control_inventarios.bodegas b100
                           ON b100.item = cte.item AND b100.bodega = '100'
        ORDER BY cte.item, cte.periodo;
END;
$function$
;
