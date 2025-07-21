/*
 drop function puntos_venta.reporte_factura(p_factura character varying, p_tipo varchar)

 */

CREATE OR REPLACE FUNCTION puntos_venta.reporte_factura(p_factura character varying, p_tipo varchar)
    RETURNS TABLE
            (
                referencia                character varying,
                fecha                     date,
                vendedor                  character varying,
                hora                      varchar,
                clave_acceso              character varying,
                fecha_autorizacion        date,
                nombre                    text,
                direccion                 character varying,
                cedula_ruc                character varying,
                referencia1               character varying,
                item                      character varying,
                descripcion               character varying,
                unidad_medida             character varying,
                cantidad                  numeric,
                precio                    numeric,
                descuento                 numeric,
                total_precio              numeric,
                subtotal                  numeric,
                iva                       numeric,
                monto_total               numeric,
                pagos                     text,
                deducible_vestimenta      numeric,
                factura                   character varying,
                ciudad                    character varying,
                total_descuento           numeric,
                numero_articulos          numeric,
                tipo_factura              text,
                ivavigente                text,
                imprime_comentario        boolean,
                comentario                character varying,
                valor_descuento_adicional numeric
            )
    LANGUAGE plpgsql
AS
$function$
DECLARE
    v_referencia           text;
    v_pago                 text;
    v_pago_efectivo        text;
    v_deducible_vestimenta numeric;
    v_ciudad               varchar;
    v_total_descuento      numeric;
    v_numero_articulos     numeric;
    _rpagos                record;
