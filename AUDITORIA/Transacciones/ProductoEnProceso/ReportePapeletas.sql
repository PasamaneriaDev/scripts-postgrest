-- drop function auditoria.papeletas_produccion_reporte(papeleta_inicial INTEGER, papeleta_final INTEGER)

CREATE OR REPLACE FUNCTION auditoria.papeletas_produccion_reporte(papeleta_inicial varchar, papeleta_final varchar)
    RETURNS TABLE
            (
                numero_papeleta varchar,
                fecha           DATE,
                bodega          CHARACTER VARYING,
                ubicacion       CHARACTER VARYING
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    RETURN QUERY
        SELECT pi.numero_papeleta, pi.fecha, pi.bodega, pi.ubicacion
        FROM auditoria.papeletas_inventario pi
        WHERE pi.numero_papeleta >= lpad(papeleta_inicial, 10, '0')
          AND pi.numero_papeleta <= lpad(papeleta_final, 10, '0');
END;
$function$
;