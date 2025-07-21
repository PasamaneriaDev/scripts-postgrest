CREATE OR REPLACE FUNCTION puntos_venta.requerimientos_existencias_item(p_item varchar,
                                                                        OUT o_existencias numeric)
    RETURNS numeric
    LANGUAGE plpgsql
AS
$function$
DECLARE
    v_bodegas varchar;
BEGIN
    SELECT p.alfa
    INTO v_bodegas
    FROM sistema.parametros p
    WHERE p.modulo_id = 'PVENTAS'
      AND p.codigo = 'BODEGAS_REQUERIMIENTOS';

    v_bodegas = '{' || v_bodegas || '}';

    SELECT SUM(b.existencia) AS existencia
    INTO o_existencias
    FROM control_inventarios.bodegas b
    WHERE b.bodega = ANY (v_bodegas::TEXT[])
      AND item = p_item;
END;
$function$
;
