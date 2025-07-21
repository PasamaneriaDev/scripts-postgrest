/*
drop function trabajo_proceso.ordenes_rollos_actualiza_peso_crudo(p_cod_orden_rollo varchar,
                                                                               p_peso_crudo numeric,
                                                                               p_usuario varchar)
*/

CREATE OR REPLACE FUNCTION trabajo_proceso.ordenes_rollos_actualiza_peso_crudo(p_cod_orden_rollo varchar,
                                                                               p_peso_crudo numeric,
                                                                               p_tonalidad varchar,
                                                                               p_observacion varchar,
                                                                               p_usuario varchar)
    RETURNS VOID
    LANGUAGE plpgsql
AS
$function$
BEGIN
    UPDATE trabajo_proceso.ordenes_rollos_detalle
    SET peso_crudo             = p_peso_crudo,
        tonalidad              = p_tonalidad,
        fecha_pesado_crudo     = CURRENT_TIMESTAMP,
        observacion_pesa_crudo = p_observacion,
        usuario_pesa_crudo     = p_usuario
    WHERE codigo_orden = LEFT(p_cod_orden_rollo, LENGTH(p_cod_orden_rollo) - 3)
      AND numero_rollo = RIGHT(p_cod_orden_rollo, 3);
END;
$function$
;