BEGIN
    /*
        p_tipo = 'F' Factura, 'C' Credito
    */
    -- Busca la referencia
    IF p_tipo = 'F' THEN
        SELECT fc.referencia
        FROM puntos_venta.facturas_cabecera fc
        WHERE fc.factura = p_factura
          AND (tipo_documento IS NULL OR tipo_documento = '')
        INTO v_referencia;
    ELSIF p_tipo = 'C' THEN
        SELECT fc.referencia
        FROM puntos_venta.facturas_cabecera fc
        WHERE fc.factura = p_factura
          AND tipo_documento = 'C'
        INTO v_referencia;
    ELSE
        RAISE EXCEPTION 'Tipo de documento no valido';
    END IF;

    IF NOT found THEN
        RAISE EXCEPTION 'No se encontro el Documento %', p_factura;
    END IF;

    -- PAGOS
    FOR _rpagos IN (SELECT pp.codigo_pago, pp.tipo_pago, pp.codigo_documento, pp.monto_pago, pp.verificacion, pp.cambio
                    FROM puntos_venta.pagos pp
                    WHERE pp.referencia = v_referencia)
        LOOP
            IF _rpagos.codigo_pago = 'B' THEN
                v_pago_efectivo := '  ' || _rpagos.tipo_pago || '   ' || ROUND(_rpagos.monto_pago, 2)::varchar ||
                                   '    RECIBIDO:  ' ||
                                   TRIM(ROUND((_rpagos.monto_pago + _rpagos.cambio), 2)::varchar) || '   CAMBIO:  ' ||
                                   ROUND(_rpagos.cambio, 2)::varchar;
            ELSIF _rpagos.codigo_pago = 'E' THEN
                v_pago := COALESCE(v_pago, '') || 'CH  ' || LEFT(_rpagos.verificacion, 8) || '/' ||
                          RIGHT(TRIM(_rpagos.codigo_documento), 7) || '/' ||
                          LEFT(_rpagos.codigo_documento, 6) || TRIM(ROUND(_rpagos.monto_pago, 2)::varchar) || '  ';
            ELSIF _rpagos.codigo_pago = 'Q' THEN
                v_pago := COALESCE(v_pago, '') || _rpagos.tipo_pago || '   ' || TRIM(_rpagos.codigo_documento) || '  ';
            ELSIF _rpagos.codigo_pago = 'Y' THEN
                v_pago :=
                        COALESCE(v_pago, '') || _rpagos.tipo_pago || '   ' || TRIM(_rpagos.codigo_documento) || '   ' ||
                        TRIM(ROUND(_rpagos.monto_pago, 2)::varchar) || '  ';
            ELSE
                v_pago :=
                        COALESCE(v_pago, '') || _rpagos.tipo_pago || '   ' ||
                        TRIM(ROUND(_rpagos.monto_pago, 2)::varchar) || '  ';
            END IF;
        END LOOP;
    v_pago = TRIM(COALESCE(v_pago, '') || COALESCE(v_pago_efectivo, ''));
    /*
        WITH pagos AS (
        SELECT
            pp.codigo_pago,
            pp.tipo_pago,
            pp.codigo_documento,
            pp.monto_pago,
            pp.verificacion,
            pp.cambio,
            CASE
                WHEN pp.codigo_pago = 'B' THEN
                    '  ' || pp.tipo_pago || '   ' || ROUND(pp.monto_pago, 2)::varchar ||
                    '    RECIBIDO:  ' || TRIM(ROUND((pp.monto_pago + pp.cambio), 2)::varchar) || '   CAMBIO:  ' ||
                    ROUND(pp.cambio, 2)::varchar
                WHEN pp.codigo_pago = 'E' THEN
                    'CH  ' || LEFT(pp.verificacion, 8) || '/' || RIGHT(TRIM(pp.codigo_documento), 7) || '/' ||
                    LEFT(pp.codigo_documento, 6) || TRIM(ROUND(pp.monto_pago, 2)::varchar) || '  '
                WHEN pp.codigo_pago = 'Q' THEN
                    pp.tipo_pago || '   ' || TRIM(pp.codigo_documento) || '  '
                WHEN pp.codigo_pago = 'Y' THEN
                    pp.tipo_pago || '   ' || TRIM(pp.codigo_documento) || '   ' ||
                    TRIM(ROUND(pp.monto_pago, 2)::varchar) || '  '
                ELSE
                    pp.tipo_pago || '   ' || TRIM(ROUND(pp.monto_pago, 2)::varchar) || '  '
            END AS pago
        FROM puntos_venta.pagos pp
        WHERE pp.referencia = '2320097001'
        )
        SELECT
            string_agg(pago, ' ') AS v_pago,
            MAX(CASE WHEN codigo_pago = 'B' THEN pago END) AS v_pago_efectivo
        FROM pagos;
    */
    -- DEDUCIBLE VESTIMENTA
    SELECT SUM(dfc.total_precio) total
    INTO v_deducible_vestimenta
    FROM puntos_venta.facturas_detalle dfc
    WHERE (LEFT(dfc.item, 1) = '1' OR LEFT(dfc.item, 1) = '5')
      AND dfc.referencia = v_referencia;

    -- CIUDAD
    SELECT ib.ciudad
    INTO v_ciudad
    FROM control_inventarios.id_bodegas ib
    WHERE ib.bodega = LEFT(v_referencia, 3);

    -- TOTAL DESCUENTO
    SELECT SUM((fd.cantidad * fd.precio) - fd.total_precio) total_descuento
    INTO v_total_descuento
    FROM puntos_venta.facturas_detalle fd
    WHERE fd.referencia = v_referencia;

    -- NUMERO ARTICULOS
    SELECT SUM(fd.cantidad) numarticulos
    INTO v_numero_articulos
    FROM puntos_venta.facturas_detalle fd
    WHERE fd.referencia = v_referencia;


    RETURN QUERY
        SELECT fc.referencia,
               fc.fecha,
               fc.vendedor,
               fc.hora,
               fc.clave_acceso,
               fc.fecha_autorizacion,
               CONCAT(cli.apellidos, ' ', cli.nombres) AS nombre,
               cli.direccion,
               cli.cedula_ruc,
               fd.referencia,
               fd.item,
               fd.descripcion,
               i.unidad_medida,
               fd.cantidad,
               fd.precio,
               fd.descuento,
               (fd.cantidad * fd.precio)               AS total_precio,
               fc.monto_total - fc.iva                 AS subtotal,
               fc.iva,
               fc.monto_total,
               v_pago                                  AS pagos,
               v_deducible_vestimenta                  AS deducible_vestimenta,
               fc.factura                              AS factura,
               v_ciudad                                AS ciudad,
               v_total_descuento                       AS total_descuento,
               v_numero_articulos                      AS numero_articulos,
               CASE
                   WHEN COALESCE(fc.tipo_documento, '') = '' THEN 'FACTURA NO:'
                   ELSE 'N/CREDITO NO:' END            AS tipo_factura,
               fc.porcentaje_iva::integer || '%'       AS IvaVigente,
               CASE
                   WHEN fc.comentario ILIKE '%GANADOR BILLETE PASA%' THEN TRUE
                   ELSE FALSE END                      AS imprime_comentario,
               fc.comentario,
               fc.valor_descuento_adicional
        FROM puntos_venta.facturas_cabecera fc,
             puntos_venta.facturas_detalle fd,
             puntos_venta.clientes cli,
             control_inventarios.items i
        WHERE fc.referencia = v_referencia
          AND fc.referencia = fd.referencia
          AND cli.cedula_ruc = fc.cedula_ruc
          AND fd.item = i.item;

END
$function$
;

