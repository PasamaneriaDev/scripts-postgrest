-- drop FUNCTION auditoria.reporte_grabados_valorados(p_bodega varchar, p_periodo varchar);

CREATE OR REPLACE FUNCTION auditoria.reporte_grabados_valorados(p_bodega varchar, p_periodo varchar)
    RETURNS TABLE
            (
                documento                CHARACTER VARYING,
                item                     CHARACTER VARYING,
                descripcion              CHARACTER VARYING,
                unidad_medida            CHARACTER VARYING,
                fecha                    date,
                costo                    NUMERIC,
                cantidad                 NUMERIC,
                conos                    numeric,
                tara                     NUMERIC,
                cajon                    NUMERIC,
                constante                NUMERIC,
                cantidad_ajuste          NUMERIC,
                bodega                   CHARACTER VARYING,
                ubicacion                CHARACTER VARYING,
                numero_muestras          integer,
                valor_materia_prima      numeric,
                valor_mano_obra          numeric,
                valor_gastos_fabricacion numeric,
                orden                    CHARACTER VARYING
            )
    LANGUAGE plpgsql
AS
$function$
DECLARE
    v_anio numeric;
    v_mes  numeric;
BEGIN
    IF p_periodo <> '' THEN
        v_anio := SUBSTRING(p_periodo FROM 1 FOR 4)::numeric;
        v_mes := SUBSTRING(p_periodo FROM 5 FOR 2)::numeric;
    END IF;

    RETURN QUERY
        SELECT a.documento,
               a.item,
               i.descripcion,
               i.unidad_medida,
               a.creacion_fecha,
               a.costo,
               a.cantidad,
               a.conos,
               a.tara,
               a.cajon,
               a.constante,
               a.cantidad_ajuste,
               a.bodega,
               a.ubicacion,
               CARDINALITY(
                       ARRAY(
                               SELECT line
                               FROM UNNEST(STRING_TO_ARRAY(a.muestra, CHR(10))) AS line
                               WHERE (STRING_TO_ARRAY(line, CHR(9)))[1]::numeric IS NOT NULL
                       )
               )                             AS numero_muestras,
               CASE
                   WHEN LEFT(a.item, 1) <> 'M' THEN cl.valor_materia_prima
                   ELSE i.costo_promedio END AS valor_materia_prima,
               CASE
                   WHEN LEFT(a.item, 1) <> 'M' THEN cl.valor_mano_obra
                   ELSE 0 END                AS valor_mano_obra,
               CASE
                   WHEN LEFT(a.item, 1) <> 'M' THEN cl.valor_gastos_fabricacion
                   ELSE 0 END                AS valor_gastos_fabricacion,
               a.orden
        FROM inventario_proceso.ajustes a
                 JOIN inventario_proceso.items i ON i.item = a.item
                 LEFT JOIN LATERAL (SELECT (c.mantenimiento_materia_prima + c.nivel_materia_prima +
                                            c.acumulacion_materia_prima)      AS valor_materia_prima,
                                           (c.mantenimiento_mano_obra + c.nivel_mano_obra +
                                            c.acumulacion_mano_obra)          AS valor_mano_obra,
                                           (c.mantenimiento_gastos_fabricacion + c.nivel_gastos_fabricacion +
                                            c.acumulacion_gastos_fabricacion) AS valor_gastos_fabricacion
                                    FROM inventario_proceso.costos c
                                    WHERE c.item = a.item
                                      AND c.tipo_costo = 'Standard') AS cl ON TRUE
        WHERE (p_bodega = '' OR a.bodega = p_bodega)
          AND a.status <> 'V'
          AND (p_periodo = '' OR
               (EXTRACT('year' FROM a.creacion_fecha) = v_anio AND EXTRACT('month' FROM a.creacion_fecha) = v_mes))
        ORDER BY a.bodega, a.documento;
END
$function$;


