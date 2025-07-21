-- DROP FUNCTION control_inventarios.bodega_fecha_conteo_grabado_fnc(text, date);

CREATE OR REPLACE FUNCTION control_inventarios.bodega_fecha_conteo_grabado_fnc(p_bodega text, p_fecha date)
    RETURNS boolean
    LANGUAGE plpgsql
AS
$function$

DECLARE
    _bodega TEXT[] = '{' || p_bodega || '}';

BEGIN

    IF (SELECT i.es_almacen_saldos
        FROM control_inventarios.id_bodegas i
        WHERE i.bodega = p_bodega) THEN
        WITH t
                 AS
                 (SELECT ('{' || bodega || ',' || bodega_primera || '}')::TEXT[] bodega
                  FROM sistema.parametros_almacenes
                  WHERE bodega_primera <> ''
                    AND terminal = '01')
        SELECT t.bodega
        INTO _bodega
        FROM t
        WHERE ARRAY [p_bodega] <@ t.bodega;

    END IF;

    RETURN
        EXISTS(SELECT 1
               FROM control_inventarios.bodegas b
               WHERE b.bodega = ANY (_bodega)
                 AND b.fecha_conteo = p_fecha
                 AND b.conteo_grabado);

END;
$function$
;
