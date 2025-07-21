CREATE OR REPLACE FUNCTION ordenes_venta.orden_rollo_grabar_paro_mantenimiento(p_tipo varchar,
                                                                               p_orden_rollo character varying,
                                                                               p_maquina varchar,
                                                                               p_motivo varchar,
                                                                               p_creacion_usuario varchar)
    RETURNS void
    LANGUAGE plpgsql
AS
$function$
BEGIN
    IF EXISTS(SELECT 1
              FROM trabajo_proceso.ordenes_rollos_paros_mantenimiento pm
              WHERE pm.maquina = p_maquina
                AND pm.fecha_fin IS NULL) THEN
        RAISE EXCEPTION 'La máquina % ya tiene un paro de mantenimiento activo.', p_maquina;
    END IF;

    INSERT INTO trabajo_proceso.ordenes_rollos_paros_mantenimiento (codigo_orden,
                                                                    numero_rollo,
                                                                    tipo,
                                                                    motivo,
                                                                    maquina,
                                                                    creacion_usuario)
    VALUES (nullif(LEFT(p_orden_rollo, LENGTH(p_orden_rollo) - 3), ''),
            nullif(RIGHT(p_orden_rollo, 3), ''),
            p_tipo,
            p_motivo,
            p_maquina,
            p_creacion_usuario);
END ;
$function$