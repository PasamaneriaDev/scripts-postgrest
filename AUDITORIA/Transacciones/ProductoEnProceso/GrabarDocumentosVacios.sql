-- DROP FUNCTION control_inventarios.ajuste_costo_grabar_fnc(varchar, bool, text);

CREATE OR REPLACE FUNCTION control_inventarios.ajuste_toma_grabar_documentos_vacios_fnc(p_documento_inicial integer,
                                                                                        p_documento_final integer,
                                                                                        p_bodega VARCHAR,
                                                                                        p_ubicacion varchar,
                                                                                        p_usuario text)
    RETURNS void
    LANGUAGE plpgsql
AS
$function$

DECLARE
    _interface_activo BOOLEAN = TRUE;
BEGIN
    WITH RECURSIVE
        rango AS (SELECT p_documento_inicial AS nro_documento
                  UNION ALL
                  SELECT nro_documento + 1
                  FROM rango
                  WHERE nro_documento < p_documento_final),
        t AS (
            INSERT INTO control_inventarios.ajustes AS a
                (documento, item, cantidad_ajuste, bodega, ubicacion, tipo, creacion_usuario)
                SELECT LPAD(r.nro_documento::text, 10, '0'), 'V', 0, p_bodega, p_ubicacion, 'T', p_usuario
                FROM rango r
                RETURNING a.documento, a.item, a.cantidad_ajuste, a.bodega, a.ubicacion,
                    a.tipo, a.creacion_usuario, a.creacion_fecha, a.creacion_hora, a.secuencia)
    INSERT
    INTO sistema.interface
        (usuarios, modulo, proceso, directorio, tabla, buscar, SQL)
    SELECT t.creacion_usuario
         , 'AUDITORIA'
         , 'INSERT1'
         , 'V:\SBTPRO\ICDATA\ '
         , 'ICINVF01'
         , ''
         , FORMAT(
            'INSERT INTO v:\sbtpro\icdata\ICINVF01 ' ||
            '(document, item, descrip, sqty, loctid, ' ||
            ' qstore, type, adduser, adddate, addtime,' ||
            ' secu_post) ' ||
            'VALUES([%s], [%s], [%s], %s, [%s], ' ||
            '       [%s], [%s], [%s], {^%s}, [%s], ' ||
            '       %s)',
            t.documento, t.item, i.descripcion, t.cantidad_ajuste::VARCHAR, t.bodega,
            t.ubicacion, t.tipo, t.creacion_usuario, TO_CHAR(t.creacion_fecha, 'YYYY-MM-DD'), t.creacion_hora,
            t.secuencia::VARCHAR)
    FROM t
             INNER JOIN
         control_inventarios.items i ON t.item = i.item
    WHERE _interface_activo;

END ;
$function$
;
