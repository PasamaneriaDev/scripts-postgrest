-- drop FUNCTION ordenes_venta.pedidos_usuario_modifica_cabecera(p_codigo_usuario VARCHAR)

CREATE OR REPLACE FUNCTION sistema.usuario_tiene_acceso_rapido(p_codigo_usuario VARCHAR, p_opcion varchar, OUT tiene_acceso BOOLEAN)
    RETURNS BOOLEAN
    LANGUAGE plpgsql
AS
$function$
DECLARE
BEGIN
    tiene_acceso = FALSE;

    IF p_opcion = 'Consulta de Items' THEN
        tiene_acceso = TRUE;

    ELSIF p_opcion = 'Datos Trabajadores' OR p_opcion = 'Consulta Asistencia' THEN
        tiene_acceso = EXISTS(SELECT 1
                              FROM sistema.accesos_ventana_accion
                              WHERE (usuario_id, ventana_accion) = (p_codigo_usuario, p_opcion));
    END IF;
END;
$function$;


select tiene_acceso from
    sistema.usuario_tiene_acceso_rapido('1333', 'Datos Trabajadores');