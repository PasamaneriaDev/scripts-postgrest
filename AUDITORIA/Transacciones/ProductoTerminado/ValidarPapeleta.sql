-- DROP FUNCTION auditoria.papeleta_validar_documento_toma_terminado(p_numero_papeleta varchar)

CREATE OR REPLACE FUNCTION auditoria.papeleta_buscar_documento_toma_terminado(p_numero_papeleta varchar)
    RETURNS TABLE
            (
                numero_papeleta   varchar,
                fecha             date,
                bodega            character varying,
                ubicacion         character varying,
                bloqueado_por     varchar,
                es_almacen_saldos boolean
            )
    LANGUAGE plpgsql
AS
$function$
DECLARE
BEGIN
    RETURN QUERY
        SELECT pi.numero_papeleta, pi.fecha, pi.bodega, pi.ubicacion, pi.bloqueado_por, ib.es_almacen_saldos
        FROM auditoria.papeletas_inventario pi
                 LEFT JOIN control_inventarios.id_bodegas ib ON ib.bodega = pi.bodega
        WHERE pi.numero_papeleta = LPAD(p_numero_papeleta, 10, '0');
END;
$function$
;


