-- drop function trabajo_proceso.orden_rollo_consulta_paro_mant(date, date, varchar, varchar);

CREATE OR REPLACE FUNCTION trabajo_proceso.orden_rollo_consulta_paro_mant(p_fecha_inicial date, p_fecha_fin date,
                                                                          p_maquina varchar, p_tipo varchar)
    RETURNS TABLE
            (
                tipo                character varying,
                fecha_registro      date,
                operario            character varying,
                operario_nombre     character varying,
                codigo_orden        character varying,
                numero_rollo        character varying,
                maquina             character varying,
                fecha_inicio        timestamp WITHOUT TIME ZONE,
                fecha_fin           timestamp WITHOUT TIME ZONE,
                motivo              varchar,
                tiempo_transcurrido numeric
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    RETURN QUERY
        WITH data AS (SELECT ''::varchar   AS tipo,
                             rd.fecha_registro_produccion,
                             rd.operario_registro_produccion,
                             u.nombres     AS operario_nombre,
                             rd.codigo_orden,
                             rd.numero_rollo,
                             o.maquina,
                             NULL::date    AS fecha_inicio,
                             NULL::date    AS fecha_fin,
                             NULL::varchar AS motivo,
                             NULL          AS tiempo_transcurrido -- en Horas
                      FROM trabajo_proceso.ordenes_rollos_detalle rd
                               JOIN trabajo_proceso.ordenes o ON o.codigo_orden = rd.codigo_orden
                               JOIN sistema.usuarios u ON rd.operario_registro_produccion = u.codigo
                      WHERE rd.fecha_registro_produccion::date >= p_fecha_inicial
                        AND rd.fecha_registro_produccion::date <= p_fecha_fin
                        AND (o.maquina = p_maquina OR p_maquina = '')
                        AND rd.fecha_registro_produccion IS NOT NULL
                      UNION ALL
                      SELECT pr.tipo,
                             pr.fecha_inicio,
                             rd.operario_registro_produccion,
                             u.nombres                                                           AS operario_nombre,
                             rd.codigo_orden,
                             rd.numero_rollo,
                             o.maquina,
                             pr.fecha_inicio,
                             pr.fecha_fin,
                             pr.motivo,
                             ROUND((EXTRACT(EPOCH FROM (pr.fecha_fin - pr.fecha_inicio)) / 3600)::numeric, 2) AS tiempo_transcurrido -- en Horas
                      FROM trabajo_proceso.ordenes_rollos_detalle rd
                               JOIN trabajo_proceso.ordenes o ON o.codigo_orden = rd.codigo_orden
                               JOIN sistema.usuarios u ON rd.operario_registro_produccion = u.codigo
                               JOIN trabajo_proceso.ordenes_rollos_paros_mantenimiento pr
                                    ON rd.codigo_orden = pr.codigo_orden AND rd.numero_rollo = pr.numero_rollo
                      WHERE pr.fecha_inicio::date >= p_fecha_inicial
                        AND pr.fecha_inicio::date <= p_fecha_fin
                        AND (pr.maquina = p_maquina OR p_maquina = '')
                      UNION ALL
                      SELECT rd.tipo,
                             rd.fecha_inicio,
                             rd.creacion_usuario,
                             u.nombres                                                           AS operario_nombre,
                             '',
                             '',
                             rd.maquina,
                             rd.fecha_inicio,
                             rd.fecha_fin,
                             rd.motivo,
                             ROUND((EXTRACT(EPOCH FROM (rd.fecha_fin - rd.fecha_inicio)) / 3600)::numeric, 2) AS tiempo_transcurrido
                      FROM trabajo_proceso.ordenes_rollos_paros_mantenimiento rd
                               JOIN sistema.usuarios u ON rd.creacion_usuario = u.codigo
                      WHERE rd.tipo = 'M'
                        AND rd.fecha_inicio::date >= p_fecha_inicial
                        AND rd.fecha_inicio::date <= p_fecha_fin
                        AND (rd.maquina = p_maquina OR p_maquina = ''))
        SELECT d.tipo,
               d.fecha_registro_produccion::date,
               d.operario_registro_produccion,
               d.operario_nombre,
               d.codigo_orden,
               d.numero_rollo,
               d.maquina,
               d.fecha_inicio,
               d.fecha_fin,
               d.motivo,
               d.tiempo_transcurrido
        FROM data d
        WHERE (d.tipo = p_tipo OR p_tipo = '')
        ORDER BY d.fecha_registro_produccion ASC, d.fecha_inicio ASC, codigo_orden;
END
$function$
;
