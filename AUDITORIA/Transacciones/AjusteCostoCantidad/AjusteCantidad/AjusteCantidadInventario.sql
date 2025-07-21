-- DROP FUNCTION control_inventarios.ajuste_cantidad_actualizacion_inventario(text, text, text, text);

CREATE OR REPLACE FUNCTION control_inventarios.ajuste_cantidad_actualizacion_inventario(p_documento text, p_tipo text, p_referencia text, p_usuario text)
    RETURNS void
    LANGUAGE plpgsql
AS
$function$

DECLARE
    _interface_activo BOOLEAN = TRUE;
    count             integer;
BEGIN
    SELECT p_interface_activo
    INTO _interface_activo
    FROM sistema.interface_modulo_activo_fnc('trabajo_proceso');

    -- Tabla Temporal
    CREATE TEMP TABLE ajuste_tmp ON COMMIT DROP AS
    SELECT r1.*, COALESCE(p.precio, 0) AS precio, LPAD(x.numero::text, 10, ' ') AS transaccion
    FROM (SELECT a.bodega
               , a.item
               , CASE
                     WHEN a.cantidad_ajuste < 0
                         THEN 'AJUS CANT-'
                     ELSE 'AJUS CANT+' END    AS tipo
               , 'Ajuste Invent. Bodega/Ubic' AS referencia
               , a.cantidad_ajuste            AS cantidad
               , a.costo
               , a.documento
               , a.ubicacion
               , a.cuenta_ajuste
               , a.cuenta
               , a.secuencia
               , a.anio_trimestre
          FROM control_inventarios.ajustes a
          WHERE (a.documento = p_documento OR p_documento = '')
            AND a.tipo = p_tipo
            AND a.status <> ALL ('{V,C}'::TEXT[])
          ORDER BY a.secuencia) r1
             LEFT JOIN control_inventarios.precios p ON p.item = r1.item AND p.tipo = 'PVP'
             INNER JOIN LATERAL sistema.transaccion_inventario_numero_obtener(CASE WHEN r1.secuencia >= 0 THEN '001' END) x
                        ON TRUE;

    -- Inserta Transacciones de Entrega
    WITH tran
             AS
             (
                 INSERT INTO control_inventarios.transacciones AS it
                     (transaccion, bodega, item, referencia, anio_trimestre, tipo_movimiento, fecha, cantidad, costo,
                      modulo, documento,
                      ubicacion, precio, creacion_usuario, es_psql)
                     SELECT r1.transaccion
                          , r1.bodega
                          , r1.item
                          , CASE
                                WHEN p_referencia = '' THEN r1.referencia::varchar
                                ELSE p_referencia::varchar END AS referencia
                          , r1.anio_trimestre
                          , r1.tipo
                          , CURRENT_DATE
                          , r1.cantidad
                          , r1.costo
                          , 'IC'
                          , r1.documento
                          , r1.ubicacion
                          , r1.precio
                          , p_usuario
                          , TRUE
                     FROM ajuste_tmp AS r1
                     RETURNING it.*)
    INSERT
    INTO sistema.interface
        (modulo, proceso, tabla, usuarios, directorio, buscar, sql)
    SELECT 'AUDITORIA'
         , 'INSERT1'
         , 'ICTRAN01'
         , p_usuario
         , 'V:\SBTPRO\ICDATA\ ' --, anio_trime WITH ' ||  CAST(NEW.anio_trimestre As VARCHAR) ||
         , ''
         , 'INSERT INTO V:\SBTPRO\ICDATA\ICTRAN01 ' ||
           '(ttranno, loctid, item, ref, anio_trime, trantyp, ' ||
           'tdate, sqty, tcost, applid, docno, ' ||
           'tstore, price, adduser, adddate, addtime, per) ' ||
           'VALUES ([' ||
           s.transaccion || '], [' || s.bodega || '], [' || s.item || '], [' || s.referencia ||
           '], ' || COALESCE(s.anio_trimestre::varchar, '') || ', [' ||
           CASE WHEN s.tipo_movimiento = 'AJUS CANT+' THEN 'AR' ELSE 'AI' END || '], {^' ||
           TO_CHAR(s.fecha, 'YYYY-MM-DD') || '}, ' || s.cantidad::VARCHAR || ', ' ||
           s.costo::VARCHAR || ', [' ||
           s.modulo || '], [' || s.documento || '], [' ||
           s.ubicacion || '], ' || COALESCE(s.precio::VARCHAR, '0') || ', [' || s.creacion_usuario || '], {^' ||
           TO_CHAR(s.fecha, 'YYYY-MM-DD') || '}, [' || ('now'::text)::time(0) || '], [' ||
           TO_CHAR(CURRENT_DATE, 'YYYYMM') || '])'
    FROM tran AS s
    WHERE _interface_activo;

    WITH dist
             AS
             (
                 INSERT INTO control_inventarios.distribucion AS d
                     (cuenta, monto, fecha, transaccion, tipo_transaccion, periodo, ano, creacion_usuario)
                     SELECT x.cuenta
                          , x.costo
                          , CURRENT_DATE
                          , x.transaccion
                          , x.tipo_transaccion
                          , TO_CHAR(CURRENT_DATE, 'MM')
                          , TO_CHAR(CURRENT_DATE, 'YYYY')
                          , p_usuario
                     FROM (SELECT a.cuenta
                                , a.costo * a.cantidad                                    AS costo
                                , a.transaccion
                                , CASE WHEN a.tipo = 'AJUS CANT+' THEN 'DC' ELSE 'DD' END AS tipo_transaccion
                           FROM ajuste_tmp a
                           UNION ALL
                           SELECT a.cuenta_ajuste
                                , a.costo * a.cantidad * -1                               AS costo
                                , a.transaccion
                                , CASE WHEN a.tipo = 'AJUS CANT+' THEN 'CD' ELSE 'CC' END AS tipo_transaccion
                           FROM ajuste_tmp a) x
                     ORDER BY x.transaccion, x.costo
                     RETURNING d.*)
    INSERT
    INTO sistema.interface
        (modulo, proceso, tabla, usuarios, directorio, buscar, sql)
    SELECT 'AUDITORIA'
         , 'INSERT1'
         , 'ICDIST01'
         , p_usuario
         , 'V:\SBTPRO\ICDATA\ '
         , ''
         , 'INSERT INTO V:\SBTPRO\ICDATA\ICDIST01 ' ||
           '(glacnt, amount, trandte, tranno, dsttype, ' ||
           'currdte, glper, glfyear, adduser, adddate, ' ||
           'addtime) ' ||
           'VALUES ([' ||
           i.cuenta || '], ' || i.monto::VARCHAR || ', {^' || TO_CHAR(i.fecha, 'YYYY-MM-DD') || '}, [' ||
           i.transaccion || '], [' || i.tipo_transaccion || '], {^' ||
           TO_CHAR(fecha, 'YYYY-MM-DD') || '}, [' || i.periodo || '], [' || i.ano || '], [' || i.creacion_usuario ||
           '], {^' || TO_CHAR(CURRENT_DATE, 'YYYY-MM-DD') || '}, [' ||
           ('now'::text)::time(0) || '])'
    FROM dist AS i
    WHERE _interface_activo;

    -- Actualiza Ajuste
    WITH t
             AS
             (
                 UPDATE control_inventarios.ajustes a
                     SET fecha = CURRENT_DATE
                         , status = 'C'
                     WHERE (documento = p_documento OR p_documento = '')
                         AND tipo = p_tipo
                     RETURNING a.secuencia)
    INSERT
    INTO sistema.interface
        (modulo, proceso, tabla, usuarios, directorio, buscar, sql)
    SELECT 'AUDITORIA'
         , 'UPDATE1'
         , 'ICINVF01'
         , p_usuario
         , 'V:\SBTPRO\ICDATA\ '
         , ''
         , 'UPDATE V:\SBTPRO\ICDATA\ICINVF01 ' ||
           'SET tdate = [' || TO_CHAR(CURRENT_DATE, 'YYYY/MM/DD') || '] '
               ', icstat= [C] ' ||
           'Where secu_post = ' || t.secuencia::varchar
    FROM t
    WHERE _interface_activo;

END ;
$function$
;
