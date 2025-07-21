CREATE OR REPLACE FUNCTION cuentas_cobrar.guias_remision_transferencia(p_datajs text,
                                                                       p_usuario text)
    RETURNS void
    LANGUAGE plpgsql
AS
$function$
DECLARE
    _interface_activo BOOLEAN = TRUE;
    v_punto_emision   varchar;
    v_numero_guia     varchar;
    v_factura         varchar = '';
BEGIN

    SELECT p_interface_activo
    INTO _interface_activo
    FROM sistema.interface_modulo_activo_fnc('trabajo_proceso');

    IF p_datajs::json ->> 'tipo_documento' = 'D' THEN
        SELECT factura
        INTO v_factura
        FROM cuentas_cobrar.facturas_cabecera
        WHERE referencia = (p_datajs::json ->> 'referencia');

        IF NOT found THEN
            RAISE EXCEPTION 'No existe factura para la referencia %', (p_datajs::json ->> 'referencia');
        END IF;
    END IF;

    SELECT direccion3
    INTO v_punto_emision
    FROM sistema.parametros_almacenes
    WHERE bodega = (p_datajs::json ->> 'bodega')
      AND terminal = '01';

    SELECT p_numero_guia
    INTO v_numero_guia
    FROM sistema.bodega_numero_guia_obtener_fnc((p_datajs::json ->> 'bodega'), '01');

    WITH t AS (
        INSERT INTO cuentas_cobrar.guias_remision AS a
            (tipo_documento, numero_guia, referencia, cliente, fecha,
             bodega, factura, codigo_transportista, direccion_establecimiento,
             fecha_inicio, fecha_fin, direccion_destino, impreso, numero_ganchos)
            SELECT x.tipo_documento,
                   v_numero_guia,
                   x.referencia,
                   x.cliente,
                   CURRENT_DATE,
                   x.bodega,
                   v_factura,
                   x.codigo_transportista,
                   v_punto_emision,
                   x.fecha_inicio,
                   x.fecha_fin,
                   x.direccion_destino,
                   '',
                   0
            FROM JSON_TO_RECORD(p_datajs::json) x (tipo_documento text, referencia text, cliente text,
                                                   bodega text, codigo_transportista text,
                                                   fecha_inicio date, fecha_fin date,
                                                   direccion_destino text)
            RETURNING a.tipo_documento,
                a.numero_guia,
                a.referencia,
                a.cliente,
                a.fecha,
                a.bodega,
                a.factura,
                a.codigo_transportista,
                a.direccion_establecimiento,
                a.fecha_inicio,
                a.fecha_fin,
                a.direccion_destino,
                a.impreso,
                a.numero_ganchos)
    INSERT
    INTO sistema.interface
        (usuarios, modulo, proceso, directorio, tabla, buscar, sql)
    SELECT p_usuario
         , 'DESPACHOS'
         , 'INSERT1'
         , 'V:\SBTPRO\ARDATA\ '
         , 'ARGUIASR'
         , ''
         , FORMAT(
            'INSERT INTO V:\SBTPRO\ARDATA\ARGUIASR ' ||
            '(invno, custno, invdte, tipo_docu, ' ||
            ' loctid, refnum_fac, cod_transp, refnum_gui, ' ||
            ' direstable, fechaini, fechafin, dirdestino, ' ||
            ' prtid, numganchos) ' ||
            'VALUES([%s], [%s], [%s], [%s], ' ||
            '       [%s], [%s], [%s], [%s], ' ||
            '       [%s], {^%s}, {^%s}, [%s], ' ||
            '       [%s], %s)',
            t.referencia, t.cliente, TO_CHAR(t.fecha, 'MM/DD/YYYY'), t.tipo_documento,
            t.bodega, t.factura, t.codigo_transportista, t.numero_guia,
            t.direccion_establecimiento, TO_CHAR(t.fecha_inicio, ' YYYY - MM - DD '),
            TO_CHAR(t.fecha_fin, ' YYYY - MM - DD '),
            t.direccion_destino, t.impreso, t.numero_ganchos)

    FROM t
    WHERE _interface_activo;
END;
$function$
;


