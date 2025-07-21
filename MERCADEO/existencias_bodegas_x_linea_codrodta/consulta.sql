
CREATE OR REPLACE FUNCTION control_inventarios.existenacias_bodega_x_linea_codrotacion_temp(respuesta OUT varchar)
    RETURNS varchar
    LANGUAGE plpgsql
AS
$function$
DECLARE
    codigo_rotacion text;
    col_sum         text = '';
    tot_sum         text = '';
    col_fin         text = '';
    sum_fin         text = '';
    tot_fin         text = '';
    where_f         text = '';
    query           text;
BEGIN
    -- Obtener todas las combinaciones únicas de linea y codigo_rotacion
    FOR codigo_rotacion IN
        SELECT c.codigo
        FROM lista_materiales.codigos_rotacion c
        WHERE NOT c.anulado
        ORDER BY c.codigo
        LOOP
            col_sum := col_sum || FORMAT(
                    'SUM(CASE WHEN e.codigo_rotacion = %L THEN (e.existencia + e.transito) * e.costo_promedio ELSE 0 END) AS %s, ',
                    codigo_rotacion, codigo_rotacion);
            col_sum := col_sum || FORMAT(
                    '(SUM(CASE WHEN e.codigo_rotacion = %L THEN (e.existencia + e.transito) * e.costo_promedio ELSE 0 END) / max(t.%s)) * 100 AS %s, ',
                    codigo_rotacion, codigo_rotacion || '_total', 'porc_' || codigo_rotacion);
            tot_sum := tot_sum || FORMAT(
                    'SUM(CASE WHEN e.codigo_rotacion = %L THEN (e.existencia + e.transito) * e.costo_promedio ELSE 0 END) AS %s, ',
                    codigo_rotacion, codigo_rotacion || '_total');
            col_fin := col_fin || FORMAT('%s, %s, ', 'f.' || codigo_rotacion, 'f.porc_' || codigo_rotacion);
            tot_fin := tot_fin || FORMAT('sum(%s), sum(%s), ', 'f.' || codigo_rotacion, 'f.porc_' || codigo_rotacion);
            sum_fin := sum_fin || FORMAT('%s + ', 'f.' || codigo_rotacion);
            where_f := where_f || FORMAT('%s <> 0 or ', 'f.' || codigo_rotacion);
        END LOOP;

    -- Remover la última coma y espacio
    col_sum := LEFT(col_sum, LENGTH(col_sum) - 2);
    tot_sum := LEFT(tot_sum, LENGTH(tot_sum) - 2);
    col_fin := LEFT(col_fin, LENGTH(col_fin) - 2);
    sum_fin := LEFT(sum_fin, LENGTH(sum_fin) - 2);
    tot_fin := LEFT(tot_fin, LENGTH(tot_fin) - 2);
    where_f := LEFT(where_f, LENGTH(where_f) - 3);

    respuesta := 'temp_exist_bod_x_lin_codrot';
    -- Construir la consulta dinámica
    query := FORMAT('
        DROP TABLE IF EXISTS ' || respuesta || ';
        create temp table ' || respuesta || ' as (
        WITH existencia AS (SELECT i.linea,
                           i.codigo_rotacion,
                           b.existencia,
                           i.costo_promedio,
                           b.transito,
                           LEFT(i.item, 1) AS digito
                    FROM control_inventarios.bodegas b
                             JOIN control_inventarios.items i ON b.item = i.item
                             JOIN control_inventarios.id_bodegas ib ON b.bodega = ib.bodega
                    WHERE b.existencia <> 0
                      AND i.es_fabricado
                      AND i.es_vendible
                      AND LEFT(ib.descripcion, 6) = ''Bodega''
                    ORDER BY LEFT(i.item, 1)),
        totales as (SELECT %s
                FROM existencia e),
        final as (SELECT e.digito as seccion, e.linea, %s
                  FROM existencia e, totales t
                  GROUP BY e.linea, e.digito
		          order by e.digito, e.linea),
		total_f as (Select ''''::text as seccion, ''TOTAL GENERAL''::text as linea, %s, sum(%s)
				    from final f)
        (select s.seccion as seccion, f.linea, %s, %s as total_general
        from final f left join control_inventarios.item_seccion s on f.seccion = s.codigo
        where %s)
		UNION ALL
		(select * from total_f));', tot_sum, col_sum, tot_fin, sum_fin, col_fin, sum_fin, where_f);

    EXECUTE query;
END;
$function$
;
