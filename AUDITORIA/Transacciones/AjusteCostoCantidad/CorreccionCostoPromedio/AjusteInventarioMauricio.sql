-- DROP FUNCTION control_inventarios.ajuste_actualizacion_inventario(text, text, text, text);

CREATE OR REPLACE FUNCTION control_inventarios.ajuste_actualizacion_inventario(p_documento text, p_tipo text, p_referencia text, p_usuario text)
    RETURNS void
    LANGUAGE plpgsql
AS
$function$

DECLARE
    _sql              TEXT;
    _interface_activo BOOLEAN = TRUE;

BEGIN

    IF p_tipo <> ALL ('{A,C}'::TEXT[]) THEN
        RAISE EXCEPTION 'Tipo sólo puede ser Ajuste de Inventario (A) o Ajuste de Costo (C)';

    END IF;

    SELECT p_interface_activo
    INTO _interface_activo
    FROM sistema.interface_modulo_activo_fnc('trabajo_proceso');

    IF p_referencia = '' THEN
        p_referencia = CASE
                           WHEN p_tipo = 'A'
                               THEN 'Ajuste Invent. Bodega/Ubic.'
                           ELSE 'Cant. entregada en Cambio Cost'
            END;

    END IF;

    _sql = 'CREATE TEMP TABLE ajuste_tmp ON COMMIT DROP
          As
			With t As
			  (
       		   SELECT a.bodega, a.item, a.cantidad_ajuste, a.costo_nuevo, a.costo
			  					, a.documento, a.ubicacion, a.cuenta, a.cuenta_ajuste, a.secuencia
                  , ''PVP''::TEXT As precio_pvp
               From control_inventarios.ajustes a
               Where a.tipo = $1
                 And a.status <> ALL(''{V,C}''::TEXT[]) ' ||
           CASE WHEN p_documento <> '' THEN 'And a.documento = $2 ' ELSE ' ' END ||
           '), s As ' ||
           '(  ' ||
           'Select t.*, b.cuenta_mano_obra, ''PRT'' As codigo_integracion, COALESCE(p.precio, .0) As precio, CURRENT_DATE As fecha ' ||
           'From t Inner Join ' ||
           'control_inventarios.id_bodegas b On t.bodega = b.bodega Left Join ' ||
           'control_inventarios.precios p On (t.item, t.precio_pvp) = (p.item, p.tipo) ' ||
           ') ' ||
           'Select s.*, n.transaccion_tipo_movimiento As tipo_movimiento, n.factor, n.orden, lpad(x.numero::TEXT, 10, '' '') As transaccion ' ||
           ', ''IC'' As modulo '
               'From s INNER JOIN LATERAL ' ||
           'control_inventarios.ajuste_transaccion_tipo_movimiento(''' || p_tipo ||
           ''', s.cantidad_ajuste) n ON TRUE INNER JOIN LATERAL ' ||
           'sistema.transaccion_inventario_numero_obtener(CASE WHEN s.secuencia >= 0 THEN ''001'' END) x ON TRUE ' ||
           'ORDER BY s.item, n.orden';

    IF p_documento = '' THEN
        EXECUTE _sql USING p_tipo;

    ELSE
        EXECUTE _sql USING p_tipo, p_documento;

    END IF;

    WITH s
             AS
             (
                 INSERT INTO control_inventarios.transacciones AS it
                     (transaccion, bodega, item, referencia, tipo_movimiento, fecha, cantidad, costo, modulo, documento,
                      ubicacion, precio, creacion_usuario, es_psql)
                     SELECT t.transaccion
                          , t.bodega
                          , t.item
                          , p_referencia
                          , t.tipo_movimiento
                          , t.fecha
                          , t.cantidad_ajuste * t.factor
                          , CASE
                                WHEN t.tipo_movimiento = 'AJUS COST+' --AJUS COST- (CI), AJUS COST+ (CR)
                                    THEN t.costo_nuevo
                                ELSE t.costo
                         END
                          , t.modulo
                          , t.documento
                          , t.ubicacion
                          , t.precio
                          , p_usuario
                          , TRUE
                     FROM ajuste_tmp t
                     RETURNING it.*)
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
           'tstore, price, adduser, adddate, addtime) ' ||
           'VALUES ([' ||
           s.transaccion || '], [' || s.bodega || '], [' || s.item || '], [' || s.referencia || '], [' ||
           s.tipo_movimiento || '], {^' ||
           TO_CHAR(s.fecha, 'YYYY-MM-DD') || '}, ' || s.cantidad::VARCHAR || ', ' || s.costo::VARCHAR || ', [' ||
           s.modulo || '], [' || s.documento || '], [' ||
           s.ubicacion || '], ' || s.precio::VARCHAR || ', [' || s.creacion_usuario || '], {^' ||
           TO_CHAR(s.fecha, 'YYYY-MM-DD') || '}, [' || ('now'::text)::time(0) || '])'
    FROM s
    WHERE _interface_activo;

    WITH i
             AS
             (
                 INSERT INTO control_inventarios.distribucion AS d
                     (cuenta, monto, fecha, transaccion, tipo_transaccion, periodo, ano, creacion_usuario)
                     SELECT CASE WHEN t.distribucion_orden = 1 THEN a.cuenta ELSE a.cuenta_ajuste END AS cuenta
                          , CASE
                                WHEN a.tipo_movimiento = 'AJUS COST+' --AJUS COST- (CI), AJUS COST+ (CR)
                                    THEN a.costo_nuevo
                                ELSE a.costo
                                END * a.cantidad_ajuste * t.distribucion_factor                       AS monto
                          , a.fecha
                          , a.transaccion
                          , t.distribucion_tipo_transaccion
                          , TO_CHAR(a.fecha, 'MM')                                                    AS periodo
                          , TO_CHAR(a.fecha, 'YYYY')                                                  AS ano
                          , p_usuario                                                                 AS creacion_usuario
                     FROM ajuste_tmp a
                              INNER JOIN LATERAL
                         (
                         SELECT td.distribucion_tipo_transaccion,
                                td.factor AS distribucion_factor,
                                td.orden  AS distribucion_orden
                         FROM control_inventarios.transaccion_distribucion_tipo td
                         WHERE td.transaccion_tipo_movimiento = a.tipo_movimiento
                         ) t ON TRUE
                     ORDER BY a.transaccion, t.distribucion_orden
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
    FROM i
    WHERE _interface_activo;

    WITH t
             AS
             (
                 UPDATE control_inventarios.ajustes a
                     SET fecha = CURRENT_DATE
                         , status = 'C'
                     FROM ajuste_tmp at
                     WHERE a.secuencia = at.secuencia
                     RETURNING a.item, a.documento, a.bodega, a.ubicacion)
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
           'SET tdate = {^' || TO_CHAR(CURRENT_DATE, 'YYYY-MM-DD') || '} '
               ', icstat= [C] ' ||
           'Where item = [' || RPAD(t.item, 15, ' ') || '] ' ||
           'And document = [' || t.documento || '] ' ||
           'And loctid = [' || t.bodega || '] ' ||
           'And qstore = [' || t.ubicacion || '] '
    FROM t
    WHERE _interface_activo;

END ;
$function$
;
