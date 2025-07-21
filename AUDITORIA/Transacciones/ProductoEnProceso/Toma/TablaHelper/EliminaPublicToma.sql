-- DROP FUNCTION control_inventarios.ajuste_costo_grabar_fnc(varchar, bool, text);

CREATE OR REPLACE FUNCTION control_inventarios.ajuste_toma_prod_proc_eliminar_resp_by_id(p_secuencia integer)
    RETURNS void
    LANGUAGE plpgsql
AS
$function$
BEGIN
    DELETE
    FROM inventario_proceso.toma_producto_proceso_preliminar
    WHERE id_public = p_secuencia;
END ;
$function$
;
