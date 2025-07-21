-- drop function puntos_venta.reporte_ventas_netas_almacen_condensado(p_periodo varchar, p_bodegas varchar, p_monto_minimo numeric)

CREATE OR REPLACE FUNCTION puntos_venta.reporte_ventas_netas_almacen_condensado(p_periodo varchar, p_bodegas varchar, p_monto_minimo numeric)
    RETURNS TABLE
            (
                fecha                date,
                periodo              varchar,
                monto_minimo         numeric,
                bodega_1             text,
                num_transacciones_1  integer,
                total_venta_1        numeric,
                bodega_2             text,
                num_transacciones_2  integer,
                total_venta_2        numeric,
                bodega_3             text,
                num_transacciones_3  integer,
                total_venta_3        numeric,
                bodega_4             text,
                num_transacciones_4  integer,
                total_venta_4        numeric,
                bodega_5             text,
                num_transacciones_5  integer,
                total_venta_5        numeric,
                bodega_6             text,
                num_transacciones_6  integer,
                total_venta_6        numeric,
                bodega_7             text,
                num_transacciones_7  integer,
                total_venta_7        numeric,
                bodega_8             text,
                num_transacciones_8  integer,
                total_venta_8        numeric,
                bodega_9             text,
                num_transacciones_9  integer,
                total_venta_9        numeric,
                bodega_10            text,
                num_transacciones_10 integer,
                total_venta_10       numeric
            )
    LANGUAGE plpgsql
AS
$function$
DECLARE
    v_bodegas            text[];
    v_descripciones      text[];
    v_bodega_descripcion text;
