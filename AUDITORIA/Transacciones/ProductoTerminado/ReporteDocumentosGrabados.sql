-- drop function auditoria.reporte_tomas_terminados_grabadas(p_bodega varchar, p_ubicacion varchar);

CREATE OR REPLACE FUNCTION auditoria.reporte_tomas_terminados_grabadas(p_bodega varchar, p_ubicacion varchar)
    RETURNS TABLE
            (
                documento CHARACTER VARYING,
                item      CHARACTER VARYING,
                orden     CHARACTER VARYING,
                cantidad  NUMERIC,
                bodega    CHARACTER VARYING,
                ubicacion CHARACTER VARYING
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    RETURN QUERY
        SELECT a.documento,
               a.item,
               a.orden,
               a.cantidad,
               a.bodega,
               a.ubicacion
        FROM control_inventarios.ajustes a
        WHERE a.status <> 'V'
          AND a.tipo = 'T'
          AND a.bodega = p_bodega
          AND (p_ubicacion = '' OR a.ubicacion = p_ubicacion)
          AND a.muestra IS NULL;
END
$function$
;