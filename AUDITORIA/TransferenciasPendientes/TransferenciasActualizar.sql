-- DROP FUNCTION puntos_venta.incidencias_cambiar_estado_noautorizado(in int4, in varchar, in varchar, out text);

CREATE OR REPLACE FUNCTION control_inventarios.transferencia_quitar_pendiente(p_transferencia varchar,
                                                                              p_usuario varchar,
                                                                              OUT respuesta text)
    RETURNS text
    LANGUAGE plpgsql
AS
$function$
BEGIN

    UPDATE control_inventarios.transacciones
    SET recepcion_completa = TRUE
    WHERE transaccion = p_transferencia
      AND tipo_movimiento = 'TRANSFER+';

    IF FOUND THEN
        PERFORM *
        FROM sistema.interface_creacion(CAST(LOCALTIME(0) AS VARCHAR), p_usuario, 'LINUX',
                                        'PTO.VENTA', 'NO',
                                        'REPLACE REST rectrnffin WITH .t. WHILE ttranno =[' ||
                                        LPAD(p_transferencia, 10, ' ') || '] FOR trantyp=[TR]',
                                        TO_CHAR(CURRENT_DATE, 'YYYY-MM-DD'), '', 'UPDATE', 'V:\sbtpro\icdata\ ',
                                        'ictran01',
                                        '=SEEK("' || LPAD(p_transferencia, 10, ' ') || '","ictran01","ttranno")', '',
                                        '');
    END IF;
    /****************/
    respuesta = 'OK';
    /****************/
END;
$function$
;
