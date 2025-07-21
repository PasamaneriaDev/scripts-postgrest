-- drop function auditoria.item_costo_standard_total(p_item varchar);

CREATE OR REPLACE FUNCTION auditoria.item_costo_standard_total(p_item varchar)
    RETURNS TABLE
            (
                item             VARCHAR,
                unidad_medida    VARCHAR,
                numero_decimales numeric,
                descripcion      VARCHAR,
                total_costo      NUMERIC
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    RETURN QUERY
        SELECT i.item,
               i.unidad_medida,
               i.numero_decimales,
               i.descripcion,
               COALESCE((cc.mantenimiento_materia_prima + cc.mantenimiento_mano_obra +
                         cc.mantenimiento_gastos_fabricacion +
                         cc.nivel_materia_prima + cc.nivel_mano_obra + cc.nivel_gastos_fabricacion +
                         cc.acumulacion_materia_prima + cc.acumulacion_mano_obra + cc.acumulacion_gastos_fabricacion),
                        0) AS total_costo
        FROM control_inventarios.items i
                 LEFT JOIN costos.costos cc
                           ON i.item = cc.item
                               AND cc.tipo_costo = 'Standard'
        WHERE i.item = p_item;
END;
$function$;