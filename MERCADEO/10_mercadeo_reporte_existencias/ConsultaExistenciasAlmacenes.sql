-- drop function puntos_venta.reporte_existencias_almacenes(p_bodegas varchar[], p_tipo_reporte varchar)

CREATE OR REPLACE FUNCTION puntos_venta.reporte_existencias_almacenes(p_bodegas varchar[], p_tipo_reporte varchar)
    RETURNS TABLE
            (
                grupo          text,
                codigo         varchar,
                bodega_1       text,
                descripcion_1  text,
                total_1        numeric,
                bodega_2       text,
                descripcion_2  text,
                total_2        numeric,
                bodega_3       text,
                descripcion_3  text,
                total_3        numeric,
                bodega_4       text,
                descripcion_4  text,
                total_4        numeric,
                bodega_5       text,
                descripcion_5  text,
                total_5        numeric,
                bodega_6       text,
                descripcion_6  text,
                total_6        numeric,
                bodega_7       text,
                descripcion_7  text,
                total_7        numeric,
                bodega_8       text,
                descripcion_8  text,
                total_8        numeric,
                bodega_9       text,
                descripcion_9  text,
                total_9        numeric,
                bodega_10      text,
                descripcion_10 text,
                total_10       numeric,
                bodega_11      text,
                descripcion_11 text,
                total_11       numeric,
                bodega_12      text,
                descripcion_12 text,
                total_12       numeric,
                bodega_13      text,
                descripcion_13 text,
                total_13       numeric,
                bodega_14      text,
                descripcion_14 text,
                total_14       numeric,
                bodega_15      text,
                descripcion_15 text,
                total_15       numeric
            )
    LANGUAGE plpgsql
AS
$function$
DECLARE
    v_bodegas       text[];
    v_descripciones text[];
    v_grupos        text[];
