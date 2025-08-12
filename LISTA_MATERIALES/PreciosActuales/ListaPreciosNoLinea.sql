-- drop function lista_materiales.precios_no_linea_temp(p_data_js text);

CREATE OR REPLACE FUNCTION lista_materiales.precios_actuales_no_linea_temp(p_data_js text)
    RETURNS void
    LANGUAGE plpgsql
AS
$function$
DECLARE
    v_data          record;
    v_iva           numeric;
    v_empaque_metro numeric;
BEGIN
    SELECT COALESCE(x.precio_por_empaque, FALSE)     AS precio_por_empaque,
           COALESCE(NULLIF(x.item_inicial, ''), '1') AS item_inicial,
           COALESCE(NULLIF(x.item_final, ''), '9')   AS item_final,
           COALESCE(x.porcentaje_dolares, 0)         AS porcentaje_dolares,
           COALESCE(x.tipo_item, 'O')                AS tipo_item,
           COALESCE(x.existencia, 0)                 AS existencia
    INTO v_data
    FROM JSON_TO_RECORD(p_data_js::json) AS x(
                                              precio_por_empaque boolean,
                                              item_inicial text,
                                              item_final text,
                                              porcentaje_dolares numeric,
                                              tipo_item text, -- O = 'NO LINEA/OBSOLETO', E = 'ESPECIAL'
                                              existencia numeric
        );

    SELECT 1 + numero
    INTO v_iva
    FROM sistema.parametros p
    WHERE p.codigo = 'IVA';

    SET work_mem = '64MB';

    DROP TABLE IF EXISTS temp_items_precios_grupos;
    IF v_data.tipo_item = 'O' THEN
        CREATE TEMP TABLE temp_items_precios_grupos AS
        SELECT i.item, i.descripcion, i.unidad_medida, i.unidad_despacho
        FROM control_inventarios.items i
        WHERE i.item BETWEEN v_data.item_inicial AND v_data.item_final
          AND i.existencia >= v_data.existencia
          AND (i.codigo_rotacion IN ('OO', 'XX')
            OR SUBSTRING(i.clase_producto FROM 2 FOR 1) = 'Z'
            OR SUBSTRING(i.descripcion FROM 1 FOR 2) = 'A-');
    ELSE
        CREATE TEMP TABLE temp_items_precios_grupos AS
        SELECT i.item, i.descripcion, i.unidad_medida, i.unidad_despacho
        FROM control_inventarios.items i
        WHERE i.item BETWEEN v_data.item_inicial AND v_data.item_final
          AND i.existencia >= v_data.existencia
          AND (i.codigo_rotacion = 'EE');
    END IF;

    DROP TABLE IF EXISTS temp_precios_grupos;
    CREATE TEMP TABLE temp_precios_grupos AS
    WITH cte_items AS (SELECT (r.unidad_despacho::int || r.unidad_medida) AS unidad_despacho_str,
                              (CASE
                                   WHEN v_data.precio_por_empaque
                                       THEN (CASE
                                                 WHEN r.unidad_medida = 'MT' OR r.unidad_medida = 'YD'
                                                     THEN
                                                     v_empaque_metro
                                                 ELSE r.unidad_despacho END)
                                   ELSE 1 END)                            AS unidad_despacho_opera,
                              r.item,
                              r.descripcion,
                              r.unidad_medida                             AS unidad
                       FROM temp_items_precios_grupos r),
         cte_lista_no_linea AS (SELECT ci.item                                                      AS talla,
                                       ci.descripcion,
                                       ci.unidad_despacho_str,
                                       (CASE
                                            WHEN v_data.precio_por_empaque
                                                THEN control_inventarios.unidades_formato_reporte(ci.unidad,
                                                                                                  ci.unidad_despacho_opera)
                                            ELSE ci.unidad END)                                     AS descripción_unidad,
                                       control_inventarios.precios_actuales_talla_orden(ci.item)    AS talla_orden,
                                       (COALESCE(p.DIS, 0) * ci.unidad_despacho_opera)              AS distribuidor,
                                       (COALESCE(p.MAY, 0) * ci.unidad_despacho_opera)              AS mayorista,
                                       (COALESCE(p.MER, 0) * ci.unidad_despacho_opera)              AS mercantil,
                                       (COALESCE(p.PVP, 0) * ci.unidad_despacho_opera)              AS pvp,
                                       (COALESCE(p.CAD, 0) * ci.unidad_despacho_opera)              AS cadena,
                                       (CASE
                                            WHEN v_data.porcentaje_dolares <> 0
                                                THEN COALESCE(p.EXP, 0) * ((v_data.porcentaje_dolares / 100) + 1) *
                                                     ci.unidad_despacho_opera
                                            ELSE COALESCE(p.EXP, 0) * ci.unidad_despacho_opera END) AS exportacion,
                                       (COALESCE(p.HCE, 0) * ci.unidad_despacho_opera)              AS hce
                                FROM cte_items ci
                                         JOIN LATERAL (SELECT COALESCE(MAX(CASE WHEN tipo = 'DIS' THEN pi.precio END), 0) AS DIS,
                                                              COALESCE(MAX(CASE WHEN tipo = 'MAY' THEN pi.precio END), 0) AS MAY,
                                                              COALESCE(MAX(CASE WHEN tipo = 'MER' THEN pi.precio END), 0) AS MER,
                                                              COALESCE(MAX(CASE WHEN tipo = 'PVP' THEN pi.precio END), 0) AS PVP,
                                                              COALESCE(MAX(CASE WHEN tipo = 'CAD' THEN pi.precio END), 0) AS CAD,
                                                              COALESCE(MAX(CASE WHEN tipo = 'EXP' THEN pi.precio END), 0) AS EXP,
                                                              COALESCE(MAX(CASE WHEN tipo = 'HCE' THEN pi.precio END), 0) AS HCE
                                                       FROM control_inventarios.precios pi
                                                       WHERE pi.item = ci.item) p ON TRUE
                                WHERE (p.DIS <> 0
                                    OR p.MAY <> 0
                                    OR p.MER <> 0
                                    OR p.PVP <> 0
                                    OR p.CAD <> 0
                                    OR p.EXP <> 0
                                    OR p.HCE <> 0)
                                ORDER BY talla_orden)
    SELECT talla,
           descripcion,
           unidad_despacho_str AS unidad_despacho,
           descripción_unidad,
           distribuidor,
           mayorista,
           mercantil,
           pvp,
           NULL                AS pvp_iva,
           cadena,
           exportacion,
           hce
    FROM cte_lista_no_linea
    ORDER BY talla_orden;
END;
$function$
;
