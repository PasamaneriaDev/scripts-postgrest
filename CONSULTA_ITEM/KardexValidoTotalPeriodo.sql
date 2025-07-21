-- DROP FUNCTION control_inventarios.items_kardex_valido_total_periodo(varchar, date, date, _varchar, varchar);

CREATE OR REPLACE FUNCTION control_inventarios.items_kardex_valido_total_periodo(p_item character varying, p_fecha_inicial date, p_fecha_final date, p_bodega character varying[], p_ubicacion character varying)
 RETURNS TABLE(tipo_registro character varying, periodo character varying, fecha date, documento character varying, movimiento character varying, referencia character varying, cantidad numeric, transito numeric, costo numeric, costo_total numeric, bodega character varying, ubicacion character varying, bodega_destino character varying, ubicacion_destino character varying, cantidad_recibida numeric, fecha_recepcion date, creacion_usuario character varying, usuario_nombre character varying, creacion_hora character varying, cliente character varying, nombre_cliente character varying, orden numeric)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
        WITH kardex AS (SELECT 'K'::varchar                             AS tipo_registro,
                               ik.periodo,
                               ik.fecha::date                           AS fecha,
                               ik.documento,
                               CASE
                                   WHEN LEFT(ik.movimiento, 8) = 'TRANSFER' THEN
                                       'TRANSFE'
                                   WHEN LEFT(ik.movimiento, 9) = 'REUB CANT' THEN
                                       'REUBICA'
                                   ELSE
                                       ik.movimiento
                                   END::varchar                         AS movimiento,
                               ik.referencia,
                               ik.cantidad,
                               0                                        AS transito,
                               ik.costo                                 AS costo,
                               (ik.cantidad * ik.costo)::numeric(12, 2) AS costo_total,
                               ik.bodini                                AS bodega,
                               ik.ubicini                               AS ubicacion,
                               ik.bodfin                                AS bodega_destino,
                               ik.ubicfin                               AS ubicacion_destino,
                               ik.cantidad_recibida,
                               ik.fecha_recepcion,
                               ik.creacion_usuario,
                               ik.usuario_nombre,
                               ik.creacion_hora,
                               ik.codigo_proveedor                      AS cliente,
                               ik.nombre_proveedor                      AS nombre_cliente,
                               ik.secuencia1                            AS orden
                        FROM control_inventarios.items_kardex_valido(p_item, p_fecha_inicial, p_fecha_final,
                                                                     p_bodega) ik
                        WHERE (p_ubicacion = '' OR (ik.ubicini = p_ubicacion OR ik.ubicfin = p_ubicacion))),
             historico AS (SELECT 'T'::varchar                                        AS tipo_registro,
                                  ih.periodo,
                                  (DATE_TRUNC('month', TO_DATE(ih.periodo, 'YYYYMM') + INTERVAL '1 month') -
                                   INTERVAL '1 day')::date                            AS fecha,
                                  ''::varchar                                         AS documento,
                                  ''::varchar                                         AS movimiento,
                                  ''::varchar                                         AS referencia,
                                  ih.existencia                                       AS cantidad,
                                  ih.transito,
                                  ih.costo_promedio                                   AS costo,
                                  (ih.costo_promedio * ih.existencia)::numeric(12, 2) AS costo_total,
                                  ih.bodega,
                                  ih.ubicacion,
                                  ''::varchar                                         AS bodega_destino,
                                  ''::varchar                                         AS ubicacion_destino,
                                  NULL::numeric                                       AS cantidad_recibida,
                                  NULL::date                                          AS fecha_recepcion,
                                  ''::varchar                                         AS creacion_usuario,
                                  ''::varchar                                         AS usuario_nombre,
                                  ''::varchar                                         AS creacion_hora,
                                  ''::varchar                                         AS cliente,
                                  ''::varchar                                         AS nombre_cliente,
                                  999999                                              AS orden -- Para que los totales aparezcan al final del período
                           FROM control_inventarios.items_historico ih
                           WHERE ih.item = p_item
                             AND ih.nivel = 'IQTY'
                             AND ih.periodo >= TO_CHAR(p_fecha_inicial, 'YYYYMM')
                             AND ih.periodo <= TO_CHAR(p_fecha_final, 'YYYYMM')
                             AND (ARRAY_LENGTH(p_bodega, 1) IS NULL OR (ih.bodega = ANY (p_bodega)))
                             AND (p_ubicacion = '' OR ih.ubicacion = p_ubicacion))
        SELECT cmb.tipo_registro,
               cmb.periodo,
               cmb.fecha,
               cmb.documento,
               cmb.movimiento,
               cmb.referencia,
               cmb.cantidad,
               cmb.transito,
               cmb.costo,
               cmb.costo_total,
               cmb.bodega,
               cmb.ubicacion,
               cmb.bodega_destino,
               cmb.ubicacion_destino,
               cmb.cantidad_recibida,
               cmb.fecha_recepcion,
               cmb.creacion_usuario,
               cmb.usuario_nombre,
               cmb.creacion_hora,
               cmb.cliente,
               cmb.nombre_cliente,
               cmb.orden
        FROM (SELECT *
              FROM kardex
              UNION ALL
              SELECT *
              FROM historico) cmb
        ORDER BY periodo, fecha, /*tipo_registro DESC,*/ orden;
END;
$function$
;
