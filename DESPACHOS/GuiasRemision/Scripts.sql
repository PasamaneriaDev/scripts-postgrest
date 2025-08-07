DO
$$
    DECLARE
        p_datajs     json;
        bodega_value text;
    BEGIN
        -- Crear un JSON de prueba
        p_datajs := '{
          "bodega": "B001",
          "cliente": "C123",
          "factura": "F456"
        }';

        -- Extraer el valor de 'bodega' del JSON
        bodega_value := p_datajs ->> 'bodega';

        -- Mostrar el valor extraído
        RAISE NOTICE 'El valor de bodega es: %', bodega_value;
    END;
$$;

DO
$$
    DECLARE
        json_text    text := '{"bodega": "B001", "cliente": "C123"}';
        json_data    jsonb;
        updated_json jsonb;
    BEGIN
        -- Convertir el texto a JSONB
        json_data := json_text::jsonb;

        -- Agregar o modificar un campo
        updated_json := json_data || '{
          "factura": "F456",
          "cliente": "C789"
        }'::jsonb;

        -- Mostrar el JSON actualizado
        RAISE NOTICE 'JSON actualizado: %', updated_json;

        -- Eliminar un campo (opcional)
        updated_json := updated_json - 'factura';

        -- Mostrar el JSON final
        RAISE NOTICE 'JSON final: %', updated_json;
    END;
$$;


SELECT *
FROM cuentas_cobrar.facturas_cabecera -- 0090000086
WHERE fecha > '2025-01-01';

SELECT *
FROM cuentas_pagar.proveedores
WHERE es_transportista = TRUE;

SELECT *
FROM control_inventarios.transacciones -- 1011590163
WHERE fecha > '2025-01-01';


SELECT *
FROM cuentas_pagar.proveedores
WHERE es_transportista = TRUE
  AND codigo = '003364';


SELECT codigo, cedula_ruc, nombre, direccion, telefono1, email
FROM cuentas_pagar.proveedores
WHERE cedula_ruc = '003364'


SELECT codigo, cedula_ruc, nombre, direccion, telefono1, dias_entrega, codigo_transportista
FROM cuentas_cobrar.clientes
WHERE codigo = '111528'


BEGIN;
SELECT *
FROM cuentas_cobrar.guias_remision_nueva(
             '{"tipo_documento":"D","referencia":"0088326832","cliente":"007303","bodega":"001","codigo_transportista":"010151","fecha_inicio":"2025-07-18","fecha_fin":"2025-07-18","direccion_destino":"TOMAS EDISON 223 Y AV.DEL CHOFER"}',
             '3191') rollback;



SELECT *
FROM cuentas_cobrar.guias_remision;

SELECT *
FROM cuentas_cobrar.detalle_guia_manual;

SELECT *
FROM sistema.interface
WHERE modulo = 'DESPACHOS'
  AND fecha = CURRENT_DATE::varchar

BEGIN;
SELECT cuentas_cobrar.guias_remision_transferencia(
               '{"tipo_documento":"T","referencia":"2201463217","cliente":"999220","bodega":"001","codigo_transportista":"003364","fecha_inicio":"2025-07-22","fecha_fin":"2025-07-22","direccion_destino":"GUAYAQUIL, LUQUE 2-21 ENTRE PEDRO CARBO Y CHILE                                 "}',
               '3191');

ROLLBACK;

SELECT codigo_transportista, *
FROM cuentas_cobrar.clientes
WHERE cedula_ruc = '0501463426001';

SELECT nombre, *
FROM cuentas_pagar.proveedores
WHERE codigo = '005067';


SELECT *
FROM control_inventarios.items;



UPDATE cuentas_cobrar.facturas_cabecera c
SET ambiente_sri        = 'PRODUCCION',
    numero_autorizacion = e.numero_autorizacion,
    fecha_autorizacion  = e.fecha_autorizacion::DATE,
    hora_autorizacion   = TO_CHAR(e.fecha_autorizacion::TIMESTAMP, 'HH24:MI:SS')
FROM (SELECT CONCAT(establecimiento, puntoemision, secuencial) AS factura,
             numero_autorizacion,
             fecha_autorizacion
      FROM public.cc_elec_cabecera
      WHERE enviado_sri = 'AUTORIZADO'
        AND documento = '01') e
WHERE c.factura = e.factura
  AND c.numero_autorizacion = '';


SELECT CONCAT(establecimiento, puntoemision, secuencial) AS factura,
       numero_autorizacion,
       fecha_autorizacion
FROM public.cc_elec_cabecera
WHERE enviado_sri = 'AUTORIZADO'
  AND documento = '01';

SELECT *
FROM cuentas_cobrar.facturas_cabecera c
         JOIN public.cc_elec_cabecera e ON c.factura = CONCAT(e.establecimiento, e.puntoemision, e.secuencial)
WHERE c.numero_autorizacion = ''



SELECT *
FROM (SELECT fd.item,
             fd.descripcion,
             fd.cantidad
      FROM cuentas_cobrar.facturas_detalle fd
      WHERE fd.referencia = '0088326832'
      UNION ALL
      SELECT 'GANCHOS',
             'GANCHOS',
             0
      WHERE 1 > 0) AS r1;

select *
    from cuentas_cobrar.guias_remision_cargar_pendientes(
             '001',
             'M')
/*------------------------------------------------------------------------------*/

BEGIN;
SELECT *
FROM cuentas_cobrar.guia_remision_procesar(
             '{"bodega_entorno":"001","codigo_transportista":"006404","fecha_inicio":"2025-07-22","fecha_fin":"2025-07-22","direccion_destino":"BELISARIO QUEVEDO 825 Y JUAN ABEL ECHEVERIA ","numero_guia":"001001000282508"}',
             '3191') rollback;

rollback;

SELECT *
FROM sistema.interface
WHERE fecha = CURRENT_DATE::varchar
  AND usuarios = '3191'
ORDER BY secuencia;

SELECT *
FROM cuentas_cobrar.guias_remision
WHERE numero_guia = '001001000282508';

select fd.*
from cuentas_cobrar.guias_remision gr
join cuentas_cobrar.facturas_detalle fd on gr.referencia = fd.referencia
where gr.numero_guia = '001001000282508';

SELECT cc.*
FROM cuentas_cobrar.guias_remision me
         LEFT JOIN public.cc_elec_cabecera_guia cc ON me.numero_guia = cc.establecimiento || cc.puntoemision || cc.secuencial
WHERE me.numero_guia = '001001000282508';

SELECT cc.*
FROM cuentas_cobrar.guias_remision me
         LEFT JOIN public.cc_elec_detalle_guia cc ON me.numero_guia = cc.establecimiento || cc.puntoemision || cc.secuencial
WHERE me.numero_guia = '001001000282508';

-- ACTUALIZA CLIENTE VARIOS con los datos enviados
-- Validar Fechas

SELECT *
FROM cuentas_cobrar.clientes
where codigo = 'VARIOS'

/* -------------------------------------------------------------------------- */
SELECT *
FROM cuentas_cobrar.clientes
where codigo = 'VARIOS'


SELECT codigo_transportista, * -- 005067  ** 003029
FROM cuentas_cobrar.guias_remision
where numero_guia = '001001000282512';