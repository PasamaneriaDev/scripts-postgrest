-- drop function puntos_venta.reporte_ventas_netas_almacen_condensado_temp(varchar, varchar, numeric, integer);

CREATE OR REPLACE FUNCTION puntos_venta.reporte_ventas_netas_almacen_condensado_temp(
    p_periodo character varying,
    p_bodegas character varying,
    p_monto_minimo numeric,
    p_agrp_vendedor boolean,
    p_num_grupos integer
)
    RETURNS void
    LANGUAGE plpgsql
AS
$function$
DECLARE
    v_bodegas            text[];
    v_descripciones      text[];
    v_bodega_descripcion text;
    v_num_grupos         integer;
    v_sql                text;
    v_select_cols        text    := '';
    v_join_clauses       text    := '';
    v_create_table       text;
    v_rows_by_fecha      integer = 1;
    i                    integer;
BEGIN
    -- Convert the string of bodegas to an array
    v_bodegas := STRING_TO_ARRAY(p_bodegas, ',');

    -- Determine the number of groups
    IF p_num_grupos = 0 THEN
        v_num_grupos := ARRAY_LENGTH(v_bodegas, 1);
    ELSE
        v_num_grupos := p_num_grupos;
    END IF;

    IF p_agrp_vendedor THEN
        v_rows_by_fecha := 5;
    END IF;

    -- Limit the bodegas array to v_num_grupos
    v_bodegas := v_bodegas[1:v_num_grupos];

    -- Get bodega descriptions
    FOR i IN 1..v_num_grupos
        LOOP
            IF i <= ARRAY_LENGTH(v_bodegas, 1) THEN
                SELECT bodega || ' ' || descripcion
                INTO v_bodega_descripcion
                FROM control_inventarios.id_bodegas
                WHERE bodega = v_bodegas[i];
            ELSE
                v_bodega_descripcion := 'N/A';
            END IF;
            v_descripciones := ARRAY_APPEND(v_descripciones, v_bodega_descripcion);
        END LOOP;

    -- Build dynamic column selection and join clauses
    FOR i IN 1..v_num_grupos
        LOOP
            v_select_cols := v_select_cols || FORMAT(
                    ', $4[%s] AS bodega_%s, pr%s.nombre_vendedor AS nombre_vendedor_%s, ' ||
                    'pr%s.num_transacciones AS num_transacciones_%s, pr%s.total_venta AS total_venta_%s',
                    i, i, i, i, i, i, i, i
                                              );
            v_join_clauses := v_join_clauses || FORMAT(
                    ' LEFT JOIN ventas_netas AS pr%s ON pr%s.fecha = x.fecha AND pr%s.bodega = $2[%s] AND pr%s.numero = x.numero ',
                    i, i, i, i, i
                                                );
        END LOOP;

    DROP TABLE IF EXISTS temp_reporte_ventas_netas;
    -- Create temporary table structure
    v_create_table := 'CREATE TEMPORARY TABLE temp_reporte_ventas_netas (
        fecha date' ||
                      (SELECT STRING_AGG(
                                      FORMAT(
                                              ', bodega_%s text, nombre_vendedor_%s text, num_transacciones_%s integer, total_venta_%s numeric',
                                              n, n, n, n
                                      ),
                                      ''
                              )
                       FROM (SELECT GENERATE_SERIES(1, v_num_grupos) AS n) gs) ||
                      ')';

    EXECUTE v_create_table;

    -- Build and execute dynamic query
    v_sql := FORMAT(
            'INSERT INTO temp_reporte_ventas_netas
             WITH ventas_netas AS (
                 SELECT
                     x1.bodega,
                     ROW_NUMBER() OVER (PARTITION BY x1.bodega, fd.fecha ORDER BY fd.fecha) AS numero,
                     CASE
                     WHEN $5 THEN p.apellido_paterno || '' '' || p.nombre1
                     END                                AS                nombre_vendedor,
                     COUNT(DISTINCT fd.referencia)::integer AS num_transacciones,
                     fd.fecha,
                     SUM(ROUND(COALESCE(fd.TOTAL_PRECIO, 0) -
                               COALESCE(fd.valor_descuento_adicional, 0), 2)) AS total_venta
                 FROM puntos_venta.facturas_detalle fd
                 JOIN puntos_venta.facturas_cabecera fc ON fc.referencia = fd.referencia
                 JOIN (
                     SELECT DISTINCT pa.bodega, pa.bodega_primera, cc.subcentro AS descripcion
                     FROM sistema.parametros_almacenes pa
                     JOIN control_inventarios.id_bodegas ib
                         ON pa.bodega = ib.bodega
                         AND COALESCE(pa.bodega_primera, '''') <> ib.bodega
                     LEFT JOIN activos_fijos.centros_costos cc ON cc.codigo = pa.centro_costo
                     WHERE ib.es_punto_venta
                     ) x1 ON x1.bodega = fd.bodega OR x1.bodega_primera = fd.bodega
                 LEFT JOIN roles.personal p
                     ON fd.vendedor = RIGHT(p.codigo, 4)
                     AND LEFT(p.codigo, 1) <> ''F''
                 WHERE fd.periodo = $1
                 AND x1.bodega IN (SELECT UNNEST($2::text[]))
                 AND ((fc.monto_total - fc.iva) > $3 OR $3 = 0)
                 GROUP BY x1.bodega, fd.fecha, nombre_vendedor
                 ORDER BY x1.bodega, fd.fecha, nombre_vendedor
             )
             SELECT
                 x.fecha %s
             FROM (
                 SELECT
                    fechas.fecha,
                    numeros.numero
                 FROM (
                     SELECT GENERATE_SERIES(
                         DATE_TRUNC(''month'', TO_DATE($1, ''YYYYMM'')),
                         DATE_TRUNC(''month'', TO_DATE($1, ''YYYYMM'')) + INTERVAL ''1 month'' - INTERVAL ''1 day'',
                         ''1 day''
                     )::date AS fecha
                 ) fechas
                 CROSS JOIN (
                     SELECT GENERATE_SERIES(1, $6) AS numero
                 ) numeros
             ) AS x
             %s', v_select_cols, v_join_clauses
             );
    RAISE NOTICE 'Executing SQL: %', v_sql;
    EXECUTE v_sql USING p_periodo, v_bodegas, p_monto_minimo, v_descripciones, p_agrp_vendedor, v_rows_by_fecha;

    -- Delete rows where all total_venta columns are 0
    v_sql := 'DELETE FROM temp_reporte_ventas_netas WHERE ' ||
             (SELECT STRING_AGG(FORMAT('coalesce(total_venta_%s,0) = 0', n), ' AND ')
              FROM (SELECT GENERATE_SERIES(1, v_num_grupos) AS n) gs);

    -- Execute the DELETE query
    EXECUTE v_sql;
END
$function$;
