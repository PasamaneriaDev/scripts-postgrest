DO $$
DECLARE
    p_datajs json;
    bodega_value text;
BEGIN
    -- Crear un JSON de prueba
    p_datajs := '{"bodega": "B001", "cliente": "C123", "factura": "F456"}';

    -- Extraer el valor de 'bodega' del JSON
    bodega_value := p_datajs ->> 'bodega';

    -- Mostrar el valor extraído
    RAISE NOTICE 'El valor de bodega es: %', bodega_value;
END;
$$;



select *
from cuentas_cobrar.facturas_cabecera -- 0090000086
where fecha > '2025-01-01';

SELECT *
FROM cuentas_pagar.proveedores
WHERE es_transportista = True;

select *
from control_inventarios.transacciones -- 2201463217
where fecha > '2025-01-01';


begin;
select *
from cuentas_cobrar.guias_remision_transferencia('{"tipo_documento":"D","referencia":"0088326832","cliente":"007303","bodega":"001","codigo_transportista":"010151","fecha_inicio":"2025-07-18","fecha_fin":"2025-07-18","direccion_destino":"TOMAS EDISON 223 Y AV.DEL CHOFER"}', '3191')

rollback;



select *
from cuentas_cobrar.guias_remision;


select *
from sistema.interface
where modulo = 'DESPACHOS'
and fecha = current_date::varchar