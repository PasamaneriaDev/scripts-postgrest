-- DROP FUNCTION control_inventarios.ajuste_inventario_recepcion_transferencias_otro_periodo(varchar, varchar, varchar, varchar, numeric, varchar, text);

CREATE OR REPLACE FUNCTION control_inventarios.ajuste_inventario_recepcion_transferencias_otro_periodo(p_bod_selecc character varying,
                                                                                                       p_bod_entorn character varying,
                                                                                                       p_ubicacion character varying,
                                                                                                       p_item character varying,
                                                                                                       p_cantidad numeric,
                                                                                                       p_transaccion character varying,
                                                                                                       p_usuario text)
    RETURNS void
    LANGUAGE plpgsql
AS
$function$
DECLARE
    v_transaccion     numeric;
    _interface_activo BOOLEAN = TRUE;
BEGIN
    SELECT p_interface_activo
    INTO _interface_activo
    FROM sistema.interface_modulo_activo_fnc('trabajo_proceso');

    -- Numero Transaccion
    SELECT numero INTO v_transaccion FROM sistema.transaccion_inventario_numero_obtener(p_bod_entorn);

    -- Actualizo los que vengan con Secuecia
    WITH s
             AS
             (INSERT INTO control_inventarios.transacciones AS tr
                 (transaccion, bodega, item, tipo_movimiento, fecha, cantidad, costo, modulo, documento, ubicacion,
                  referencia, creacion_usuario, creacion_fecha, creacion_hora, es_psql)
                 SELECT LPAD(v_transaccion::text, 10, ' '),
                        p_bod_selecc,
                        p_item,
                        'RECE CANT' || CASE WHEN p_cantidad > 0 THEN '+' ELSE '-' END,
                        CURRENT_DATE,
                        p_cantidad,
                        i.costo_promedio,
                        'IC',
                        v_transaccion::varchar,
                        p_ubicacion,
                        'AJUSTE INV. ' || p_transaccion,
                        p_usuario,
                        CURRENT_DATE,
                        ('now'::text)::time(0),
                        TRUE
                 FROM control_inventarios.items i
                 WHERE i.item = p_item
                 RETURNING tr.transaccion, tr.bodega, tr.item, tr.referencia, tr.tipo_movimiento, tr.fecha, tr.cantidad,
                     tr.costo, tr.modulo, tr.documento, tr.ubicacion, tr.precio, tr.creacion_usuario, tr.creacion_fecha,
                     tr.creacion_hora)
    INSERT
    INTO sistema.interface
        (modulo, proceso, tabla, usuarios, directorio, buscar, sql)
    SELECT 'AUDITORIA'
         , 'INSERT1'
         , 'ICTRAN01'
         , p_usuario
         , 'V:\SBTPRO\ICDATA\ '
         , ''
         , 'INSERT INTO V:\SBTPRO\ICDATA\ICTRAN01 ' ||
           '(ttranno, loctid, item, ref, trantyp, ' ||
           'tdate, sqty, tcost, applid, docno, ' ||
           'tstore, price, adduser, adddate, addtime, per) ' ||
           'VALUES ([' ||
           s.transaccion || '], [' || s.bodega || '], [' || s.item || '], [' || s.referencia ||
           '], [' ||
           CASE WHEN s.cantidad > 0 THEN 'JR' ELSE 'JI' END || '], {^' ||
           TO_CHAR(s.fecha, 'YYYY-MM-DD') || '}, ' || s.cantidad::VARCHAR || ', ' ||
           s.costo::VARCHAR || ', [' ||
           s.modulo || '], [' || s.documento || '], [' ||
           s.ubicacion || '], ' || COALESCE(s.precio::VARCHAR, '0') || ', [' || s.creacion_usuario || '], {^' ||
           TO_CHAR(s.fecha, 'YYYY-MM-DD') || '}, [' || ('now'::text)::time(0) || '], [' ||
           TO_CHAR(CURRENT_DATE, 'YYYYMM') || '])'
    FROM s
    WHERE _interface_activo;
END;
$function$
;
