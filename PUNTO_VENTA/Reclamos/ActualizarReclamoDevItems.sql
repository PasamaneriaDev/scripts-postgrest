-- cheques.inserta_banco
-- DROP FUNCTION puntos_venta.grabar_reclamo(p_cabecera jsonb, OUT respuesta text);
CREATE OR REPLACE FUNCTION puntos_venta.actualizar_reclamo(p_data jsonb, OUT respuesta text) -- *
    RETURNS text
    LANGUAGE plpgsql
AS
$function$
DECLARE
    _r               record;
    _d               record;
    p_numero_reclamo numeric;
    p_correos        VARCHAR;
    p_numero_email   numeric;
    p_centro_costo   VARCHAR;
BEGIN
    /********************************************************************************************************/
    -- JSON
    --     {
    --         "centro_costo": "",
    --         "nombre_cliente": "",
    --         "fecha_reclamo": "",
    --         "fecha_compra": "",
    --         "problema_solucionado": "",
    --         "solucion": ""
    --         "productos_lavado": "",
    --         "metodo_lavado": "",
    --         "metodo_secado": "",
    --         "observaciones": "",
    --         "numero_transferencia": "",
    --         "creacion_usuario": ""
    --         "detalles": [
    --             {
    --                 "item": "",
    --                 "cantidad": "",
    --                 "periodo": "",
    --                 "observacion_item": "",
    --                 "codigo_defecto": ""
    --             },
    --             {...}
    --         ]
    --     }
    /********************************************************************************************************/

    SELECT COALESCE(UPPER(t.centro_costo), '')         AS centro_costo,
           COALESCE(UPPER(t.nombre_cliente), '')       AS nombre_cliente,
           COALESCE(t.fecha_reclamo, CURRENT_DATE)     AS fecha_reclamo,
           COALESCE(t.fecha_compra, CURRENT_DATE)      AS fecha_compra,
           COALESCE(t.problema_solucionado, FALSE)     AS problema_solucionado,
           COALESCE(UPPER(t.solucion), '')             AS solucion,
           COALESCE(UPPER(t.productos_lavado), '')     AS productos_lavado,
           COALESCE(UPPER(t.metodo_lavado), '')        AS metodo_lavado,
           COALESCE(UPPER(t.metodo_secado), '')        AS metodo_secado,
           COALESCE(UPPER(t.observaciones), '')        AS observaciones,
           COALESCE(UPPER(t.numero_transferencia), '') AS numero_transferencia,
           COALESCE(UPPER(t.creacion_usuario), '')     AS creacion_usuario,
           (p_data ->> 'detalles')::jsonb              AS detalles
    INTO _r
    FROM JSONB_TO_RECORD(p_data) AS t (centro_costo VARCHAR(3),
                                       nombre_cliente VARCHAR(70),
                                       fecha_reclamo DATE,
                                       fecha_compra DATE,
                                       problema_solucionado BOOLEAN,
                                       solucion VARCHAR(100),
                                       productos_lavado VARCHAR(30),
                                       metodo_lavado VARCHAR(30),
                                       metodo_secado VARCHAR(30),
                                       observaciones VARCHAR(300),
                                       numero_transferencia VARCHAR(10),
                                       creacion_usuario VARCHAR(4));

    /********************************************************************************************************/
    -- Inserta en la tabla cabecera_reclamo
    INSERT INTO puntos_venta.reclamos_cabecera (centro_costo,
                                                nombre_cliente,
                                                fecha_reclamo,
                                                fecha_compra,
                                                problema_solucionado,
                                                solucion,
                                                productos_lavado,
                                                metodo_lavado,
                                                metodo_secado,
                                                observaciones,
                                                numero_transferencia,
                                                creacion_usuario,
                                                creacion_fecha)
    VALUES (_r.centro_costo,
            _r.nombre_cliente,
            _r.fecha_reclamo,
            _r.fecha_compra,
            _r.problema_solucionado,
            _r.solucion,
            _r.productos_lavado,
            _r.metodo_lavado,
            _r.metodo_secado,
            _r.observaciones,
            _r.numero_transferencia,
            _r.creacion_usuario,
            CURRENT_TIMESTAMP)
    RETURNING numero_reclamo INTO p_numero_reclamo;

    /********************************************************************************************************/
    -- Inserta en el detalle del reclamo
    FOR _d IN SELECT j.item,
                     j.cantidad,
                     COALESCE(j.periodo, 0)           AS periodo,
                     COALESCE(j.observacion_item, '') AS observacion_item,
                     j.codigo_defecto
              FROM JSON_TO_RECORDSET(_r.detalles::json) AS j(item VARCHAR(15), cantidad numeric, periodo numeric,
                                                             observacion_item VARCHAR, codigo_defecto numeric)
        LOOP

            INSERT INTO puntos_venta.reclamos_detalle (numero_reclamo, item, cantidad, anio_trimestre,
                                                       codigo_defecto, observaciones)
            VALUES (p_numero_reclamo, _d.item, _d.cantidad, _d.periodo, _d.codigo_defecto, _d.observacion_item);
        END LOOP;
    -- Respuesta
    respuesta = p_numero_reclamo::text;

END;
$function$;