BEGIN
    -- Convierte el string de bodegas en un array
    v_bodegas := p_bodegas;


    -- Obtiene la descripción de las bodegas
    SELECT ARRAY_AGG(sub.bodega || ' ' || sub.descripcion ORDER BY ord)
    INTO v_descripciones
    FROM (SELECT ib.bodega, ib.descripcion, t.ord
          FROM UNNEST(v_bodegas) WITH ORDINALITY AS t(bodega, ord)
                   JOIN control_inventarios.id_bodegas ib ON t.bodega = ib.bodega) sub;

    -- Condiciona el tipo de reporte
    IF p_tipo_reporte = 'CONFECCIONES' THEN
        v_grupos := '{Confecciones,Calcetines}';
    ELSIF p_tipo_reporte = 'INSUMOS' THEN
        v_grupos := '{Telares,Trenzadoras,Tintoreria,Encajes,Hilos}';
    ELSE
        v_grupos := '{Confecciones,Telares,Trenzadoras,Tintoreria,Calcetines,Encajes,Hilos}';
    END IF;

    RETURN QUERY
        WITH existencias AS (SELECT b.bodega,
                                    r0.descripcion,
                                    CASE
                                        WHEN LEFT(B.ITEM, 1) = '1' THEN 'Confecciones'
                                        WHEN LEFT(B.ITEM, 1) = '2' THEN 'Telares'
                                        WHEN LEFT(B.ITEM, 1) = '3' THEN 'Trenzadoras'
                                        WHEN LEFT(B.ITEM, 1) = '4' THEN 'Tintoreria'
                                        WHEN LEFT(B.ITEM, 1) = '5' THEN 'Calcetines'
                                        WHEN LEFT(B.ITEM, 1) = '6' THEN 'Encajes'
                                        WHEN LEFT(B.ITEM, 1) = 'B' THEN 'Hilos'
                                        ELSE 'OTROS' END grupo,
                                    r1.codigo_rotacion,
                                    SUM(b.existencia)    total_existencia
                             FROM control_inventarios.bodegas b
                                      JOIN control_inventarios.id_bodegas r0
                                           ON r0.bodega = b.bodega
                                               AND r0.es_punto_venta = TRUE
                                      LEFT JOIN control_inventarios.items r1
                                                ON r1.item = b.item
                             WHERE r1.codigo_rotacion IS NOT NULL
                               AND r1.es_vendible
                               AND r1.codigo_rotacion != ''
                               AND b.bodega = ANY (p_bodegas)
                             GROUP BY b.bodega, r0.descripcion, r1.codigo_rotacion, grupo
                             ORDER BY B.BODEGA ASC, grupo, r1.codigo_rotacion ASC)
        SELECT gp.grupo,
               cr.codigo,
               v_bodegas[1]         AS bodega_1,
               v_descripciones[1]   AS descripcion_1,
               r1.total_existencia  AS total_1,
               v_bodegas[2]         AS bodega_2,
               v_descripciones[2]   AS descripcion_2,
               r2.total_existencia  AS total_2,
               v_bodegas[3]         AS bodega_3,
               v_descripciones[3]   AS descripcion_3,
               r3.total_existencia  AS total_3,
               v_bodegas[4]         AS bodega_4,
               v_descripciones[4]   AS descripcion_4,
               r4.total_existencia  AS total_4,
               v_bodegas[5]         AS bodega_5,
               v_descripciones[5]   AS descripcion_5,
               r5.total_existencia  AS total_5,
               v_bodegas[6]         AS bodega_6,
               v_descripciones[6]   AS descripcion_6,
               r6.total_existencia  AS total_6,
               v_bodegas[7]         AS bodega_7,
               v_descripciones[7]   AS descripcion_7,
               r7.total_existencia  AS total_7,
               v_bodegas[8]         AS bodega_8,
               v_descripciones[8]   AS descripcion_8,
               r8.total_existencia  AS total_8,
               v_bodegas[9]         AS bodega_9,
               v_descripciones[9]   AS descripcion_9,
               r9.total_existencia  AS total_9,
               v_bodegas[10]        AS bodega_10,
               v_descripciones[10]  AS descripcion_10,
               r10.total_existencia AS total_10,
               v_bodegas[11]        AS bodega_11,
               v_descripciones[11]  AS descripcion_11,
               r11.total_existencia AS total_11,
               v_bodegas[12]        AS bodega_12,
               v_descripciones[12]  AS descripcion_12,
               r12.total_existencia AS total_12,
               v_bodegas[13]        AS bodega_13,
               v_descripciones[13]  AS descripcion_13,
               r13.total_existencia AS total_13,
               v_bodegas[14]        AS bodega_14,
               v_descripciones[14]  AS descripcion_14,
               r14.total_existencia AS total_14,
               v_bodegas[15]        AS bodega_15,
               v_descripciones[15]  AS descripcion_15,
               r15.total_existencia AS total_15
        FROM (SELECT UNNEST(v_grupos) AS grupo) AS gp
                 CROSS JOIN lista_materiales.codigos_rotacion AS cr
                 LEFT JOIN existencias r1
                           ON r1.bodega = v_bodegas[1] AND r1.grupo = gp.grupo AND r1.codigo_rotacion = cr.codigo
                 LEFT JOIN existencias r2
                           ON r2.bodega = v_bodegas[2] AND r2.grupo = gp.grupo AND r2.codigo_rotacion = cr.codigo
                 LEFT JOIN existencias r3
                           ON r3.bodega = v_bodegas[3] AND r3.grupo = gp.grupo AND r3.codigo_rotacion = cr.codigo
                 LEFT JOIN existencias r4
                           ON r4.bodega = v_bodegas[4] AND r4.grupo = gp.grupo AND r4.codigo_rotacion = cr.codigo
                 LEFT JOIN existencias r5
                           ON r5.bodega = v_bodegas[5] AND r5.grupo = gp.grupo AND r5.codigo_rotacion = cr.codigo
                 LEFT JOIN existencias r6
                           ON r6.bodega = v_bodegas[6] AND r6.grupo = gp.grupo AND r6.codigo_rotacion = cr.codigo
                 LEFT JOIN existencias r7
                           ON r7.bodega = v_bodegas[7] AND r7.grupo = gp.grupo AND r7.codigo_rotacion = cr.codigo
                 LEFT JOIN existencias r8
                           ON r8.bodega = v_bodegas[8] AND r8.grupo = gp.grupo AND r8.codigo_rotacion = cr.codigo
                 LEFT JOIN existencias r9
                           ON r9.bodega = v_bodegas[9] AND r9.grupo = gp.grupo AND r9.codigo_rotacion = cr.codigo
                 LEFT JOIN existencias r10
                           ON r10.bodega = v_bodegas[10] AND r10.grupo = gp.grupo AND r10.codigo_rotacion = cr.codigo
                 LEFT JOIN existencias r11
                           ON r11.bodega = v_bodegas[11] AND r11.grupo = gp.grupo AND r11.codigo_rotacion = cr.codigo
                 LEFT JOIN existencias r12
                           ON r12.bodega = v_bodegas[12] AND r12.grupo = gp.grupo AND r12.codigo_rotacion = cr.codigo
                 LEFT JOIN existencias r13
                           ON r13.bodega = v_bodegas[13] AND r13.grupo = gp.grupo AND r13.codigo_rotacion = cr.codigo
                 LEFT JOIN existencias r14
                           ON r14.bodega = v_bodegas[14] AND r14.grupo = gp.grupo AND r14.codigo_rotacion = cr.codigo
                 LEFT JOIN existencias r15
                           ON r15.bodega = v_bodegas[15] AND r15.grupo = gp.grupo AND r15.codigo_rotacion = cr.codigo
        ORDER BY gp.grupo, cr.codigo;
END
$function$
;

