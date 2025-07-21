-- DROP FUNCTION auditoria.inventario_herramienta_eliminar_fnc(varchar);

CREATE OR REPLACE FUNCTION auditoria.inventario_herramienta_eliminar_fnc(p_codigo_documento character varying, p_eliminar boolean)
    RETURNS void
    LANGUAGE plpgsql
AS
$function$

BEGIN

    UPDATE auditoria.cabecera_inventario_herramienta
    SET eliminado = p_eliminar
    WHERE codigo_documento = p_codigo_documento;

    -- ACTUALIZAMOS LOS DETALLES EXISTENTES
    UPDATE auditoria.detalle_inventario_herramienta
    SET eliminado = p_eliminar
    WHERE codigo_documento = p_codigo_documento;


END ;
$function$
;



