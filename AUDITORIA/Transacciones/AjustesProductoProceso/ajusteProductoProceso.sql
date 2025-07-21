-- DROP FUNCTION control_inventarios.ajuste_cantidad_producto_proceso(text, text);

CREATE OR REPLACE FUNCTION control_inventarios.ajuste_cantidad_producto_proceso(p_data text, p_usuario text)
    RETURNS void
    LANGUAGE plpgsql
AS
$function$

DECLARE
    _interface_activo       BOOLEAN = TRUE;
    v_cuenta_default_ajuste text;
BEGIN
    SELECT p_interface_activo
    INTO _interface_activo
    FROM sistema.interface_modulo_activo_fnc('trabajo_proceso');

    SELECT alfa
    INTO v_cuenta_default_ajuste
    FROM sistema.parametros p
    WHERE modulo_id = 'TRABPROC'
      AND codigo = 'CUENTA_AJUSTEPT';

    -- Tabla Temporal
    CREATE TEMP TABLE ajuste_tmp ON COMMIT DROP AS
    SELECT r1.*, LPAD(x.numero::text, 10, ' ') AS transaccion
    FROM (SELECT i.bodega
               , a.item
               , CASE
                     WHEN a.cantidad_ajuste < 0
                         THEN 'AJUS CANT-'
                     ELSE 'AJUS CANT+' END                             AS tipo
               , ROUND(a.cantidad_ajuste, i.numero_decimales::integer) AS cantidad
               , i.costo_promedio                                      AS costo
               , a.documento                                           AS documento
               , a.ubicacion
               , a.referencia
               , CASE
                     WHEN LEFT(a.item, 1) = 'M' THEN i.costo_promedio
                     ELSE cl.valor_materia_prima END                  AS valor_materia_prima
               , CASE
                     WHEN LEFT(a.item, 1) = 'M' THEN 0
                     ELSE cl.valor_mano_obra END                      AS valor_mano_obra
               , CASE
                     WHEN LEFT(a.item, 1) = 'M' THEN 0
                     ELSE cl.valor_gastos_fabricacion END             AS valor_gastos_fabricacion
               , ib.ajuste_materia_prima                  AS cuenta_materia_prima
               , ib.ajuste_mano_obra                      AS cuenta_mano_obra
               , ib.ajuste_gastos_fabricacion             AS cuenta_gastos_fabricacion
          FROM JSON_TO_RECORD(p_data::json) a (ubicacion TEXT, item TEXT, cantidad_ajuste DECIMAL, documento TEXT, referencia text)
                   JOIN control_inventarios.items i ON i.item = a.item
                   LEFT JOIN LATERAL (SELECT COALESCE(c.mantenimiento_materia_prima + c.nivel_materia_prima +
                                                      c.acumulacion_materia_prima, 0)      AS valor_materia_prima,
                                             COALESCE(c.mantenimiento_mano_obra + c.nivel_mano_obra +
                                                      c.acumulacion_mano_obra, 0)          AS valor_mano_obra,
                                             COALESCE(c.mantenimiento_gastos_fabricacion + c.nivel_gastos_fabricacion +
                                                      c.acumulacion_gastos_fabricacion, 0) AS valor_gastos_fabricacion
                                      FROM costos.costos c
                                      WHERE c.item = a.item
                                        AND c.tipo_costo = 'Standard') AS cl ON TRUE
                   JOIN control_inventarios.id_bodegas ib ON i.bodega = ib.bodega) r1
             INNER JOIN LATERAL sistema.transaccion_inventario_numero_obtener(CASE WHEN r1.item = r1.item THEN '001' END) x
                        ON TRUE;

    -- Inserta Transacciones de Entrega
    WITH tran
             AS
             (
                 INSERT INTO control_inventarios.transacciones AS it
                     (transaccion, bodega, item, tipo_movimiento, fecha, cantidad, costo,
                      modulo, ubicacion, referencia, periodo, creacion_usuario, es_psql)
                     SELECT r1.transaccion
                          , r1.bodega
                          , r1.item
                          , r1.tipo
                          , CURRENT_DATE
                          , r1.cantidad
                          , r1.costo
                          , 'TP'
                          , r1.ubicacion
                          , r1.referencia
                          , TO_CHAR(CURRENT_DATE, 'YYYYMM')
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
         , 'V:\SBTPRO\ICDATA\ '
         , ''
         , FORMAT('INSERT INTO V:\SBTPRO\ICDATA\ICTRAN01 ' ||
                  '(ttranno, loctid, item, trantyp, ' ||
                  ' tdate, sqty, tcost, applid, ref, ' ||
                  ' tstore, adduser, adddate, per) ' ||
                  'VALUES ([%s], [%s], [%s], [%s], ' ||
                  '        {^%s}, %s, %s, [%s], [%s], ' ||
                  '        [%s], [%s], {^%s}, [%s])',
                  s.transaccion, s.bodega, s.item, lista_materiales.tipo_movimiento_spp_x_codigo(s.tipo_movimiento),
                  TO_CHAR(s.fecha, 'YYYY-MM-DD'), s.cantidad::VARCHAR, s.costo::VARCHAR, s.modulo, s.referencia,
                  s.ubicacion, s.creacion_usuario, TO_CHAR(s.fecha, 'YYYY-MM-DD'), s.periodo)
    FROM tran AS s
    WHERE _interface_activo;

    WITH dist
             AS
             (
                 INSERT INTO control_inventarios.distribucion AS d
                     (cuenta, monto, fecha, transaccion, periodo, ano, creacion_usuario)
                     SELECT x.cuenta
                          , x.costo
                          , CURRENT_DATE
                          , x.transaccion
                          , TO_CHAR(CURRENT_DATE, 'MM')
                          , TO_CHAR(CURRENT_DATE, 'YYYY')
                          , p_usuario
                     FROM (SELECT 1                                       AS orden, -- Identificador para la primera subconsulta
                                  v_cuenta_default_ajuste                 AS cuenta,
                                  a.valor_materia_prima * a.cantidad * -1 AS costo,
                                  a.transaccion
                           FROM ajuste_tmp a
                           WHERE (a.valor_materia_prima * a.cantidad * -1) <> 0
                           UNION ALL
                           SELECT 2                                   AS orden, -- Identificador para la segunda subconsulta
                                  v_cuenta_default_ajuste             AS cuenta,
                                  a.valor_mano_obra * a.cantidad * -1 AS costo,
                                  a.transaccion
                           FROM ajuste_tmp a
                           WHERE (a.valor_mano_obra * a.cantidad * -1) <> 0
                           UNION ALL
                           SELECT 3                                            AS orden,
                                  v_cuenta_default_ajuste                      AS cuenta,
                                  a.valor_gastos_fabricacion * a.cantidad * -1 AS costo,
                                  a.transaccion
                           FROM ajuste_tmp a
                           WHERE (a.valor_gastos_fabricacion * a.cantidad * -1) <> 0
                           UNION ALL
                           SELECT 4                                  AS orden,
                                  a.cuenta_materia_prima             AS cuenta,
                                  a.valor_materia_prima * a.cantidad AS costo,
                                  a.transaccion
                           FROM ajuste_tmp a
                           WHERE (a.valor_materia_prima * a.cantidad) <> 0
                           UNION ALL
                           SELECT 5                              AS orden,
                                  a.cuenta_mano_obra             AS cuenta,
                                  a.valor_mano_obra * a.cantidad AS costo,
                                  a.transaccion
                           FROM ajuste_tmp a
                           WHERE (a.valor_mano_obra * a.cantidad) <> 0
                           UNION ALL
                           SELECT 6                                       AS orden,
                                  a.cuenta_gastos_fabricacion             AS cuenta,
                                  a.valor_gastos_fabricacion * a.cantidad AS costo,
                                  a.transaccion
                           FROM ajuste_tmp a
                           WHERE (a.valor_gastos_fabricacion * a.cantidad) <> 0) x
                     ORDER BY x.transaccion, x.orden
                     RETURNING d.cuenta, d.monto, d.fecha, d.transaccion, d.periodo, d.ano, d.creacion_usuario,
                         d.creacion_fecha, d.creacion_hora)
    INSERT
    INTO sistema.interface
        (modulo, proceso, tabla, usuarios, directorio, buscar, sql)
    SELECT 'AUDITORIA'
         , 'INSERT1'
         , 'ICDIST01'
         , p_usuario
         , 'V:\SBTPRO\ICDATA\ '
         , ''
         , FORMAT('INSERT INTO V:\SBTPRO\ICDATA\ICDIST01 ' ||
                  '(glacnt, amount, trandte, tranno, ' ||
                  'currdte, glper, glfyear, adduser, ' ||
                  'adddate, addtime) ' ||
                  'VALUES ([%s], %s, {^%s}, [%s], ' ||
                  '        {^%s}, [%s], [%s], [%s], ' ||
                  '        {^%s}, [%s])',
                  i.cuenta, i.monto::VARCHAR, TO_CHAR(i.fecha, 'YYYY-MM-DD'), i.transaccion,
                  TO_CHAR(i.fecha, 'YYYY-MM-DD'), i.periodo, i.ano, i.creacion_usuario,
                  TO_CHAR(i.creacion_fecha, 'YYYY-MM-DD'), i.creacion_hora)
    FROM dist AS i
    WHERE _interface_activo;

END ;
$function$
;
