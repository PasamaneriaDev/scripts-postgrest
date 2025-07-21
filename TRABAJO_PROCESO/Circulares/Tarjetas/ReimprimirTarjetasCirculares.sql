CREATE OR REPLACE FUNCTION trabajo_proceso.tarjetas_circulares_reimprimir(p_codigo_orden varchar,
                                                                          p_rollo_inicial varchar,
                                                                          p_rollo_final varchar)
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
BEGIN

    RETURN QUERY
        WITH numerados AS
                 (SELECT o.codigo_orden,
                         LPAD(o.secuencia_codigo_barra || od.numero_rollo, 12, '0') AS secuencia_codigo_barra,
                         od.numero_rollo,
                         o.item,
                         it.descripcion,
                         o.maquina,
                         ROW_NUMBER() OVER (ORDER BY o.codigo_orden)                AS rn
                  FROM trabajo_proceso.ordenes_rollos_detalle od
                           JOIN trabajo_proceso.ordenes o ON od.codigo_orden = o.codigo_orden
                           JOIN control_inventarios.items it ON o.item = it.item
                  WHERE o.codigo_orden = p_codigo_orden
                    AND od.numero_rollo BETWEEN p_rollo_inicial AND p_rollo_final
                  ORDER BY o.codigo_orden, od.numero_rollo)
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