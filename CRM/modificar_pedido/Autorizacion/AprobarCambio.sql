CREATE OR REPLACE FUNCTION ordenes_venta.pedidos_aprobar_cambios(p_datajs character varying, OUT p_mensaje character varying)
    RETURNS character varying
    LANGUAGE plpgsql
AS
$$
DECLARE
    v_registros_actualizados INTEGER;
BEGIN
    -- Actualización y conteo en una sola consulta usando WITH
    WITH updated AS (
        UPDATE ordenes_venta.pedidos_cabecera AS pc
            SET aprobacion_cambio = NOT aprobacion_cambio
            FROM JSON_TO_RECORDSET(p_datajs::JSON) AS j (numero_pedido CHARACTER VARYING)
            WHERE pc.numero_pedido = j.numero_pedido
            RETURNING pc.aprobacion_cambio)
    SELECT COUNT(*) AS total
    INTO v_registros_actualizados
    FROM updated;

    -- Asignar el mensaje de salida
    p_mensaje := 'Registros actualizados: ' || v_registros_actualizados;
END;
$$;


SELECT *
FROM ordenes_venta.pedidos_cabecera
WHERE aprobacion_cambio = TRUE;