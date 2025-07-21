CREATE OR REPLACE FUNCTION ordenes_venta.orden_rollo_cerrar_paro_mantenimiento(p_id integer)
    RETURNS void
    LANGUAGE plpgsql
AS
$function$
BEGIN
    UPDATE trabajo_proceso.ordenes_rollos_paros_mantenimiento
    SET fecha_fin = NOW()
    WHERE id_ordenes_rollos_paros_mantenimiento = p_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No se encontró un paro de mantenimiento con el ID %', p_id;
    END IF;
END ;
$function$