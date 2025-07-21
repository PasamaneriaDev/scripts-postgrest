-- DROP FUNCTION control_inventarios.conteo_fisico_almacen_diferencia_fnc(text, date);

CREATE OR REPLACE FUNCTION control_inventarios.conteo_fisico_almacen_diferencia_fnc(p_bodega text, p_fecha date)
    RETURNS TABLE
            (
                bodega        character varying,
                item          character varying,
                descripcion   character varying,
                fecha_conteo  date,
                corte_conteo  numeric,
                fisico_conteo numeric
            )
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
                 (SELECT ('{' || p.bodega || ',' || p.bodega_primera || '}')::TEXT[] bodega
                  FROM sistema.parametros_almacenes p
                  WHERE p.bodega_primera <> ''
                    AND p.terminal = '01')
        SELECT t.bodega
        INTO _bodega
        FROM t
        WHERE ARRAY [p_bodega] <@ t.bodega;

    END IF;

    RETURN QUERY
        SELECT b.bodega, b.item, i.descripcion, b.fecha_conteo, b.corte_conteo, b.fisico_conteo
        FROM control_inventarios.bodegas b
                 INNER JOIN
             control_inventarios.items i ON b.item = i.item
        WHERE b.bodega = ANY (_bodega)
          AND b.fecha_conteo = p_fecha
          AND b.corte_conteo <> b.fisico_conteo
          AND b.conteo_grabado
          AND b.auditoria_conteo = FALSE
        ORDER BY b.bodega, b.item;

END;
$function$
;
