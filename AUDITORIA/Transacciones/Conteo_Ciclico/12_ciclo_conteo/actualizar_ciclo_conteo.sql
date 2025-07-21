-- DROP FUNCTION control_inventarios.ciclo_conteo_no_se_cuenta_grabar_fnc(text, date, date, text);

CREATE OR REPLACE FUNCTION control_inventarios.ciclo_conteo_no_se_cuenta_grabar_fnc(p_usuario text, p_fecha_inicial date, p_fecha_final date, p_data text)
    RETURNS void
    LANGUAGE plpgsql
AS
$function$

DECLARE
    _interface_activo BOOLEAN := TRUE;

BEGIN

    SELECT p_interface_activo
    INTO _interface_activo
    FROM sistema.interface_modulo_activo_fnc('trabajo_proceso');

    DROP TABLE IF EXISTS ciclo_conteo_tmp, resultado_tmp;

    CREATE TEMP TABLE ciclo_conteo_tmp
    AS
    SELECT t.fecha::DATE AS fecha, s.bodega, s.tipo, s.motivo
    FROM JSON_TO_RECORDSET(p_data::json) AS s (bodega VARCHAR(3), tipo TEXT, motivo TEXT)
             CROSS JOIN
         GENERATE_SERIES(p_fecha_inicial, p_fecha_final, '1 day'::interval) t (fecha);

    CREATE TEMP TABLE resultado_tmp
    AS
    WITH conteo_update
             AS (SELECT ct.fecha
                      , CASE WHEN t.bodega IS NULL THEN ct.bodega_origen ELSE t.bodega || t.tipo END          AS bodega
                      , CASE WHEN t.bodega IS NULL THEN '' ELSE t.bodega || ':' || COALESCE(t.motivo, '') END AS motivo
                 FROM (--Genera filas por cada bodega dentro de no_se_cuenta (022N,150N,320N,420N,224N,226D)
                          SELECT c.fecha,
                                 REGEXP_SPLIT_TO_TABLE(COALESCE(c.no_se_cuenta, ''), ',') AS bodega_origen --split no_se_cuenta
                          FROM control_inventarios.ciclo_conteo c
                          WHERE c.fecha BETWEEN p_fecha_inicial AND p_fecha_final) ct
                          LEFT JOIN -- conservo todos los ciclos de conteo para formar cadena y actualizar
                     ciclo_conteo_tmp t ON ct.fecha = t.fecha AND LEFT(ct.bodega_origen, 3) = t.bodega),
         conteo_insert
             AS (SELECT t.fecha, t.bodega || t.tipo AS bodega, t.bodega || ':' || t.motivo AS motivo
                 FROM ciclo_conteo_tmp t
                          LEFT JOIN
                      conteo_update cu ON t.fecha = cu.fecha AND t.bodega = LEFT(cu.bodega, 3)
                 WHERE cu.bodega IS NULL),
         conteo_para_agrupar
             AS (SELECT cu.fecha, cu.bodega, cu.motivo
                 FROM conteo_update cu
                 UNION
                 SELECT ci.fecha, ci.bodega, ci.motivo
                 FROM conteo_insert ci)
    SELECT conteo_para_agrupar.fecha --, conteo_para_agrupar.bodega, conteo_para_agrupar.motivo
         , STRING_AGG(conteo_para_agrupar.bodega, ',' ORDER BY conteo_para_agrupar.bodega) AS no_se_cuenta
         , STRING_AGG(CASE WHEN conteo_para_agrupar.motivo = '' THEN NULL ELSE conteo_para_agrupar.motivo END, '.'
                      ORDER BY conteo_para_agrupar.bodega)                                 AS motivo
    FROM conteo_para_agrupar
    WHERE conteo_para_agrupar.bodega <> ''
    GROUP BY conteo_para_agrupar.fecha;

    -- WITH interface_tmp
    --          AS
    --          (
    UPDATE control_inventarios.ciclo_conteo c
    SET no_se_cuenta = t.no_se_cuenta
      , referencia   = COALESCE(c.referencia, '') ||
                       CASE WHEN c.referencia IS DISTINCT FROM NULL THEN '.' ELSE '' END || t.motivo
    FROM resultado_tmp t
    WHERE c.fecha = t.fecha;
    --RETURNING c.fecha, c.no_se_cuenta, c.referencia
    --          )
    -- INSERT
    -- INTO sistema.interface
    --     (usuarios, modulo, proceso, directorio, tabla, buscar, sql)
    -- SELECT p_usuario
    --      , 'AUDITORIA'
    --      , 'UPDATE1'
    --      , 'v:\sbtpro\icdata\ '
    --      , 'ICCONT01'
    --      , ''
    --      , 'Update v:\sbtpro\icdata\ICCONT01 ' ||
    --        'Set nosecuenta = [' || REPLACE(interface_tmp.no_se_cuenta, ',', '.') || '], ref = [' ||
    --        interface_tmp.referencia || '] '
    --            'Where fecha = {^' || TO_CHAR(interface_tmp.fecha, 'YYYY-MM-DD') || '}'
    -- FROM interface_tmp
    -- WHERE _interface_activo;

--DROP TABLE IF EXISTS ciclo_conteo_tmp, resultado_tmp;

END;
$function$
;
