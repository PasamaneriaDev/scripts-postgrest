-- DROP FUNCTION ordenes_venta.pedido_graba_modificaciones_detalle(in jsonb, out text);

CREATE OR REPLACE FUNCTION ordenes_venta.pedido_graba_modificaciones_detalle(p_data jsonb, OUT respuesta text)
    RETURNS text
    LANGUAGE plpgsql
AS
$function$
DECLARE
    _r                record;
    _d                record;
    _detalle_original record;
    p_email           text;
    p_numero_email    numeric;
    _interface_activo boolean;
    p_count_updates   numeric;
    v_cliente         VARCHAR;
    v_nombre_cliente  VARCHAR;
    v_nombre_usuario  VARCHAR;
BEGIN
    /********************************************************************************************************/
    -- JSON
    --     {
    --         "numero_pedido": "",
    --         "monto_iva": numeric,
    --         "monto_pendiente": numeric,
    --         "creacion_usuario": ""
    --         "detalles": [
    --             {
    --                 "item": "",
    --                 "descripcion": "",
    --                 "descripcion_original": "",
    --                 "precio": numeric,
    --                 "porcentaje_descuento": numeric,
    --                 "subtotal": numeric,
    --                 "precio_manual": ""
    --                 "color_comercial": ""
    --                 "cliente": ""
    --                 "cliente_catalogo": ""
    --                 "secuencia": ""
    --                 "porcentaje_descuento_original": numeric,
    --             },
    --             {...}
    --         ]
    --     }
    /********************************************************************************************************/
    -- Bandera de Interfaz
    SELECT p_interface_activo
    INTO _interface_activo
    FROM sistema.interface_modulo_activo_fnc('trabajo_proceso');

    -- Extraer los datos del JSON
    SELECT COALESCE(UPPER(t.numero_pedido), '')    AS numero_pedido,
           COALESCE(t.monto_iva, 0)                AS monto_iva,
           COALESCE(t.monto_pendiente, 0)          AS monto_pendiente,

           COALESCE(UPPER(t.creacion_usuario), '') AS creacion_usuario,
           (p_data ->> 'detalles')::jsonb          AS detalles
    INTO _r
    FROM JSONB_TO_RECORD(p_data) AS t (numero_pedido VARCHAR(10),
                                       monto_iva NUMERIC,
                                       monto_pendiente NUMERIC,
                                       creacion_usuario VARCHAR(4));

    /********************************************************************************************************/
    -- ACTUALIZACIÓN en la Cabecera del Pedido
    WITH t AS (
        UPDATE ordenes_venta.pedidos_cabecera t1
            SET monto_iva = _r.monto_iva,
                monto_pendiente = _r.monto_pendiente
            WHERE t1.numero_pedido = _r.numero_pedido
            RETURNING t1.monto_iva, t1.monto_pendiente)
    -- Interfaz
    INSERT
    INTO sistema.interface
        (modulo, proceso, tabla, usuarios, directorio, buscar, sql)
    SELECT 'ORDENES DE VENTA',
           'UPDATE',
           'Somast01',
           _r.creacion_usuario,
           'V:\sbtpro\SODATA\',
           '=SEEK([' || LPAD(_r.numero_pedido::varchar, 10, ' ') || '],[Somast01],[sono])',
           'REPLACE tax WITH ' || CAST((t.monto_iva) AS VARCHAR) ||
           ', ordamt WITH ' || CAST(t.monto_pendiente AS VARCHAR)
    FROM t
    WHERE _interface_activo;

    /********************************************************************************************************/
    -- Obtener el cliente
    SELECT pc.cliente, c.nombre
    INTO v_cliente, v_nombre_cliente
    FROM ordenes_venta.pedidos_cabecera pc
             JOIN cuentas_cobrar.clientes c ON pc.cliente = c.codigo
    WHERE numero_pedido = _r.numero_pedido;

    -- ACTUALIZACIÓN del Saldo del cliente
    WITH t AS (
        UPDATE cuentas_cobrar.clientes t1
            SET pedidos = (SELECT SUM(t2.monto_pendiente)
                           FROM ordenes_venta.pedidos_cabecera t2
                           WHERE t1.codigo = t2.cliente
                             AND t2.monto_pendiente > 0
                             AND COALESCE(t2.estado, '') = '')
            WHERE t1.codigo = v_cliente
            RETURNING t1.pedidos)
    -- Interfaz
    INSERT
    INTO sistema.interface
        (modulo, proceso, tabla, usuarios, directorio, buscar, sql)
    SELECT 'CUENTAS POR COBRAR',
           'UPDATE1',
           'Arcust01',
           _r.creacion_usuario,
           'V:\sbtpro\ARDATA',
           '',
           'UPDATE V:\sbtpro\ARDATA\Arcust01 ' ||
           'set onorder = ' || COALESCE(t.pedidos, 0)::varchar || ' ' ||
           'Where custno = [' || v_cliente || '] '
    FROM t
    WHERE _interface_activo;

    /********************************************************************************************************/
    -- VALIDACIÓN items duplicados
    WITH detalles AS (SELECT j.item,
                             UPPER(j.descripcion) AS descripcion,
                             j.porcentaje_descuento
                      FROM JSON_TO_RECORDSET(_r.detalles::JSON) AS j(item VARCHAR(15), descripcion VARCHAR, porcentaje_descuento NUMERIC))
    SELECT item, descripcion, porcentaje_descuento
    INTO _d
    FROM detalles
    GROUP BY item, descripcion, porcentaje_descuento
    HAVING COUNT(*) > 1;

    IF FOUND THEN
        RAISE EXCEPTION 'Se encontraron ítems duplicados en el JSON: item: %, porcentaje_descuento: %', _d.item, _d.porcentaje_descuento;
    END IF;

    p_count_updates = 0;
    FOR _d IN
        SELECT j.item,
               UPPER(j.descripcion) AS descripcion,
               j.descripcion_original,
               j.precio,
               j.porcentaje_descuento,
               j.subtotal,
               j.precio_manual,
               j.color_comercial,
               j.cliente,
               j.cliente_catalogo,
               j.secuencia,
               j.porcentaje_descuento_original
        FROM JSON_TO_RECORDSET(_r.detalles::JSON) AS j(item VARCHAR(15), descripcion VARCHAR,
                                                       descripcion_original varchar,
                                                       precio NUMERIC, porcentaje_descuento NUMERIC, subtotal NUMERIC,
                                                       precio_manual VARCHAR, color_comercial VARCHAR,
                                                       cliente VARCHAR, cliente_catalogo VARCHAR,
                                                       secuencia INTEGER, porcentaje_descuento_original NUMERIC)
        LOOP
            -- VALIDACIONES
            IF _d.descripcion = '' THEN
                RAISE EXCEPTION 'La descripción del item: % no puede estar vacía', _d.item;
            END IF;

            -- DETALLE ORIGINAL
            SELECT precio, precio_manual
            INTO _detalle_original
            FROM ordenes_venta.pedidos_detalle
            WHERE numero_pedido = _r.numero_pedido
              AND item = _d.item
              AND descripcion = _d.descripcion_original
              AND porcentaje_descuento = _d.porcentaje_descuento_original;

            -- ACTUALIZA EL DETALLE DEL PEDIDO
            WITH t AS (
                UPDATE ordenes_venta.pedidos_detalle t1
                    SET subtotal = _d.subtotal,
                        descripcion = _d.descripcion,
                        porcentaje_descuento = _d.porcentaje_descuento,
                        precio = _d.precio,
                        precio_manual = _d.precio_manual
                    WHERE t1.numero_pedido = _r.numero_pedido
                        AND t1.item = _d.item
                        AND t1.descripcion = _d.descripcion_original
                        AND t1.porcentaje_descuento = _d.porcentaje_descuento_original
                    RETURNING t1.subtotal, t1.descripcion, t1.porcentaje_descuento,
                        t1.precio, t1.precio_manual, t1.item, t1.secuencia, t1.cliente,
                        t1.cliente_catalogo, t1.color_comercial)
            -- Interfaz
            INSERT
            INTO sistema.interface
                (modulo, proceso, tabla, usuarios, directorio, buscar, sql)
            SELECT 'ORDENES DE VENTA',
                   'UPDATE1',
                   'Sotran01',
                   _r.creacion_usuario,
                   'V:\sbtpro\SODATA\',
                   '',
                   'UPDATE v:\sbtpro\SODATA\Sotran01 ' ||
                   'set extprice = ' || t.subtotal::varchar || ', ' ||
                   '  descrip = [' || t.descripcion || '], ' ||
                   '  disc = ' || t.porcentaje_descuento::varchar || ', ' ||
                   '  price = ' || t.precio::varchar || ', ' ||
                   '  macode = [' || t.precio_manual || '] ' ||
                   'Where sono = [' || LPAD(_r.numero_pedido::varchar, 10, ' ') || '] ' ||
                   '  And item = [' || RPAD(t.item, 15, ' ') || '] ' ||
                   '  And descrip = [' || _d.descripcion_original || '] ' ||
                   '  And disc = ' || _d.porcentaje_descuento_original::varchar
            FROM t
            WHERE _interface_activo;

            -- INSERTA EN LA BITACORA
            INSERT INTO ordenes_venta.pedidos_detalle_bitacora(numero_pedido, item, secuencia, cliente,
                                                               cliente_catalogo, color_comercial,
                                                               porcentaje_descuento_anterior,
                                                               porcentaje_descuento_nuevo, precio_anterior,
                                                               precio_nuevo,
                                                               descripcion_anterior, descripcion_nueva,
                                                               creacion_usuario, creacion_fecha)
            VALUES (_r.numero_pedido, _d.item, _d.secuencia, _d.cliente, _d.cliente_catalogo, _d.color_comercial,
                    _d.porcentaje_descuento_original, _d.porcentaje_descuento, _detalle_original.precio,
                    _d.precio, _d.descripcion_original, _d.descripcion, _r.creacion_usuario, CURRENT_TIMESTAMP);
            p_count_updates = p_count_updates + 1;

        END LOOP;

    -- Verifica si se realizó algún update
    IF p_count_updates = 0 THEN
        RAISE EXCEPTION 'No se ha Realizado ningun update en el detalle...';
    END IF;

    /******************** Enviar el Mail ********************/
    -- Se busca el email en los parametros del sistema
    SELECT alfa
    INTO p_email
    FROM sistema.parametros
    WHERE modulo_id = 'SISTEMA'
      AND codigo = 'CORREO_AUTO_CAMBIO_PEDIDO';

    IF p_email IS NULL THEN
        RAISE EXCEPTION 'No se ha configurado el EMAIL para enviar la notificación de cambio de pedido';
    END IF;
    -- Se obtiene el número de email
    SELECT MAX(t1.numero_email) + 1
    INTO p_numero_email
    FROM sistema.email_masivo_cabecera t1;

    -- Obtencion del nombre del usuario
    SELECT nombres
    INTO v_nombre_usuario
    FROM sistema.usuarios
    WHERE codigo = _r.creacion_usuario;
    -- Se inserta en la cabecera del email(Asunto y Cuerpo del email)
    INSERT
    INTO sistema.email_masivo_cabecera(numero_email, fecha, asunto_email, mensaje_email, imagen_email_cabecera,
                                       nombre_empresa, estado)
    VALUES (p_numero_email, CURRENT_DATE, 'Notificación Automatica de MODIFICACION EN PEDIDO MAYORISTA.',
            'Estimado, <br/>' ||
            'Se ha registrado la Modificacion de un Pedido de Mayorista, ' || -- || p_centro_costo ||
            '.<br/>' ||
            'Pedido Nro: ' || _r.numero_pedido::varchar || ', del cliente: ' || v_cliente || '. ' ||
            COALESCE(v_nombre_cliente, '') ||
            '<br/>' ||
            'Usuario: ' || COALESCE(v_nombre_usuario, '') ||
            '.<br/>' ||
            'Email Generado automáticamente por el sistema, no responda este mensaje ',
            '', 'Pasamanería S.A.', 'P');

    -- Se inserta en el detalle del email(Destinatarios del email)
    INSERT INTO sistema.email_masivo_detalle(numero_email, emails, nombre_destinatario)
    VALUES (p_numero_email, p_email, '');

    -- Bloqueamos el pedido para cambios
    UPDATE ordenes_venta.pedidos_cabecera as pc
    SET aprobacion_cambio = FALSE
    WHERE pc.numero_pedido = _r.numero_pedido;
    /***************/
    respuesta = 'OK';
    /***************/
END;
$function$
;
