-- DROP FUNCTION auditoria.papeleta_validar_documento_toma(p_numero_papeleta varchar, p_bodega varchar, p_ubicacion varchar)

CREATE OR REPLACE FUNCTION auditoria.papeleta_validar_documento_toma_proceso(p_numero_papeleta varchar, p_bodega varchar, p_ubicacion varchar)
    RETURNS TABLE
            (
                numero_papeleta varchar,
                fecha           date,
                bodega          character varying,
                ubicacion       character varying,
                bloqueado_por   varchar
            )
    LANGUAGE plpgsql
AS
$function$
DECLARE
BEGIN
    RETURN QUERY
        SELECT pi.numero_papeleta, pi.fecha, pi.bodega, pi.ubicacion, pi.bloqueado_por
        FROM auditoria.papeletas_inventario pi
        WHERE pi.numero_papeleta = LPAD(p_numero_papeleta, 10, '0')
          AND pi.bodega = p_bodega
          AND ((p_bodega <> '1C' OR p_bodega <> 'B4') OR pi.ubicacion = p_ubicacion);
END;
$function$
;