BEGIN
    -- Convierte el string de bodegas en un array
    v_bodegas := STRING_TO_ARRAY(p_bodegas, ',');
    -- Se ajusta el tamaño del array a 10 elementos (El maximo soportado por la funcion/reporte)
    FOR i IN ARRAY_LENGTH(v_bodegas, 1) + 1..10
        LOOP
            v_bodegas := ARRAY_APPEND(v_bodegas, 'x');
        END LOOP;

    -- Obtiene la descripción de las bodegas
    FOR i IN 1..ARRAY_LENGTH(v_bodegas, 1)
        LOOP
            SELECT bodega || ' ' || descripcion
            INTO v_bodega_descripcion
            FROM control_inventarios.id_bodegas
            WHERE bodega = v_bodegas[i];

            -- Almacenar el resultado en el array v_descripciones
            v_descripciones := ARRAY_APPEND(v_descripciones, v_bodega_descripcion);
        END LOOP;

    RETURN QUERY
        WITH ventas_netas AS (SELECT p_periodo                              AS                periodo,
                                     p_monto_minimo                         AS                monto_minimo,
                                     x1.bodega,
                                     COUNT(DISTINCT fd.referencia)::integer AS                num_transacciones,
                                     fd.fecha,
                                     SUM(ROUND(COALESCE(fd.TOTAL_PRECIO, 0) -
                                               COALESCE(fd.valor_descuento_adicional, 0), 2)) total_venta
                              FROM puntos_venta.facturas_detalle fd
                                       JOIN puntos_venta.facturas_cabecera fc ON fc.referencia = fd.referencia
                                       JOIN
                                   (SELECT DISTINCT pa.bodega, pa.bodega_primera, cc.subcentro AS descripcion
                                    FROM sistema.parametros_almacenes pa
                                             JOIN control_inventarios.id_bodegas ib
                                                  ON pa.bodega = ib.bodega AND
                                                     COALESCE(pa.bodega_primera, '') <> ib.bodega
                                             LEFT JOIN activos_fijos.centros_costos cc ON cc.codigo = pa.centro_costo
                                    WHERE ib.es_punto_venta
                                      AND ib.fecha_fin_transacciones IS NULL) x1
                                   ON x1.bodega = fd.bodega OR x1.bodega_primera = fd.bodega
                              WHERE fd.periodo = p_periodo
                                AND x1.bodega IN (SELECT UNNEST(v_bodegas))
                                AND ((fc.monto_total - fc.iva) > p_monto_minimo OR p_monto_minimo = 0)
                              GROUP BY x1.bodega, fd.fecha
                              --HAVING SUM(fd.total_precio) > p_monto_minimo
                              ORDER BY x1.bodega, fd.fecha)
        SELECT x.fecha,
               p_periodo              AS periodo,
               p_monto_minimo         AS monto_minimo,
               v_descripciones[1]     AS bodega_1,
               pr1.num_transacciones  AS num_transacciones_1,
               pr1.total_venta        AS total_venta_1,
               v_descripciones[2]     AS bodega_2,
               pr2.num_transacciones  AS num_transacciones_2,
               pr2.total_venta        AS total_venta_2,
               v_descripciones[3]     AS bodega_3,
               pr3.num_transacciones  AS num_transacciones_3,
               pr3.total_venta        AS total_venta_3,
               v_descripciones[4]     AS bodega_4,
               pr4.num_transacciones  AS num_transacciones_4,
               pr4.total_venta        AS total_venta_4,
               v_descripciones[5]     AS bodega_5,
               pr5.num_transacciones  AS num_transacciones_5,
               pr5.total_venta        AS total_venta_5,
               v_descripciones[6]     AS bodega_6,
               pr6.num_transacciones  AS num_transacciones_6,
               pr6.total_venta        AS total_venta_6,
               v_descripciones[7]     AS bodega_7,
               pr7.num_transacciones  AS num_transacciones_7,
               pr7.total_venta        AS total_venta_7,
               v_descripciones[8]     AS bodega_8,
               pr8.num_transacciones  AS num_transacciones_8,
               pr8.total_venta        AS total_venta_8,
               v_descripciones[9]     AS bodega_9,
               pr9.num_transacciones  AS num_transacciones_9,
               pr9.total_venta        AS total_venta_9,
               v_descripciones[10]    AS bodega_10,
               pr10.num_transacciones AS num_transacciones_10,
               pr10.total_venta       AS total_venta_10
        FROM (SELECT GENERATE_SERIES(
                             DATE_TRUNC('month', TO_DATE(p_periodo, 'YYYYMM')),
                             DATE_TRUNC('month', TO_DATE(p_periodo, 'YYYYMM')) + INTERVAL '1 month' - INTERVAL '1 day',
                             '1 day')::date AS fecha) AS x
                 LEFT JOIN ventas_netas AS pr1 ON pr1.fecha = x.fecha AND pr1.bodega = v_bodegas[1]
                 LEFT JOIN ventas_netas AS pr2 ON pr2.fecha = x.fecha AND pr2.bodega = v_bodegas[2]
                 LEFT JOIN ventas_netas AS pr3 ON pr3.fecha = x.fecha AND pr3.bodega = v_bodegas[3]
                 LEFT JOIN ventas_netas AS pr4 ON pr4.fecha = x.fecha AND pr4.bodega = v_bodegas[4]
                 LEFT JOIN ventas_netas AS pr5 ON pr5.fecha = x.fecha AND pr5.bodega = v_bodegas[5]
                 LEFT JOIN ventas_netas AS pr6 ON pr6.fecha = x.fecha AND pr6.bodega = v_bodegas[6]
                 LEFT JOIN ventas_netas AS pr7 ON pr7.fecha = x.fecha AND pr7.bodega = v_bodegas[7]
                 LEFT JOIN ventas_netas AS pr8 ON pr8.fecha = x.fecha AND pr8.bodega = v_bodegas[8]
                 LEFT JOIN ventas_netas AS pr9 ON pr9.fecha = x.fecha AND pr9.bodega = v_bodegas[9]
                 LEFT JOIN ventas_netas AS pr10 ON pr10.fecha = x.fecha AND pr10.bodega = v_bodegas[10];
END
$function$
;

