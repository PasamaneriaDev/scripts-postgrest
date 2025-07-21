-- DROP FUNCTION control_inventarios.item_consulta_kardex(varchar, date, date, _varchar);

CREATE OR REPLACE FUNCTION control_inventarios.item_consulta_kardex(p_item character varying, p_fecha_inicial date,
                                                                    p_fecha_final date, p_bodegas character varying[])
    RETURNS TABLE
            (
                transaccion       character varying,
                cantidad          numeric,
                bodega            character varying,
                ubicacion         character varying,
                cnt               integer,
                bodega_final      character varying,
                ubicacion_final   character varying,
                tipo_movimiento   character varying,
                fecha             date,
                cantidad_recibida numeric,
                fecha_recepcion   date,
                creacion_usuario  character varying,
                creacion_hora     character varying,
                referencia        character varying,
                documento         character varying,
                costo             numeric,
                cliente           character varying,
                periodo           character varying,
                nombre_cliente    character varying,
                nombre            text
            )
    LANGUAGE plpgsql
AS
$function$

DECLARE

BEGIN
    DROP TABLE IF EXISTS AuxUnicos;
    RETURN QUERY WITH r AS
                          (WITH t AS
                                    (SELECT p.transaccion,
                                            p.cantidad,
                                            p.bodega,
                                            p.ubicacion,
                                            COUNT(*) OVER (PARTITION BY p.transaccion)::integer                    AS cnt,
                                            LEAD(p.bodega, 1)
                                            OVER (PARTITION BY p.transaccion, ABS(p.cantidad) ORDER BY p.cantidad) AS bodega_final,
                                            LEAD(p.ubicacion, 1)
                                            OVER (PARTITION BY p.transaccion, ABS(p.cantidad) ORDER BY p.cantidad) AS ubicacion_final,
                                            p.tipo_movimiento,
                                            p.fecha,
                                            --p.cantidad_recibida,

                                            LEAD(p.cantidad_recibida, 1)
                                            OVER (PARTITION BY p.transaccion, ABS(p.cantidad) ORDER BY p.cantidad) AS cantidad_recibida,
                                            LEAD(p.fecha_recepcion, 1)
                                            OVER (PARTITION BY p.transaccion, ABS(p.cantidad) ORDER BY p.cantidad) AS fecha_recepcion,

                                            p.creacion_usuario,
                                            p.creacion_hora,
                                            p.referencia,
                                            p.documento,
                                            ROUND((-p.cantidad * p.costo), 2)                                      AS costo,
                                            CASE
                                                WHEN p.tipo_movimiento = 'VTAS MAY' THEN
                                                    (SELECT c.cliente
                                                     FROM cuentas_cobrar.facturas_cabecera c
                                                     WHERE c.referencia = p.documento)
                                                ELSE
                                                    ''
                                                END                                                                AS cliente,
                                            p.periodo
                                     FROM control_inventarios.transacciones p
                                     WHERE p.item = p_item
                                       AND p.fecha BETWEEN p_fecha_inicial AND p_fecha_final
                                       AND p.tipo_movimiento <> 'CERR ORDE'
                                     GROUP BY p.transaccion, p.cantidad, p.bodega, p.ubicacion, p.tipo_movimiento,
                                              p.fecha, p.cantidad_recibida, p.fecha_recepcion, p.creacion_usuario,
                                              p.creacion_hora, p.referencia, p.documento, p.costo, p.periodo
                                     ORDER BY p.transaccion)
                           SELECT t.*
                           FROM t
                           WHERE (MOD(t.cnt, 2) = 0 AND t.bodega_final IS NOT NULL)
                              OR (MOD(t.cnt, 2) <> 0 AND t.bodega_final IS NULL))
                 SELECT r.*,
                        CASE
                            WHEN r.cliente <> '' THEN
                                (SELECT n.nombre FROM cuentas_cobrar.clientes n WHERE n.codigo = r.cliente)
                            ELSE
                                ''
                            END                                                                             AS Nombre_cliente,
                        CONCAT(p.apellido_paterno, ' ', p.apellido_materno, ' ', p.nombre1, ' ', p.nombre2) AS nombre
                 FROM r
                          LEFT JOIN roles.personal p ON RIGHT(p.codigo, 4) = r.creacion_usuario
                 WHERE (ARRAY_LENGTH(p_bodegas, 1) IS NULL OR (r.bodega = ANY (p_bodegas) OR
                                                               r.bodega_final = ANY (p_bodegas)))
                 ORDER BY fecha ASC, tipo_movimiento DESC;
END;
$function$
;
