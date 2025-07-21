
CREATE OR REPLACE FUNCTION trabajo_proceso.tintoreria_peso_balanza_margen_tolerancia(p_codigo_orden varchar,
                                                                                     p_peso_rollo_agrega numeric,
                                                                                     o_es_valido OUT text)
    RETURNS text
    LANGUAGE plpgsql
AS
$function$
DECLARE
    v_item_malla_cruda       varchar;
    v_malla_cruda_entregada  numeric;
    v_malla_tinturada_pesada numeric;
    v_margen_tolerancia      numeric;
BEGIN

    -- Mallas Reprocesadas no deben ser validadas
    IF left(p_codigo_orden, 4) = 'T7-R' THEN
        RETURN;
    END IF;

    -- Buscar el item de la malla cruda
    SELECT e.componente
    INTO v_item_malla_cruda
    FROM trabajo_proceso.ordenes o
             JOIN lista_materiales.estructuras e ON e.item = o.item
        AND e.componente LIKE LEFT(o.item, 6) || '%'
    WHERE o.codigo_orden = p_codigo_orden;

    IF NOT found THEN
        RAISE EXCEPTION 'No se encontró el item de la malla cruda para la orden %', p_codigo_orden;
    END IF;

    -- Buscar egreso de Crudo a la orden
    SELECT SUM(t.cantidad) AS cantidad
    INTO v_malla_cruda_entregada
    FROM control_inventarios.transacciones t
    WHERE t.tipo_movimiento = 'EGRE ORDE'
      AND t.item = v_item_malla_cruda
      AND t.referencia = p_codigo_orden;

    IF NOT found THEN
        RAISE EXCEPTION 'No se encontró la cantidad de malla cruda entregada para la orden: %', p_codigo_orden;
    END IF;

    v_malla_cruda_entregada := COALESCE(ABS(v_malla_cruda_entregada), 0);

    IF v_malla_cruda_entregada = 0 THEN
        RAISE EXCEPTION 'No se ha entregado malla cruda a la orden: % ', p_codigo_orden;
    END IF;

    -- Busca la malla ya tinturada y pesada
    SELECT SUM(tpb.peso_neto)
    INTO v_malla_tinturada_pesada
    FROM trabajo_proceso.tintoreria_pesos_balanza tpb
    WHERE tpb.bodega <> ''
      AND tpb.codigo_orden = p_codigo_orden;

    v_malla_tinturada_pesada = COALESCE(v_malla_tinturada_pesada, 0) + p_peso_rollo_agrega;

    -- Formula el margen de tolerancia
    v_margen_tolerancia = ((v_malla_cruda_entregada - v_malla_tinturada_pesada) / v_malla_cruda_entregada) * 100;

    IF v_margen_tolerancia < -15 THEN
        o_es_valido :=
                'Ha superado el margen de tolerancia del 15% (Actual: ' || ROUND(ABS(v_margen_tolerancia), 2) || '%)';
    END IF;
END ;
$function$
;