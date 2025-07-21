-- drop function auditoria.toma_documento_no_grabado(p_bodega varchar, p_ubicacion varchar)

CREATE OR REPLACE FUNCTION auditoria.reporte_tomas_no_grabadas(p_bodega varchar, p_ubicacion varchar)
    RETURNS TABLE
            (
                documento CHARACTER VARYING,
                ubicacion CHARACTER VARYING
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    RETURN QUERY
        SELECT pi.numero_papeleta, pi.ubicacion
        FROM auditoria.papeletas_inventario pi
                 LEFT JOIN control_inventarios.ajustes aj
                           ON pi.numero_papeleta = aj.documento
                               AND aj.status <> 'V'
        WHERE pi.bodega = p_bodega
          AND (p_ubicacion = '' OR pi.ubicacion = p_ubicacion)
          AND aj.documento IS NULL;
END
$function$
;


