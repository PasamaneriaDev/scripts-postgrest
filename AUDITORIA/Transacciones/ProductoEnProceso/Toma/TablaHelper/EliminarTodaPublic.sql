-- DROP FUNCTION control_inventarios.ajuste_costo_grabar_fnc(varchar, bool, text);

CREATE OR REPLACE FUNCTION control_inventarios.ajuste_toma_prod_proc_eliminar_resp(p_computador varchar, p_usuario varchar, p_documento varchar)
    RETURNS void
    LANGUAGE plpgsql
AS
$function$
BEGIN
    DELETE
    FROM inventario_proceso.toma_producto_proceso_preliminar
    where computador = p_computador
      AND usuario = p_usuario
      AND documento = p_documento;
END ;
$function$
;
