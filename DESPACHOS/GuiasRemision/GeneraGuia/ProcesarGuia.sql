-- drop function cuentas_cobrar.guias_remision_actualiza_autorizacion_from_public();

CREATE OR REPLACE FUNCTION cuentas_cobrar.guia_remision_procesar(p_data_js varchar, p_usuario varchar)
    RETURNS void
    LANGUAGE plpgsql
AS
$function$
DECLARE
    _interface_activo         BOOLEAN = TRUE;
    v_ambiente_facturacion    numeric;
    v_direccion               varchar;
    v_ambiente_guias_remision varchar;
    v_ruc_pasa                varchar;
    v_razon_social_pasa       varchar;
    v_direccion_pasa          varchar;
    v_email_pasa              varchar;
    v_transportista_rec       RECORD;
    v_tipo_documento          varchar;
    v_numero_ganchos          numeric;
    v_referencia_guia         varchar;
    v_data_rec                RECORD;
BEGIN

    SELECT p_interface_activo
    INTO _interface_activo
    FROM sistema.interface_modulo_activo_fnc('trabajo_proceso');

    SELECT x.numero_guia,
           x.direccion_destino,
           x.fecha_inicio,
           x.fecha_fin,
           x.codigo_transportista,
           x.bodega_entorno
    INTO v_data_rec
    FROM JSON_TO_RECORD(p_data_js::json) x (numero_guia text, direccion_destino text, fecha_inicio date,
                                            fecha_fin date, codigo_transportista text, bodega_entorno text);

    SELECT gr.tipo_documento, COALESCE(gr.numero_ganchos, 0), COALESCE(gr.referencia, '')
    INTO v_tipo_documento, v_numero_ganchos, v_referencia_guia
    FROM cuentas_cobrar.guias_remision gr
    WHERE numero_guia = v_data_rec.numero_guia;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No se encontró la guía de remisión con número %', v_data_rec.numero_guia;
    END IF;

    WITH t AS (
        UPDATE cuentas_cobrar.guias_remision AS g
            SET direccion_destino = v_data_rec.direccion_destino,
                fecha_inicio = v_data_rec.fecha_inicio,
                fecha_fin = v_data_rec.fecha_fin,
                codigo_transportista = v_data_rec.codigo_transportista
            WHERE numero_guia = v_data_rec.numero_guia
            RETURNING g.numero_guia, g.direccion_destino,
                g.fecha_inicio, g.fecha_fin, g.codigo_transportista)
    INSERT
    INTO sistema.interface
        (modulo, proceso, tabla, usuarios, directorio, buscar, sql)
    SELECT 'DESPACHOS',
           'UPDATE1',
           'arguiasr',
           p_usuario,
           'V:\sbtpro\ardata\ ',
           '',
           FORMAT('UPDATE V:\sbtpro\ardata\arguiasr ' ||
                  'SET  dirdestino = [%s], ' ||
                  '     fechaini = {^%s}, ' ||
                  '     fechafin = {^%s}, ' ||
                  '     cod_transp = [%s] ' ||
                  'WHERE refnum_gui = [%s] ',
                  t.direccion_destino, TO_CHAR(t.fecha_inicio, 'YYYY-MM-DD'),
                  TO_CHAR(t.fecha_fin, 'YYYY-MM-DD'), t.codigo_transportista, t.numero_guia)
    FROM t
    WHERE _interface_activo;

    SELECT codigo,
           cedula_ruc,
           tipo_cedula_ruc,
           nombre,
           direccion,
           telefono1,
           email,
           CASE
               WHEN tipo_cedula_ruc = 'R' THEN '04'
               WHEN tipo_cedula_ruc = 'C' THEN '05'
               WHEN tipo_cedula_ruc = 'P' THEN '06'
               ELSE '' END AS tipo_cedula_transportista
    INTO v_transportista_rec
    FROM cuentas_pagar.proveedores
    WHERE codigo = v_data_rec.codigo_transportista;

    SELECT direccion3, ambiente_guias_remision
    INTO v_direccion, v_ambiente_guias_remision
    FROM sistema.parametros_almacenes
    WHERE bodega = v_data_rec.bodega_entorno;

    v_direccion := COALESCE(v_direccion, '');
    v_ambiente_guias_remision := COALESCE(v_ambiente_guias_remision, '');

    IF v_ambiente_guias_remision = '' THEN
        RAISE EXCEPTION 'No se ha definido el ambiente para las guías de remisión en la bodega %', v_data_rec.bodega_entorno;
    END IF;

    IF v_ambiente_guias_remision = 'PRUEBAS' THEN
        v_ambiente_facturacion = 1;
    ELSE
        v_ambiente_facturacion = 2;
    END IF;

    SELECT alfa INTO v_ruc_pasa FROM sistema.parametros WHERE codigo = 'P-RUC';
    SELECT alfa INTO v_razon_social_pasa FROM sistema.parametros WHERE codigo = 'P-RAZONSOCIAL';
    SELECT alfa INTO v_direccion_pasa FROM sistema.parametros WHERE codigo = 'P-DIRECCION';
    SELECT alfa INTO v_email_pasa FROM sistema.parametros WHERE codigo = 'MAIL-FACT-ELECT';

    v_ruc_pasa := COALESCE(v_ruc_pasa, '');
    v_razon_social_pasa := COALESCE(v_razon_social_pasa, '');
    v_direccion_pasa := COALESCE(v_direccion_pasa, '');
    v_email_pasa := COALESCE(v_email_pasa, '');

    IF v_ruc_pasa = '' OR v_razon_social_pasa = '' THEN
        RAISE EXCEPTION 'No existen parámetros para factura electrónica.';
    END IF;

    /* ------------------------------------------------------------------------------ */
    -- CABECERA DE LA GUIA
    /* ------------------------------------------------------------------------------ */

    INSERT INTO public.cc_elec_cabecera_guia (ambiente, razon_social, nombre_comercial, ruc_empresa, clave_acceso,
                                              documento, establecimiento, puntoemision, secuencial, direccion_matriz,
                                              direccion_estab, direccion_partida, ruc_transportista,
                                              tipo_id_transportista, razon_social_transportista,
                                              direccion_transportista, email_transportista, numero_placa,
                                              obligadocontabilidad, contribuyenteespecial,
                                              fecha_inicio_transporte, fecha_fin_transporte, id_destinatario,
                                              razon_social_destinatario, direccion_destinatario,
                                              motivo_translado, telefono_transportista, enviado_sri)
    SELECT v_ambiente_facturacion,
           v_razon_social_pasa,
           v_razon_social_pasa,
           v_ruc_pasa,
           '0',
           '06',
           LEFT(me.numero_guia, 3),
           SUBSTRING(me.numero_guia FROM 4 FOR 3),
           RIGHT(me.numero_guia, 9),
           v_direccion_pasa,
           me.direccion_establecimiento,
           me.direccion_establecimiento,
           v_transportista_rec.cedula_ruc,
           v_transportista_rec.tipo_cedula_transportista,
           v_transportista_rec.nombre,
           v_transportista_rec.direccion,
           CASE WHEN v_ambiente_facturacion = '1' THEN COALESCE(v_email_pasa, '') ELSE v_transportista_rec.email END,
           '0',
           'SI',
           '3257',
           me.fecha_inicio,
           me.fecha_fin,
           cl.cedula_ruc,
           cl.nombre,
           cl.direccion,
           'TRANSFERENCIA DE MERCADERIA',
           v_transportista_rec.telefono1,
           '0'
    FROM cuentas_cobrar.guias_remision me
             LEFT JOIN cuentas_cobrar.clientes cl ON cl.codigo = me.cliente
    WHERE me.numero_guia = v_data_rec.numero_guia;

    RAISE NOTICE 'Insertando cabecera de la guía %', v_data_rec.numero_guia;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No se Inserto la cabecera %', v_data_rec.numero_guia;
    END IF;

    /* ------------------------------------------------------------------------------ */
    -- DETALLES DE LA GUIA
    /* ------------------------------------------------------------------------------ */

    IF v_tipo_documento = 'F' OR v_tipo_documento = 'D' THEN
        INSERT INTO public.cc_elec_detalle_guia (ruc_empresa, ambiente, documento, establecimiento, puntoemision,
                                                 secuencial, codigo_producto, descripcion, cantidad)
        SELECT v_ruc_pasa,
               v_ambiente_facturacion,
               '06',
               LEFT(v_data_rec.numero_guia, 3),
               SUBSTRING(v_data_rec.numero_guia FROM 4 FOR 3),
               RIGHT(v_data_rec.numero_guia, 9),
               r1.item,
               r1.descripcion,
               r1.cantidad
        FROM (SELECT fd.item,
                     fd.descripcion,
                     fd.cantidad
              FROM cuentas_cobrar.facturas_detalle fd
              WHERE fd.referencia = v_referencia_guia
              UNION ALL
              SELECT 'GANCHOS',
                     'GANCHOS',
                     v_numero_ganchos
              WHERE v_numero_ganchos > 0) AS r1;

    ELSEIF v_tipo_documento = 'T' THEN
        INSERT INTO public.cc_elec_detalle_guia (ruc_empresa, ambiente, documento, establecimiento, puntoemision,
                                                 secuencial, codigo_producto, descripcion, cantidad)
        SELECT v_ruc_pasa,
               v_ambiente_facturacion,
               '06',
               LEFT(v_data_rec.numero_guia, 3),
               SUBSTRING(v_data_rec.numero_guia FROM 4 FOR 3),
               RIGHT(v_data_rec.numero_guia, 9),
               t.item,
               i.descripcion,
               t.cantidad
        FROM control_inventarios.transacciones t
                 INNER JOIN control_inventarios.items i
                            ON t.item = i.item
        WHERE t.transaccion = v_referencia_guia
          AND tipo_movimiento = 'TRANSFER+';

    ELSEIF v_tipo_documento = 'M' THEN
        INSERT INTO public.cc_elec_detalle_guia (ruc_empresa, ambiente, documento, establecimiento, puntoemision,
                                                 secuencial, codigo_producto, descripcion, cantidad)
        SELECT v_ruc_pasa,
               v_ambiente_facturacion,
               '06',
               LEFT(v_data_rec.numero_guia, 3),
               SUBSTRING(v_data_rec.numero_guia FROM 4 FOR 3),
               RIGHT(v_data_rec.numero_guia, 9),
               item,
               descripcion,
               cantidad
        FROM cuentas_cobrar.detalle_guia_manual
        WHERE numero_guia = v_data_rec.numero_guia;

    END IF;

    WITH t AS (
        UPDATE cuentas_cobrar.guias_remision as gr
            SET impreso = 'P'
            WHERE numero_guia = v_data_rec.numero_guia
               RETURNING gr.numero_guia, gr.impreso)
    INSERT
    INTO sistema.interface
        (modulo, proceso, tabla, usuarios, directorio, buscar, sql)
    SELECT 'DESPACHOS',
           'UPDATE1',
           'arguiasr',
           p_usuario,
           'V:\sbtpro\ardata\ ',
           '',
           FORMAT('UPDATE V:\sbtpro\ardata\arguiasr ' ||
                  'SET prtid = [%s] ' ||
                  'WHERE refnum_gui = [%s]',
                  t.impreso, t.numero_guia)
    FROM t
    WHERE _interface_activo;
END;
$function$
;
