-- drop function puntos_venta.reporte_cierre_caja(pnumero_caja character varying, reimpresion boolean)

CREATE OR REPLACE FUNCTION puntos_venta.reporte_cierre_caja(pnumero_caja numeric, reimpresion boolean)
    RETURNS TABLE
            (
                descripcion text
            )
    LANGUAGE plpgsql
AS
$function$
DECLARE
    convertNumero_caja     numeric;
    _rcaja_totales         record;
    _rAuxQueda             record;
    -- TOTALES
    v_cambio               numeric;
    v_cambio_real          numeric;
    v_cambio_contrato      numeric;
    v_cambio_real_contrato numeric;
    wSaldoCambio           numeric;
    v_efectivo_cierre      numeric;
    wTotalQueda            numeric := 0;
    wDenominacion          numeric;
    wRegistro              integer;
    wTotal                 numeric;
    wCantidad              integer;
    wDescripcion           text;
    wCuantos               integer;
    wDiferencia            numeric;
    wCuanDif               numeric;
    wEntero                integer;
BEGIN
    -- wTablaAuxCierre
    DROP TABLE IF EXISTS _tempAuxCierre;
    CREATE TEMP TABLE _tempAuxCierre
    (
        secuencia    SERIAL,
        denominacion text,
        cantidad     integer,
        total        numeric
    );
    -- wTablaAuxQueda
    DROP TABLE IF EXISTS _tempAuxQueda;
    CREATE TEMP TABLE _tempAuxQueda
    (
        secuencia    SERIAL,
        denominacion text,
        cantidad     integer,
        total        numeric
    );
    -- wTablaAuxReporte
    DROP TABLE IF EXISTS _tempAuxReporte;
    CREATE TEMP TABLE _tempAuxReporte
    (
        descripcion text
    );

    convertNumero_caja = pnumero_caja::numeric;
    -- Registro de Caja Totales
    SELECT ct.efectivo_apertura,
           ct.fecha_apertura,
           ct.fecha_cierre,
           ct.hora_cierre,
           ct.caja,
           ct.vendedor,
           ct.numero_caja,
           ct.efectivo,
           ct.efectivo_devoluciones,
           ct.efectivo_contrato,
           ct.venta_tarjetas_pasa
    INTO _rcaja_totales
    FROM puntos_venta.caja_totales ct
    WHERE numero_caja = convertNumero_caja;

    -- Calcular totales de cambios
    SELECT SUM(cambio) cambio, SUM(cambio_real) cambioreal
    INTO v_cambio, v_cambio_real
    FROM puntos_venta.pagos
    WHERE numero_caja = _rcaja_totales.numero_caja;
    SELECT SUM(cambio) cambio, SUM(cambio_real) cambioreal
    INTO v_cambio_contrato, v_cambio_real_contrato
    FROM puntos_venta.contrato_pagos
    WHERE numero_caja = _rcaja_totales.numero_caja;
    wSaldoCambio = (v_cambio - v_cambio_real) + (v_cambio_contrato - v_cambio_real_contrato);
    -- Insertar datos en _tempAuxCierre
    INSERT
    INTO _tempAuxCierre (denominacion, cantidad, total)
    SELECT denominacion, cantidad, total
    FROM puntos_venta.detalle_efectivo
    WHERE numero_caja = _rcaja_totales.numero_caja
    ORDER BY secuencia DESC;

    -- Calcular efectivo en caja
    SELECT SUM(total)
    INTO v_efectivo_cierre
    FROM _tempAuxCierre;

    -- Insertar datos en _tempAuxQueda desde _tempAuxCierre donde el primer carácter de denominacion es 'C'
    INSERT INTO _tempAuxQueda (denominacion, cantidad, total)
    SELECT denominacion, cantidad, total
    FROM _tempAuxCierre
    WHERE LEFT(denominacion, 1) = 'C'
      AND cantidad > 0
    ORDER BY secuencia DESC;

    -- Insertar datos en _tempAuxQueda desde _tempAuxCierre donde el primer carácter de denominacion es 'B'
    INSERT INTO _tempAuxQueda (denominacion, cantidad, total)
    SELECT denominacion, cantidad, total
    FROM _tempAuxCierre
    WHERE LEFT(denominacion, 1) = 'B'
      AND cantidad > 0
    ORDER BY secuencia DESC;

    FOR _rAuxQueda IN SELECT * FROM _tempAuxQueda ORDER BY secuencia
        LOOP
            IF SUBSTRING(_rAuxQueda.denominacion, 1, 14) = 'BILLETES de 100' THEN
                wDenominacion := CAST(RIGHT(_rAuxQueda.denominacion, 3) AS numeric);
            ELSE
                IF SUBSTRING(_rAuxQueda.denominacion, 1, 1) = 'C' THEN
                    wDenominacion := CAST(RIGHT(_rAuxQueda.denominacion, 2) AS numeric) / 100;
                ELSE
                    wDenominacion := CAST(RIGHT(_rAuxQueda.denominacion, 2) AS numeric);
                END IF;
            END IF;

            IF wTotalQueda + _rAuxQueda.total <= _rcaja_totales.efectivo_apertura THEN
                wTotalQueda := wTotalQueda + _rAuxQueda.total;
            ELSE
                wRegistro := _rAuxQueda.secuencia;
                wTotal := _rAuxQueda.total;
                wCantidad := _rAuxQueda.cantidad;
                wDescripcion := _rAuxQueda.denominacion;
                EXIT;
            END IF;

            wTotal := _rAuxQueda.total;
            wCantidad := _rAuxQueda.cantidad;
            wDescripcion := _rAuxQueda.denominacion;
        END LOOP;

    IF wTotalQueda + wTotal > _rcaja_totales.efectivo_apertura THEN
        wCuantos := 1;
        WHILE wCuantos <= wCantidad
            LOOP
                wTotalQueda := wTotalQueda + wDenominacion;
                IF wTotalQueda > _rcaja_totales.efectivo_apertura THEN
                    EXIT;
                END IF;
                wCuantos := wCuantos + 1;
            END LOOP;

        -- Actualizar la tabla _tempAuxQueda
        UPDATE _tempAuxQueda
        SET cantidad = wCuantos,
            total    = wCuantos * wDenominacion
        WHERE denominacion = wDescripcion;

        DELETE FROM _tempAuxQueda WHERE secuencia > wRegistro;

        wDiferencia = ROUND(wTotalQueda - _rcaja_totales.efectivo_apertura, 2);

        FOR _rAuxQueda IN (SELECT * FROM _tempAuxQueda ORDER BY secuencia DESC)
            LOOP
                IF _rAuxQueda.denominacion::varchar = 'BILLETES de 100' THEN
                    wDenominacion = RIGHT(_rAuxQueda.denominacion, 3)::numeric / 1;
                ELSE
                    IF LEFT(_rAuxQueda.denominacion::varchar, 1) = 'C' THEN
                        wDenominacion = RIGHT(_rAuxQueda.denominacion, 2)::numeric / 100;
                    ELSE
                        wDenominacion = RIGHT(_rAuxQueda.denominacion, 2)::numeric / 1;
                    END IF;
                END IF;
                IF wDiferencia >= wDenominacion THEN
                    wCuanDif := wDiferencia / wDenominacion;
                    wRegistro := _rAuxQueda.secuencia;
                    IF wCuanDif <= _rAuxQueda.cantidad::integer THEN
                        wEntero = TRUNC(wCuanDif)::integer;
                        UPDATE _tempAuxQueda
                        SET cantidad = cantidad - wEntero
                        WHERE secuencia = wRegistro;
                        UPDATE _tempAuxQueda
                        SET total = cantidad * wDenominacion
                        WHERE secuencia = wRegistro;
                        IF wEntero = wCuanDif THEN
                            wTotalQueda = wTotalQueda - (wCuanDif * wDenominacion);
                            EXIT;
                        ELSE
                            wTotalQueda = wTotalQueda - (wEntero * wDenominacion);
                            wDiferencia = ROUND(wTotalQueda - _rcaja_totales.efectivo_apertura, 2);
                        END IF;
                    ELSE
                        wTotalQueda = wTotalQueda - _rAuxQueda.total;
                        wDiferencia = ROUND(wDiferencia - _rAuxQueda.total, 2);
                        UPDATE _tempAuxQueda
                        SET cantidad = 0,
                            total    = 0
                        WHERE secuencia = wRegistro;
                        DELETE FROM _tempAuxQueda WHERE secuencia = wRegistro;
                    END IF;
                END IF;
            END LOOP;
    END IF;

    -- Armado de reporte
    IF reimpresion THEN
        INSERT INTO _tempAuxReporte (descripcion) VALUES ('     ****** REIMPRESION ******      ');
    END IF;
    INSERT INTO _tempAuxReporte (descripcion) VALUES ('     REPORTE DE CIERRE DE CAJA      ');
    INSERT INTO _tempAuxReporte (descripcion)
    VALUES ('   ABIERTA EL ' || TO_CHAR(_rcaja_totales.fecha_apertura, 'yyyy/mm/dd'));
    INSERT INTO _tempAuxReporte (descripcion)
    VALUES ('Cierre ' || TO_CHAR(_rcaja_totales.fecha_cierre, 'yyyy/mm/dd') || '-*- Hora: ' ||
            TO_CHAR(TO_TIMESTAMP(_rcaja_totales.hora_cierre, 'HH24:MI:SS'), 'HH12:MI:SS AM'));
    INSERT INTO _tempAuxReporte (descripcion)
    VALUES ('Caja: ' || _rcaja_totales.caja || ' / ' || _rcaja_totales.numero_caja ||
            '     -*-  Cajera: ' ||
            _rcaja_totales.vendedor);
    INSERT INTO _tempAuxReporte (descripcion) VALUES (' ');
    INSERT INTO _tempAuxReporte (descripcion) VALUES ('    ***** DETALLE DE DOLARES EFECTIVO ******');
    INSERT INTO _tempAuxReporte (descripcion)
    VALUES ('DENOMINACION                Cant.            VALOR');
    WITH cierre AS (SELECT denominacion, cantidad, total
                    FROM _tempAuxCierre),
         queda AS (SELECT denominacion, cantidad, total
                   FROM _tempAuxQueda),
         reporte AS (SELECT COALESCE(c.denominacion, q.denominacion)          AS denominacion,
                            COALESCE(c.cantidad, 0) - COALESCE(q.cantidad, 0) AS cantidad,
                            COALESCE(c.total, 0) - COALESCE(q.total, 0)       AS total
                     FROM cierre c
                              FULL JOIN queda q ON c.denominacion = q.denominacion
                     WHERE COALESCE(c.cantidad, 0) - COALESCE(q.cantidad, 0) <> 0)
    INSERT
    INTO _tempAuxReporte (descripcion)
    SELECT *
    FROM (SELECT denominacion || '           ' || ROUND(cantidad, 2) ||
                 '   =     ' || ROUND(total, 2)
          FROM reporte
          UNION ALL
          SELECT 'TOTAL DOLARES           ' ||
                 ROUND(v_efectivo_cierre - wTotalQueda, 2)) AS x;
    INSERT INTO _tempAuxReporte (descripcion)
    VALUES ('--------------------------------------------------');

    /***************************PAGOSDEUNA***********************************/

    WITH original_query AS (SELECT codigo_documento || '          ' || ROUND(monto_pago, 2) AS detalle_pago,
                                   monto_pago
                            FROM puntos_venta.pagos
                            WHERE numero_caja = _rcaja_totales.numero_caja
                              AND codigo_pago = 'D'
                            ORDER BY codigo_pago, LEFT(verificacion, 8),
                                     SUBSTRING(codigo_documento, 8, 12)),
         total_query AS (SELECT SUM(monto_pago) AS total_pago
                         FROM original_query)
    INSERT
    INTO _tempAuxReporte (descripcion)
    SELECT *
    FROM ((SELECT '    ***** DETALLE DE COMPRAS CON -DEUNA-  ******')
          UNION ALL
          (SELECT 'TRANSACCION     VALOR')
          UNION ALL
          SELECT detalle_pago
          FROM original_query
          UNION ALL
          SELECT 'TOTAL COMPRAS CON -DEUNA-  ' || ROUND(total_pago, 2)
          FROM total_query
          UNION ALL
          SELECT '--------------------------------------------------') AS X
    WHERE EXISTS (SELECT 1 FROM original_query);

    /***************************Venta de tarjetas PASA***********************************/

    IF _rcaja_totales.venta_tarjetas_pasa > 0 THEN
        INSERT INTO _tempAuxReporte (descripcion)
        VALUES ('    ***** DETALLE DE -TARJETAS PASA- VENDIDAS  ******'),
               ('EFECTIVO -TARJETAS PASA- VENDIDAS   ' || ROUND(_rcaja_totales.venta_tarjetas_pasa, 2)),
               ('--------------------------------------------------');
    END IF;

    /***************************PAGOSCHEQUES***********************************/

    WITH original_query AS (SELECT LEFT(verificacion, 8) || '     ' ||
                                   SUBSTRING(codigo_documento FROM 8 FOR 12) || '     ' ||
                                   LPAD(TRIM(codigo_documento), 7, '0') || '     ' ||
                                   ROUND(monto_pago, 2) AS detalle_pago,
                                   monto_pago
                            FROM puntos_venta.pagos
                            WHERE numero_caja = _rcaja_totales.numero_caja
                              AND codigo_pago = 'E'
                            ORDER BY codigo_pago, LEFT(verificacion, 8),
                                     SUBSTRING(codigo_documento, 8, 12)),
         total_query AS (SELECT SUM(monto_pago) AS total_pago
                         FROM original_query)
    INSERT
    INTO _tempAuxReporte (descripcion)
    SELECT *
    FROM (SELECT '    ***** DETALLE DE CHEQUES ******'
          UNION ALL
          SELECT 'BANCO          CUENTA       CHEQUE         MONTO'
          UNION ALL
          SELECT detalle_pago
          FROM original_query
          UNION ALL
          SELECT 'TOTAL CHEQUES DOLARES  ' || ROUND(total_pago, 2)
          FROM total_query
          UNION ALL
          SELECT '--------------------------------------------------') capDeun
    WHERE EXISTS (SELECT 1 FROM original_query);

    /***************************DETALLE DE COMPRAS TARJETAS PASA ***********************************/

    WITH original_query AS (SELECT LEFT(referencia, 8) || '     ' ||
                                   LEFT(tipo_pago, 8) || '     ' ||
                                   LPAD(codigo_documento, 13) || '     ' ||
                                   ROUND(monto_pago, 2) AS detalle_pago,
                                   monto_pago
                            FROM puntos_venta.pagos
                            WHERE numero_caja = _rcaja_totales.numero_caja
                              AND codigo_pago = 'T'),
         total_query AS (SELECT SUM(monto_pago) AS total_pago
                         FROM original_query)
    INSERT
    INTO _tempAuxReporte (descripcion)
    SELECT *
    FROM (SELECT '    ***** DETALLE DE COMPRAS CON -TARJETAS PASA- ******'
          UNION ALL
          SELECT 'TRANSACCION     TIPO       TARJETA            VALOR'
          UNION ALL
          SELECT detalle_pago
          FROM original_query
          UNION ALL
          SELECT 'TOTAL COMPRAS CON -TARJETAS PASA-  ' || ROUND(_rcaja_totales.venta_tarjetas_pasa, 2) || ' = ' ||
                 ROUND(total_pago, 2)
          FROM total_query
          UNION ALL
          SELECT '--------------------------------------------------') capDeun
    WHERE EXISTS (SELECT 1 FROM original_query);

    /***************************DETALLE DE COMPRAS bonos PASA ***********************************/

    WITH original_query AS (SELECT cedula_ruc || '            ' ||
                                   ROUND(monto_pago, 2) AS detalle_pago,
                                   monto_pago
                            FROM puntos_venta.pagos
                            WHERE numero_caja = _rcaja_totales.numero_caja
                              AND codigo_pago = 'O'),
         total_query AS (SELECT SUM(monto_pago) AS total_pago
                         FROM original_query)
    INSERT
    INTO _tempAuxReporte (descripcion)
    SELECT *
    FROM (SELECT '    ***** DETALLE DE COMPRAS CON -BONOS PASA- ******'
          UNION ALL
          SELECT 'CEDULA            VALOR'
          UNION ALL
          SELECT detalle_pago
          FROM original_query
          UNION ALL
          SELECT 'TOTAL COMPRAS CON -BONOS PASA-   ' || ROUND(total_pago, 2)
          FROM total_query
          UNION ALL
          SELECT '--------------------------------------------------') capDeun
    WHERE EXISTS (SELECT 1 FROM original_query);

    /***************************DETALLE DE COMPRAS Billetes PASA ***********************************/

    WITH original_query AS (SELECT LEFT(codigo_documento, 13) || '            ' ||
                                   ROUND(monto_pago, 2) AS detalle_pago,
                                   monto_pago
                            FROM puntos_venta.pagos
                            WHERE numero_caja = _rcaja_totales.numero_caja
                              AND codigo_pago = 'I'),
         total_query AS (SELECT SUM(monto_pago) AS total_pago
                         FROM original_query)
    INSERT
    INTO _tempAuxReporte (descripcion)
    SELECT *
    FROM (SELECT '    ***** DETALLE DE COMPRAS CON -BILLETES PASA- ******'
          UNION ALL
          SELECT 'BILLETE            VALOR'
          UNION ALL
          SELECT detalle_pago
          FROM original_query
          UNION ALL
          SELECT 'TOTAL COMPRAS CON -BILLETES PASA-   ' || ROUND(total_pago, 2)
          FROM total_query
          UNION ALL
          SELECT '--------------------------------------------------') capDeun
    WHERE EXISTS (SELECT 1 FROM original_query);

    /***************************DETALLE DE COMPRAS Billetes SOL ***********************************/

    WITH original_query AS (SELECT LEFT(codigo_documento, 13) || '            ' ||
                                   ROUND(monto_pago, 2) AS detalle_pago,
                                   monto_pago
                            FROM puntos_venta.pagos
                            WHERE numero_caja = _rcaja_totales.numero_caja
                              AND codigo_pago = 'S'),
         total_query AS (SELECT SUM(monto_pago) AS total_pago
                         FROM original_query)
    INSERT
    INTO _tempAuxReporte (descripcion)
    SELECT *
    FROM (SELECT '    ***** DETALLE DE COMPRAS CON -BILLETES SOL- ******'
          UNION ALL
          SELECT 'BILLETE            VALOR'
          UNION ALL
          SELECT detalle_pago
          FROM original_query
          UNION ALL
          SELECT 'TOTAL COMPRAS CON -BILLETES SOL-   ' || ROUND(total_pago, 2)
          FROM total_query
          UNION ALL
          SELECT '--------------------------------------------------') capDeun
    WHERE EXISTS (SELECT 1 FROM original_query);

    /***************************PAGOSTARJETAS***********************************/

    WITH original_query AS (SELECT tipo_pago || '     ' ||
                                   codigo_documento ||
                                   verificacion ||
                                   CASE WHEN verificacion = 'M' THEN '   ***' ELSE '' END ||
                                   '     ' ||
                                   ROUND(monto_pago, 2) AS detalle_pago,
                                   monto_pago
                            FROM puntos_venta.pagos
                            WHERE numero_caja = _rcaja_totales.numero_caja
                              AND codigo_pago IN ('0', '1', '2', '3', '4', '5', '6', '7', '8', '9')
                            ORDER BY codigo_pago, codigo_documento, verificacion),
         total_query AS (SELECT SUM(monto_pago) AS total_pago
                         FROM original_query)
    INSERT
    INTO _tempAuxReporte (descripcion)
    SELECT *
    FROM (SELECT '    ***** DETALLE DE TARJETAS DE CREDITO  ******'
          UNION ALL
          SELECT 'NOMBRE        NUMERO                      MONTO'
          UNION ALL
          SELECT detalle_pago
          FROM original_query
          UNION ALL
          SELECT 'TARJETAS DE CREDITO DOLARES  ' || ROUND(total_pago, 2)
          FROM total_query
          UNION ALL
          SELECT '--------------------------------------------------') capDeun
    WHERE EXISTS (SELECT 1 FROM original_query);

    /***************************PAYPHONE***********************************/

    WITH original_query AS (SELECT codigo_documento || '        ' ||
                                   verificacion || '        ' ||
                                   ROUND(monto_pago, 2) AS detalle_pago,
                                   monto_pago
                            FROM puntos_venta.pagos
                            WHERE numero_caja = _rcaja_totales.numero_caja
                              AND codigo_pago = 'P'),
         total_query AS (SELECT SUM(monto_pago) AS total_pago
                         FROM original_query)
    INSERT
    INTO _tempAuxReporte (descripcion)
    SELECT *
    FROM (SELECT '    ***** DETALLE DE PAGOS PAYPHONE ******'
          UNION ALL
          SELECT 'TRANSACCION       CELULAR                      MONTO'
          UNION ALL
          SELECT detalle_pago
          FROM original_query
          UNION ALL
          SELECT 'PAGOS PAYPHONE DOLARES   ' || ROUND(total_pago, 2)
          FROM total_query
          UNION ALL
          SELECT '--------------------------------------------------') capDeun
    WHERE EXISTS (SELECT 1 FROM original_query);

    /***************************VENTASVALES***********************************/

    WITH original_query AS (SELECT LEFT(codigo_documento, 8) || '     ' || ROUND(monto_pago, 2) AS detalle_pago,
                                   monto_pago
                            FROM puntos_venta.pagos
                            WHERE numero_caja = _rcaja_totales.numero_caja
                              AND codigo_pago = 'Q'
                              AND monto_pago > 0
                            ORDER BY codigo_pago, codigo_documento),
         total_query AS (SELECT SUM(monto_pago) AS total_pago
                         FROM original_query)
    INSERT
    INTO _tempAuxReporte (descripcion)
    SELECT *
    FROM (SELECT '   *** DETALLE DE VENTA CON VALES ***'
          UNION ALL
          SELECT 'NUMERO                          MONTO'
          UNION ALL
          SELECT detalle_pago
          FROM original_query
          UNION ALL
          SELECT 'TOTAL VENTA CON VALES  ' || ROUND(total_pago, 2)
          FROM total_query
          UNION ALL
          SELECT '--------------------------------------------------') capDeun
    WHERE EXISTS (SELECT 1 FROM original_query);

    /***************************BONOS INSTANTANEOS***********************************/

    WITH original_query AS (SELECT LEFT(codigo_documento, 8) || '                          ' ||
                                   ROUND(monto_pago, 2) AS detalle_pago,
                                   monto_pago
                            FROM puntos_venta.pagos
                            WHERE numero_caja = _rcaja_totales.numero_caja
                              AND codigo_pago = 'N'),
         total_query AS (SELECT SUM(monto_pago) AS total_pago
                         FROM original_query)
    INSERT
    INTO _tempAuxReporte (descripcion)
    SELECT *
    FROM (SELECT '    ***** DETALLE DE VENTA CON BONOS INSTANTANEOS ******'
          UNION ALL
          SELECT 'NUMERO                          MONTO'
          UNION ALL
          SELECT detalle_pago
          FROM original_query
          UNION ALL
          SELECT 'TOTAL VENTA CON BONOS INSTANTANEOS   ' || ROUND(total_pago, 2)
          FROM total_query
          UNION ALL
          SELECT '--------------------------------------------------') capDeun
    WHERE EXISTS (SELECT 1 FROM original_query);

    /***************************VALESEMITIDOS***********************************/

    WITH original_query AS (SELECT LEFT(codigo_documento, 8) || '     ' || ROUND(monto_pago, 2) AS detalle_pago,
                                   monto_pago
                            FROM puntos_venta.pagos
                            WHERE numero_caja = _rcaja_totales.numero_caja
                              AND codigo_pago = 'Q'
                              AND monto_pago < 0
                            ORDER BY codigo_pago, codigo_documento),
         total_query AS (SELECT SUM(monto_pago) AS total_pago
                         FROM original_query)
    INSERT
    INTO _tempAuxReporte (descripcion)
    SELECT *
    FROM (SELECT '*** DETALLE DE VALES EMITIDOS ***'
          UNION ALL
          SELECT 'NUMERO                          MONTO'
          UNION ALL
          SELECT detalle_pago
          FROM original_query
          UNION ALL
          SELECT 'TOTAL VALES EMITIDOS  ' || ROUND(total_pago, 2)
          FROM total_query
          UNION ALL
          SELECT '--------------------------------------------------') capDeun
    WHERE EXISTS (SELECT 1 FROM original_query);

    /***************************VALESXEFECTIVO***********************************/

    WITH original_query AS (SELECT LEFT(codigo_documento, 8) || '     ' || ROUND(monto_pago, 2) AS detalle_pago,
                                   monto_pago
                            FROM puntos_venta.pagos
                            WHERE numero_caja = _rcaja_totales.numero_caja
                              AND codigo_pago = 'Q'
                              AND SUBSTRING(referencia FROM 8 FOR 3)::INTEGER >= 900
                            ORDER BY codigo_pago, codigo_documento),
         total_query AS (SELECT SUM(monto_pago) AS total_pago
                         FROM original_query)
    INSERT
    INTO _tempAuxReporte (descripcion)
    SELECT *
    FROM (SELECT '*** VALES CANJEADOS x EFECTIVO ***'
          UNION ALL
          SELECT 'NUMERO                          MONTO'
          UNION ALL
          SELECT detalle_pago
          FROM original_query
          UNION ALL
          SELECT 'TOTAL VALES CANJEADOS  ' || ROUND(total_pago, 2)
          FROM total_query
          UNION ALL
          SELECT '--------------------------------------------------') capDeun
    WHERE EXISTS (SELECT 1 FROM original_query);

    /***************************RETENCION***********************************/

    WITH original_query AS (SELECT RPAD(codigo_documento, 30, ' ') || '     ' || ROUND(monto_pago, 2) AS detalle_pago,
                                   monto_pago
                            FROM puntos_venta.pagos
                            WHERE numero_caja = _rcaja_totales.numero_caja
                              AND codigo_pago = 'Y'),
         total_query AS (SELECT SUM(monto_pago) AS total_pago
                         FROM original_query)
    INSERT
    INTO _tempAuxReporte (descripcion)
    SELECT *
    FROM (SELECT '*** DETALLE COMPROB. DE RETENCION ***'
          UNION ALL
          SELECT 'NUMERO                          MONTO'
          UNION ALL
          SELECT detalle_pago
          FROM original_query
          UNION ALL
          SELECT 'TOTAL COMPR.RETENCION DOLARES  ' || ROUND(total_pago, 2)
          FROM total_query
          UNION ALL
          SELECT '--------------------------------------------------') capDeun
    WHERE EXISTS (SELECT 1 FROM original_query);

    /***************************PAGOSCOMIPASA***********************************/

    WITH original_query AS (SELECT LEFT(pp.codigo_documento, 5) || ' ' ||
                                   LEFT(p2.apellido_paterno || ' ' || p2.nombre1, 20) ||
                                   '     ' ||
                                   ROUND(pp.monto_pago, 2) AS detalle_pago,
                                   pp.monto_pago
                            FROM puntos_venta.pagos pp
                                     JOIN roles.personal p2
                                          ON p2.codigo = LEFT(pp.codigo_documento, 5)
                            WHERE pp.numero_caja = _rcaja_totales.numero_caja
                              AND pp.codigo_pago = 'L'
                            ORDER BY pp.codigo_pago, pp.codigo_documento),
         total_query AS (SELECT SUM(monto_pago) AS total_pago
                         FROM original_query)
    INSERT
    INTO _tempAuxReporte (descripcion)
    SELECT *
    FROM (SELECT '   ** DETALLE  CREDITO  PASA **'
          UNION ALL
          SELECT 'EMPLEADO                         VALOR'
          UNION ALL
          SELECT detalle_pago
          FROM original_query
          UNION ALL
          SELECT 'TOTAL CREDITO-PASA.....               ' || ROUND(total_pago, 2)
          FROM total_query
          UNION ALL
          SELECT '--------------------------------------------------') capDeun
    WHERE EXISTS (SELECT 1 FROM original_query);

    /***************************QUEDADOLARES***********************************/

    IF wTotalQueda > 0 THEN
        INSERT INTO _tempAuxReporte (descripcion) VALUES (' *** DETALLE DE QUEDA DOLARES ***');
        INSERT INTO _tempAuxReporte (descripcion)
        VALUES ('DENOMINACION             Cant.               VALOR');
        INSERT INTO _tempAuxReporte (descripcion) VALUES ('   ');
        FOR _rAuxQueda IN (SELECT * FROM _tempAuxQueda WHERE cantidad <> 0 ORDER BY secuencia DESC)
            LOOP
                INSERT INTO _tempAuxReporte (descripcion)
                VALUES (_rAuxQueda.denominacion || '         ' || _rAuxQueda.cantidad ||
                        '   =        ' || ROUND(_rAuxQueda.total, 2));
            END LOOP;
        INSERT INTO _tempAuxReporte (descripcion) VALUES ('TOTAL QUEDA .....     ' || ROUND(wTotalQueda, 2));
        INSERT INTO _tempAuxReporte (descripcion)
        VALUES ('--------------------------------------------------');
    END IF;

    /***************************TOTALES***********************************/
    IF _rcaja_totales.efectivo + _rcaja_totales.efectivo_devoluciones + _rcaja_totales.efectivo_contrato < 0 THEN
        INSERT INTO _tempAuxReporte (descripcion)
        VALUES ('EFECTIVO (VENTAS) DOLARES           0.00');

        wDiferencia = v_efectivo_cierre - wTotalQueda - wSaldoCambio;
    ELSE
        INSERT INTO _tempAuxReporte (descripcion)
        VALUES ('EFECTIVO (VENTAS) DOLARES           ' ||
                ROUND(_rcaja_totales.efectivo + _rcaja_totales.efectivo_devoluciones + _rcaja_totales.efectivo_contrato,
                      2));

        wDiferencia = COALESCE(v_efectivo_cierre, 0) - COALESCE(wTotalQueda, 0) -
                      (_rcaja_totales.efectivo + _rcaja_totales.efectivo_devoluciones +
                       _rcaja_totales.efectivo_contrato) - COALESCE(wSaldoCambio, 0);
    END IF;

    IF wSaldoCambio <> 0 THEN
        INSERT INTO _tempAuxReporte (descripcion)
        VALUES ('DIFER. POR CAMBIO DOLARES           ' || ROUND(wSaldoCambio, 2));
    END IF;
    INSERT INTO _tempAuxReporte (descripcion)
    VALUES ('EFECTIVO ARQUEO DOLARES             ' || ROUND(v_efectivo_cierre - wTotalQueda, 2));

    IF wDiferencia = 0 THEN
        INSERT INTO _tempAuxReporte (descripcion)
        VALUES ('DIFER. DOLARES                      ' || ABS(ROUND(wDiferencia, 2)));
    ELSIF wDiferencia > 0 THEN
        INSERT INTO _tempAuxReporte (descripcion)
        VALUES ('DIFER. DOLARES  A FAVOR             ' || ABS(ROUND(wDiferencia, 2)));
    ELSE
        INSERT INTO _tempAuxReporte (descripcion)
        VALUES ('DIFER. DOLARES  EN CONTRA           ' || ABS(ROUND(wDiferencia, 2)));
    END IF;
    /***************************FINAL***********************************/
    INSERT INTO _tempAuxReporte (descripcion) VALUES (' ');
    INSERT INTO _tempAuxReporte (descripcion)
    VALUES (' OBSERVACIONES: ................................. ');
    INSERT INTO _tempAuxReporte (descripcion) VALUES (' ');
    INSERT INTO _tempAuxReporte (descripcion) VALUES (' ');
    INSERT INTO _tempAuxReporte (descripcion)
    VALUES (' FIRMA: ......................................... ');
    INSERT INTO _tempAuxReporte (descripcion) VALUES (' ');
    INSERT INTO _tempAuxReporte (descripcion) VALUES (' ');

    RETURN QUERY
        SELECT tux.descripcion
        FROM _tempAuxReporte AS tux
        WHERE tux.descripcion IS NOT NULL;
END
$function$
;