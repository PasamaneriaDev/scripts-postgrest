-- DROP FUNCTION control_inventarios.ajuste_actualizacion_inventario(text, text, text, text);

CREATE OR REPLACE FUNCTION control_inventarios.ajuste_cantidad_desde_txt(p_datajs character varying, p_usuario varchar)
    RETURNS void
    LANGUAGE plpgsql
AS
$function$

DECLARE
    _interface_activo BOOLEAN = TRUE;
BEGIN
    -- SIN USO, REEMPLAZADO POR AJUSTE_CANTIDAD_GRABAR_FNC

    SELECT p_interface_activo
    INTO _interface_activo
    FROM sistema.interface_modulo_activo_fnc('trabajo_proceso');

    -- Tabla Temporal
    CREATE TEMP TABLE ajuste_tmp ON COMMIT DROP AS
    SELECT r1.*, p.precio, LPAD(x.numero::text, 10, ' ') AS transaccion
    FROM (SELECT a.bodega
               , a.item
               , CASE
                     WHEN a.cantidad_ajuste < 0
                         THEN 'AJUS CANT-'
                     ELSE 'AJUS CANT+' END AS tipo
               , CASE
                     WHEN a.referencia = ''
                         THEN 'Ajuste Invent. Bodega/Ubic'
                     ELSE a.referencia END AS referencia
               , a.cantidad_ajuste         AS cantidad
               , i.costo_promedio          AS costo -- No se usa el costo del ajuste
               , a.documento               AS documento
               , a.ubicacion
               , a.cuenta_ajuste
               , a.cuenta_inventario
               , a.trimestre
          FROM JSON_TO_RECORDSET(p_datajs::json) a (ubicacion TEXT, item TEXT, trimestre text,
                                                    cantidad_ajuste DECIMAL, cuenta_inventario TEXT,
                                                    bodega TEXT, documento text, referencia text,
                                                    cuenta_ajuste TEXT)
                   JOIN control_inventarios.items i ON i.item = a.item) r1
             LEFT JOIN control_inventarios.precios p ON p.item = r1.item AND p.tipo = 'PVP'
             INNER JOIN LATERAL sistema.transaccion_inventario_numero_obtener(CASE WHEN r1.item = r1.item THEN '001' END) x
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
                          , r1.referencia
                          , (CASE WHEN COALESCE(r1.trimestre, '') = '' THEN '0' ELSE r1.trimestre END)::numeric
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
           s.ubicacion || '], ' || COALESCE(s.precio::VARCHAR, '') || ', [' || s.creacion_usuario || '], {^' ||
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
                     FROM (SELECT a.cuenta_inventario                                     AS cuenta
                                , a.costo * a.cantidad                                    AS costo
                                , a.transaccion
                                , CASE WHEN a.tipo = 'AJUS CANT+' THEN 'DC' ELSE 'DD' END AS tipo_transaccion
                           FROM ajuste_tmp a
                           UNION ALL
                           SELECT a.cuenta_ajuste                                         AS cuenta
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

END ;
$function$
;
