CREATE OR REPLACE FUNCTION trabajo_proceso.ordenes_cierre_tintoreria(p_codigo_orden text, p_usuario text)
    RETURNS void
    LANGUAGE plpgsql
AS
$$
DECLARE
    _interface_activo BOOLEAN = TRUE;
    p_neto            NUMERIC;
    p_item            TEXT;
BEGIN

    SELECT p_interface_activo
    INTO _interface_activo
    FROM sistema.interface_modulo_activo_fnc('trabajo_proceso');

    SELECT item,
           CASE
               WHEN o.cantidad_planificada < 0
                   THEN 0.0
               ELSE o.cantidad_planificada
               END - o.cantidad_fabricada AS neto
    INTO p_item, p_neto
    FROM trabajo_proceso.ordenes o
    WHERE o.codigo_orden = p_codigo_orden;

    PERFORM trabajo_proceso.cierre_ordenes_produccion(p_codigo_orden, p_item, p_neto, p_usuario);

    WITH t
             AS
             (
                 UPDATE trabajo_proceso.ordenes o
                     SET estado = 'Cerrada'
                     WHERE o.codigo_orden = p_codigo_orden
                     RETURNING o.codigo_orden)
    INSERT
    INTO sistema.interface
        (modulo, proceso, tabla, usuarios, directorio, buscar, sql)
    SELECT 'TRABAJO EN PROCESO'
         , 'UPDATE1'
         , 'ordenes'
         , p_usuario
         , 'f:\home\spp\trabproc\data\ '
         , '' /* MP 2019-08-19 09:22  Cambio por destiempo de actualizacion de reapertura de ordenes (a partir de un egreso) antes $DESTAJO*/
         , 'UPDATE f:\home\spp\trabproc\data\ordenes ' ||
           'Set estado		= [Cerrada] ' ||
           'Where	codorden = [' || RPAD(t.codigo_orden, 15, ' ') || ']'
    FROM t
    WHERE _interface_activo;

END;
$$;