CREATE OR REPLACE FUNCTION ordenes_venta.orden_rollo_grabar_produccion(p_orden_rollo character varying,
                                                                       p_orden_hilo character varying,
                                                                       p_operario character varying)
    RETURNS void
    LANGUAGE plpgsql
AS
$function$
BEGIN
    UPDATE trabajo_proceso.ordenes_rollos_detalle
    SET operario_registro_produccion = RIGHT(p_operario, 4), -- Trae el codigo de Roles
        fecha_registro_produccion    = NOW(),
        codigo_orden_hilo            = p_orden_hilo
    WHERE (codigo_orden || numero_rollo) = p_orden_rollo;
END ;
$function$
