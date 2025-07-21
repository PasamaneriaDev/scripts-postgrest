/*
 drop function trabajo_proceso.tarjetas_circulares(character varying);
 */

CREATE OR REPLACE FUNCTION trabajo_proceso.tarjetas_circulares(p_datajs character varying)
    RETURNS TABLE
            (
                codigo_orden_1           text,
                secuencia_codigo_barra_1 text,
                numero_rollo_1           text,
                item_1                   text,
                descripcion_1            text,
                maquina_1                text,
                codigo_orden_2           text,
                secuencia_codigo_barra_2 text,
                numero_rollo_2           text,
                item_2                   text,
                descripcion_2            text,
                maquina_2                text
            )
    LANGUAGE plpgsql
AS
$function$
DECLARE
    v_col integer = 2;
BEGIN

    RETURN QUERY
        WITH insertados AS
                 (
                     INSERT INTO trabajo_proceso.ordenes_rollos_detalle (codigo_orden, creacion_usuario)
                         SELECT codigo_orden, creacion_usuario
                         FROM JSON_TO_RECORDSET(p_datajs::json) a (codigo_orden text, nro_rollos integer, creacion_usuario text)
                                  JOIN LATERAL (SELECT
                                                FROM GENERATE_SERIES(1, a.nro_rollos) AS nro_rollo) AS gs ON TRUE
                         RETURNING codigo_orden, numero_rollo),
             numerados AS
                 (SELECT o.codigo_orden,
                         LPAD(o.secuencia_codigo_barra || i.numero_rollo, 12, '0') AS secuencia_codigo_barra,
                         i.numero_rollo,
                         o.item,
                         it.descripcion,
                         o.maquina,
                         ROW_NUMBER() OVER (ORDER BY o.codigo_orden)               AS rn
                  FROM trabajo_proceso.ordenes o
                           JOIN control_inventarios.items it ON o.item = it.item
                           JOIN insertados i ON o.codigo_orden = i.codigo_orden
                  ORDER BY o.codigo_orden, i.numero_rollo)
        SELECT MAX(CASE WHEN rn % 2 = 1 THEN codigo_orden END)           AS codigo_orden_1,
               MAX(CASE WHEN rn % 2 = 1 THEN secuencia_codigo_barra END) AS secuencia_codigo_barra_1,
               MAX(CASE WHEN rn % 2 = 1 THEN numero_rollo END)           AS numero_rollo_1,
               MAX(CASE WHEN rn % 2 = 1 THEN item END)                   AS item_1,
               MAX(CASE WHEN rn % 2 = 1 THEN descripcion END)            AS descripcion_1,
               MAX(CASE WHEN rn % 2 = 1 THEN maquina END)                AS maquina_1,
               MAX(CASE WHEN rn % 2 = 0 THEN codigo_orden END)           AS codigo_orden_2,
               MAX(CASE WHEN rn % 2 = 0 THEN secuencia_codigo_barra END) AS secuencia_codigo_barra_2,
               MAX(CASE WHEN rn % 2 = 0 THEN numero_rollo END)           AS numero_rollo_2,
               MAX(CASE WHEN rn % 2 = 0 THEN item END)                   AS item_2,
               MAX(CASE WHEN rn % 2 = 0 THEN descripcion END)            AS descripcion_2,
               MAX(CASE WHEN rn % 2 = 0 THEN maquina END)                AS maquina_2
        FROM numerados
        GROUP BY (rn + 1) / 2
        ORDER BY MIN(rn);

END;
$function$
;
