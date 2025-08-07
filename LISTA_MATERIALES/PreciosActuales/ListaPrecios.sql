CREATE OR REPLACE FUNCTION lista_materiales.precios_actuales_temp(p_data_js text)
    RETURNS void
    LANGUAGE plpgsql
AS
$function$
DECLARE
    v_data          record;
    v_empaque_metro numeric;
    v_iva           numeric;
BEGIN
    SELECT COALESCE(x.precio_por_empaque, FALSE) AS precio_por_empaque,
           COALESCE(x.item_inicial, '1')         AS item_inicial,
           COALESCE(x.item_final, '9')           AS item_final,
           COALESCE(x.porcentaje_dolares, 0)     AS porcentaje_dolares
    INTO v_data
    FROM JSON_TO_RECORD(p_data_js::json) AS x(
                                              precio_por_empaque boolean,
                                              item_inicial text,
                                              item_final text,
                                              porcentaje_dolares numeric
        );

    SELECT numero
    INTO v_empaque_metro
    FROM sistema.parametros p
    WHERE codigo = 'EMPAQUEMETRO';

    SELECT 1 + numero
    INTO v_iva
    FROM sistema.parametros p
    WHERE p.codigo = 'IVA';

    SET work_mem = '64MB';

    DROP TABLE IF EXISTS temp_precios_grupos;
    CREATE TEMP TABLE temp_precios_grupos AS
    WITH cte_grupos AS (SELECT pg.codigo,
                               pg.unidad_despacho || pg.unidad AS unidad_medida_str,
                               (CASE
                                    WHEN v_data.precio_por_empaque
                                        THEN (CASE
                                                  WHEN pg.unidad = 'MT' OR pg.unidad = 'YD' THEN
                                                      v_empaque_metro
                                                  ELSE pg.unidad_despacho END)
                                    ELSE 1 END)                AS unidad_despacho_opera,
                               pg.unidad,
                               pg.descripcion,
                               pg.x_default,
                               CASE
                                   WHEN pg.x_default THEN SUBSTR(pg.codigo, 1, 7)
                                   ELSE pg.codigo END          AS codigo_busqueda
                        FROM lista_materiales.precios_grupos pg
                        WHERE NOT pg.no_imprimir
                          AND pg.precio_base <> 0
                          AND pg.codigo BETWEEN v_data.item_inicial AND v_data.item_final),
         cte_items AS (SELECT *
                       FROM (SELECT xi.item AS item, v.*
                             FROM cte_grupos v
                                      JOIN LATERAL (SELECT i.item
                                                    FROM control_inventarios.items i
                                                    WHERE i.item LIKE v.codigo_busqueda || '%'
                                                      AND i.codigo_rotacion IN
                                                          ('AA', 'XA', 'AC', 'MM', 'AP', 'PO', 'MA', 'AB', 'AS')
                                                      AND i.codigo_rotacion <> 'XX'
                                                      AND SUBSTRING(i.clase_producto FROM 2 FOR 1) <> 'Z'
                                                      AND LEFT(i.descripcion, 2) <> 'A-'
                                                      AND i.es_vendible
                                                    ORDER BY i.item
                                                    LIMIT 1) xi ON LENGTH(v.codigo) > 8
                             UNION ALL
                             SELECT xi.item AS item, v.*
                             FROM cte_grupos v
                                      JOIN LATERAL (SELECT i.item
                                                    FROM control_inventarios.items i
                                                             LEFT JOIN lista_materiales.precios_grupos pgex ON pgex.codigo = i.item
                                                    WHERE i.item LIKE v.codigo_busqueda || '%'
                                                      AND i.unidad_medida = v.unidad
                                                      AND LEFT(i.item, 7) = LEFT(v.codigo, 7)
                                                      AND (LEFT(i.item, LENGTH(v.codigo)) = v.codigo
                                                        OR (SUBSTRING(i.item FROM 8 FOR 1) = '0' AND v.x_default))
                                                      AND NOT (LEFT(i.item, 1) = '5' AND SUBSTRING(i.item, 14, 1) = 'A')
                                                      AND pgex.codigo IS NULL
                                                      AND i.codigo_rotacion IN
                                                          ('AA', 'XA', 'AC', 'MM', 'AP', 'PO', 'MA', 'AB', 'AS')
                                                      AND i.codigo_rotacion <> 'XX'
                                                      AND SUBSTRING(i.clase_producto FROM 2 FOR 1) <> 'Z'
                                                      AND LEFT(i.descripcion, 2) <> 'A-'
                                                      AND i.es_vendible
                                                    ORDER BY i.item
                                                    LIMIT 1) xi ON LENGTH(v.codigo) <= 8) AS v1)
    SELECT (CASE
                WHEN LENGTH(ci.codigo) > 8 THEN
                    SUBSTR(ci.item, 1, 1) || ' ' || SUBSTR(ci.item, 2, 3) || ' ' || SUBSTR(ci.item, 5, 3) || ' ' ||
                    SUBSTR(ci.item, 8, 8)
                WHEN LENGTH(ci.codigo) = 7 THEN SUBSTR(ci.item, 1, 1) || ' ' || SUBSTR(ci.item, 2, 3) || ' ' ||
                                                SUBSTR(ci.item, 5, 3)
                ELSE SUBSTR(ci.codigo, 1, 1) || ' ' || SUBSTR(ci.codigo, 2, 3) || ' ' || SUBSTR(ci.codigo, 5, 3) ||
                     ' ' || SUBSTR(ci.codigo, 8, 1) END)                        AS talla,
           ci.descripcion,
           ci.unidad_medida_str,
           (CASE
                WHEN v_data.precio_por_empaque
                    THEN control_inventarios.unidades_formato_reporte(ci.unidad, ci.unidad_despacho_opera)
                ELSE ci.unidad END)                                             AS descripción_unidad,
           control_inventarios.precios_actuales_talla_orden(ci.item)            AS talla_orden,
           (COALESCE(p.DIS, 0) * ci.unidad_despacho_opera)                      AS distribuidor,
           (COALESCE(p.MAY, 0) * ci.unidad_despacho_opera)                      AS mayorista,
           (COALESCE(p.MER, 0) * ci.unidad_despacho_opera)                      AS menorista,
           (COALESCE(p.PVP, 0) * ci.unidad_despacho_opera)                      AS pvp,
           (CASE
                WHEN LEFT(ci.codigo, 1) IN ('1', '5') AND ci.unidad NOT IN ('MT', 'PZ')
                    THEN COALESCE(p.PVP_99, 0) * ci.unidad_despacho_opera
                ELSE COALESCE(p.PVP, 0) * v_iva * ci.unidad_despacho_opera END) AS pvp_iva,
           (COALESCE(p.CAD, 0) * ci.unidad_despacho_opera)                      AS cadena,
           (CASE
                WHEN v_data.porcentaje_dolares <> 0
                    THEN COALESCE(p.EXP, 0) * ((v_data.porcentaje_dolares / 100) + 1) * ci.unidad_despacho_opera
                ELSE COALESCE(p.EXP, 0) * ci.unidad_despacho_opera END)         AS exportacion,
           (COALESCE(p.HCE, 0) * ci.unidad_despacho_opera)                      AS hce,
           ci.codigo
    FROM cte_items ci
             JOIN LATERAL (SELECT MAX(CASE WHEN tipo = 'DIS' THEN pi.precio END) AS DIS,
                                  MAX(CASE WHEN tipo = 'MAY' THEN pi.precio END) AS MAY,
                                  MAX(CASE WHEN tipo = 'MER' THEN pi.precio END) AS MER,
                                  MAX(CASE WHEN tipo = 'PVP' THEN pi.precio END) AS PVP,
                                  MAX(CASE WHEN tipo = 'PVP' THEN pi.pvp_99 END) AS PVP_99,
                                  MAX(CASE WHEN tipo = 'CAD' THEN pi.precio END) AS CAD,
                                  MAX(CASE WHEN tipo = 'EXP' THEN pi.precio END) AS EXP,
                                  MAX(CASE WHEN tipo = 'HCE' THEN pi.precio END) AS HCE
                           FROM control_inventarios.precios pi
                           WHERE pi.item = ci.item) p ON TRUE
    WHERE COALESCE(ci.item, '') <> ''
      AND (p.DIS <> 0
        OR p.MAY <> 0
        OR p.MER <> 0
        OR p.PVP <> 0
        OR p.CAD <> 0
        OR p.EXP <> 0
        OR p.HCE <> 0)
    ORDER BY talla_orden;
END;
$function$
;
