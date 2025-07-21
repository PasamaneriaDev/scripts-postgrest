-- DROP FUNCTION control_inventarios.conteo_fisico_grabar_fnc(text, text, text);

CREATE OR REPLACE FUNCTION control_inventarios.conteo_fisico_grabar_fnc(p_usuario text, p_diferencia_json text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$

DECLARE
    _interface_activo BOOLEAN := TRUE;

BEGIN

    SELECT p_interface_activo
    INTO _interface_activo
    FROM sistema.interface_modulo_activo_fnc('trabajo_proceso');

    WITH t
             AS (SELECT j.bodega, j.item, j.conteo
                 FROM JSON_TO_RECORDSET(p_diferencia_json::json) AS j (item TEXT, bodega text, conteo NUMERIC(13, 3)))
    UPDATE control_inventarios.bodegas b
    SET fisico_conteo    = t.conteo,
        auditoria_conteo = TRUE
    FROM t
    WHERE b.bodega = t.bodega
      AND b.item = t.item;
    -- RETURNING b.bodega, b.item, b.fisico_conteo, b.auditoria_conteo)
    -- INSERT
    -- INTO sistema.interface
    --     (usuarios, modulo, proceso, directorio, tabla, buscar, sql)
    -- SELECT p_usuario
    --      , 'TRABAJO_PROCESO'
    --      , 'UPDATE1'
    --      , 'v:\sbtpro\icdata\ '
    --      , 'ICILOC01'
    --      , ''
    --      , 'Update v:\sbtpro\icdata\ICILOC01 ' ||
    --        'Set fisicconte = ' || s.fisico_conteo::VARCHAR || ', auditconte = .T. ' ||
    --        'Where LOCTID+ITEM = [' || RPAD(s.bodega, 3, ' ') || RPAD(s.item, 15, ' ') || ']'
    -- FROM s
    -- WHERE _interface_activo;

END;
$function$
;
