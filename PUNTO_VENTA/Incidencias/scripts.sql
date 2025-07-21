SELECT *
FROM sistema.usuarios_activos
WHERE computador = 'ANALISTA3'

SELECT *
FROM trabajo_proceso.requerimiento_guia

SELECT codigo, subcentro, codigo_responsable1, codigo
FROM activos_fijos.centros_costos
WHERE activos_fijos.centros_costos.no_combo_requerimientos = 'f'
  AND subcentro LIKE '%PRIMA%'
  AND codigo_responsable1 LIKE '%1656%'



SELECT item, descripcion, existencia
FROM control_inventarios.items
WHERE existencia > 0



SELECT item, descripcion, existencia, unidad_medida
FROM puntos_venta.reclamos_cabecera



SELECT respuesta
FROM puntos_venta.incidencias_grabar('{
  "centro_costo": "V74",
  "grupo": "V74",
  "observacion": "V74",
  "creacion_usuario": "CAJA"
}');


SELECT *
FROM puntos_venta.incidencias



SELECT *
FROM control_inventarios.items



SELECT *
FROM sistema.usuarios_activos ua
WHERE computador = 'ANALISTA5'



SELECT *
FROM trabajo_proceso.requerimiento_guia
ORDER BY nro_requerimiento DESC

SELECT 450.3400::int::varchar


SELECT *
FROM sistema.interface
ORDER BY secuencia DESC



SELECT *
FROM activos_fijos.centros_costos
WHERE subcentro LIKE '%MATERI%'


SELECT *
FROM trabajo_proceso.requerimiento_guia
WHERE centro_costo_destino = 'S15'
  AND LEFT(centro_costo_origen, 1) = 'V'
  AND fecha_requerimiento <> fecha_solicitud
ORDER BY fecha_requerimiento DESC



SELECT *
FROM sistema.email_masivo_cabecera emc
         JOIN sistema.email_masivo_detalle emd ON emc.numero_email = emd.numero_email
ORDER BY emc.numero_email DESC



SELECT numero_incidencia,
       centro_costo,
       grupo,
       observacion,
       creacion_usuario,
       creacion_fecha,
       recepcion_usuario,
       recepcion_fecha,
       finalizacion_usuario,
       finalizacion_fecha,
       noautorizado_usuario,
       noautorizado_fecha,
       observacion_noautorizado
FROM puntos_venta.incidencias



SELECT MIN(creacion_fecha::date) AS fecha
FROM puntos_venta.incidencias
WHERE estado IN ('EN TRAMITE', 'RECIBIDO')



SELECT *
FROM control_inventarios.id_bodegas


SELECT *
FROM activos_fijos.centros_costos
;
UPDATE puntos_venta.incidencias
SET finalizacion_fecha   = CURRENT_TIMESTAMP,
    finalizacion_usuario = 'CAJA'
WHERE numero_incidencia = 1


--   51653369

SELECT COUNT(transaccion), transaccion
FROM control_inventarios.transacciones
WHERE tipo_movimiento = 'TRANSFER+'
GROUP BY transaccion
HAVING COUNT(transaccion) > 1
   AND COUNT(transaccion) < 5
ORDER BY MAX(fecha) DESC
LIMIT 10;

SELECT LENGTH(transaccion) AS length, COUNT(*) AS count
FROM control_inventarios.transacciones
GROUP BY LENGTH(transaccion);


WHERE transaccion =

SELECT item, descripcion, unidad_medida, numero_decimales



SELECT *
FROM puntos_venta.tipos_defecto


-- Step 1: Alter the column type
         ALTER TABLE puntos_venta.tipos_defecto
ALTER
COLUMN codigo_defecto TYPE VARCHAR(3);

-- Step 2: Update existing records to the new format
UPDATE puntos_venta.tipos_defecto
SET codigo_defecto = LPAD(codigo_defecto::text, 3, '0');


SELECT *
FROM puntos_venta.reclamos_detalle

-- Step 1: Alter the column type
         ALTER TABLE puntos_venta.reclamos_detalle
ALTER
COLUMN codigo_defecto TYPE VARCHAR(3);

-- Step 2: Update existing records to the new format
UPDATE puntos_venta.reclamos_detalle
SET codigo_defecto = LPAD(codigo_defecto::text, 3, '0');



ALTER TABLE
    control_inventarios.id_bodegas
    ADD COLUMN centro_costo varchar(3);


SELECT *
FROM puntos_venta.reclamos_cabecera


SELECT *
FROM control_inventarios.items
WHERE numero_decimales > 0

SELECT *
FROM control_inventarios.transacciones
ORDER BY transaccion DESC
    C
SELECT COALESCE()
FROM activos_fijos.centros_costos



SELECT COALESCE(no_se_cuenta, '') no_se_cuenta
FROM control_inventarios.ciclo_conteo
WHERE fecha = CURRENT_DATE

SELECT primer_conteo, ultimo_conteo
FROM sistema.parametros_almacenes
WHERE bodega = '001'



SELECT *
FROM puntos_venta.incidencias pi


UPDATE puntos_venta.incidencias
SET observacion = UPPER(observacion) JOIN activos_fijos.centros_costos cc
ON pi.centro_costo = cc.codigo
    "SELECT pi.numero_incidencia, pi.creacion_fecha::date as creacion_fecha, cc.subcentro, " + _
    "  pi.grupo, pi.observacion, pi.estado " + _
    "FROM ordenes_venta.pedidos_cabecera pc "
    "WHERE (pi.numero_incidencia = $1 or $1 = '' ) " + _
    "  AND (pi.estado = $2 or $2 = '' ) " + _
    "  AND  pi.creacion_fecha BETWEEN  $1 AND $2 " + _
    "ORDER BY pc.fecha_pedido desc ";



SELECT *
FROM puntos_venta.incidencias_cambiar_estado_noautorizado(4.00, 'asfd', '3191')


SELECT *
FROM activos_fijos.centros_costos

SELECT *
FROM cuentas_cobrar.cliente s


SELECT *
FROM sistema.usuarios


SELECT *, COALESCE()
FROM sistema.email_masivo_cabecera
WHERE numero_email IS NOT NULL
ORDER BY numero_email DESC LblFechaCompletado.visible = FALSE
TxtFechaCompletado.visible = FALSE

LblFechaNoAutorizado.visible = FALSE
TxtFechaNoAutorizado.visible = FALSE
TxtObservacionesNoAutorizado.visible = FALSE
LblObservacionesNoAutorizado.visible = FALSE

LblFechaRecibido.visible = FALSE
TxtFechaRecibido.visible = FALSE



SELECT *
FROM trabajo_proceso.requerimiento_guia


SELECT email
FROM sistema.usuarios
WHERE codigo =



SELECT modulo_id
FROM sistema.parametros
GROUP BY modulo_id



SELECT ALFA
FROM sistema.parametros
WHERE modulo_id = 'CRM'
  AND codigo = 'CORREO_AUTO_ENCARGADO_CALIDAD'



SELECT *
FROM sistema.email_masivo_cabecera
WHERE numero_email IS NOT NULL
ORDER BY numero_email DESC



SELECT *
FROM sistema.email_masivo_detalle
WHERE numero_email = 2866



SELECT *
FROM puntos_venta.incidencias;


UPDATE puntos_venta.incidencias
SET finalizacion_fecha = NULL,
    noautorizado_fecha = NULL,
    recepcion_fecha    = NULL


ALTER TABLE control_inventarios.id_bodegas
    DROP COLUMN correos_calidad_reclamo_auto,
    DROP COLUMN centro_costo;


SELECT ROUND(1.499, 2)



SELECT *
FROM puntos_venta.incidencias

SELECT *
FROM trabajo_proceso.requerimiento_guia
WHERE centro_costo_origen IN (SELECT DISTINCT pa.centro_costo
                              FROM SISTEMA.parametros_almacenes AS pa)
  AND fecha_entregada IS NOT NULL

  AND fecha_entregada IS NULL
  AND fecha_recibido_almacen IS NULL



SELECT *
FROM trabajo_proceso.requerimiento_guia
WHERE fecha_recibido_almacen IS NOT NULL



SELECT rg.nro_requerimiento,
       rg.item,
       it.descripcion,
       rg.fecha_solicitud,
       rg.fecha_requerimiento,
       rg.cantidad_solicitada,
       rg.comentario,
       rg.cantidad_entragada,
       rg.fecha_entregada,
       rg.fecha_recibido_almacen,
       CASE
           WHEN rg.fecha_requerimiento IS NOT NULL AND
                rg.fecha_entregada IS NULL AND
                rg.fecha_recibido_almacen IS NULL
               THEN 'EN TRAMITE'
           WHEN rg.fecha_entregada IS NOT NULL AND rg.fecha_recibido_almacen IS NULL
               THEN 'ENTREGADO'
           WHEN rg.fecha_recibido_almacen IS NOT NULL
               THEN 'RECIBIDO'
           ELSE ''
           END AS estado
FROM trabajo_proceso.requerimiento_guia rg
         JOIN control_inventarios.items it ON it.item = rg.item
WHERE (rg.centro_costo_origen = '' OR '' = '')
  AND ('' = '' OR '' = '' OR fecha_solicitud BETWEEN ''::date AND ''::date)
  AND (('' = 'EN TRAMITE' AND rg.fecha_requerimiento IS NOT NULL AND rg.fecha_entregada IS NULL AND
        rg.fecha_recibido_almacen IS NULL) OR
       ('' = 'ENTREGADO' AND rg.fecha_entregada IS NOT NULL AND rg.fecha_recibido_almacen IS NULL) OR
       ('' = 'RECIBIDO' AND rg.fecha_recibido_almacen IS NOT NULL) OR
       ('' = '' AND TRUE))
  AND (rg.nro_requerimiento = '0000880562' OR '0000880562' = '')



SELECT *
FROM trabajo_proceso.requerimiento_guia rg
WHERE rg.nro_requerimiento = '0000929367'

SELECT centro_costo
FROM sistema.parametros_almacenes


SELECT *
FROM sistema.email_masivo_cabecera
WHERE numero_email IS NOT NULL
ORDER BY numero_email DESC



SELECT *
FROM control_inventarios.items
WHERE bodega = 'MD';


SELECT COUNT(*)
FROM puntos_venta.requerimientos_consulta('', '', '', '', '') AS rd
WHERE estado = 'EN TRAMITE'


SELECT DISTINCT centro_costo
FROM SISTEMA.parametros_almacenes

SELECT *
FROM ordenes_venta.pedidos_cabecera

SELECT modulo_id
FROM sistema.parametros
GROUP BY modulo_id

INSERT INTO sistema.parametros (modulo_id, codigo, descripcion, alfa, numero, fecha, conversion_dolar,
                                fecha_ultima_actualizacion, fecha_migrada, migracion, numero_ord_mp, interface_envia)
VALUES ('CRM', 'USUARIOS_ACCESO_MOD_PEDIDOS_CAB',
        'Usuarios con acceso a las opciones de modificacion de la cabecera(Actualizacion de Cliente, Vendedor, Dias plazo, etc.) de los Pedidos en el CRM. En el alfa se agregan los codigos de usuario separados por Comas(<Codigo1>,<Codigo2>,...)',
        '9665', 0.000000, NULL, FALSE, '2024-11-11',
        NULL, 'NO', NULL, TRUE);


DELETE
FROM sistema.parametros
WHERE modulo_id = 'CRM'
  AND codigo = 'USUARIOS_ACCESO_MOD_PEDIDOS_CAB'


SELECT *
FROM sistema.parametros
WHERE modulo_id = 'CRM'
  AND codigo = 'USUARIOS_ACCESO_MOD_PEDIDOS_CAB'

SELECT UNNEST(STRING_TO_ARRAY(sp.alfa, ',')) AS tipos
FROM sistema.parametros sp
WHERE sp.codigo = 'USUARIOS_ACCESO_MOD_PEDIDOS_CAB'
  AND sp.modulo_id = 'CRM';



SELECT EXISTS (SELECT 1
               FROM sistema.parametros sp
               WHERE sp.codigo = 'USUARIOS_ACCESO_MOD_PEDIDOS_CAB'
                 AND sp.modulo_id = 'CRM'
                 AND '9665' = ANY (STRING_TO_ARRAY(sp.alfa, ',')))


SELECT ordenes_venta.pedidos_usuario_modifica_cabecera('9665')

SELECT respuesta
FROM ordenes_venta.pedidos_usuario_modifica_cabecera('9665d')



SELECT *
FROM SISTEMA.menu
WHERE moduloid = 13
ORDER BY menuid DESC

INSERT INTO sistema.menu (titulo, nombre, orden, padreid, moduloid, esmenu, migracion, padre, path_web)
VALUES ('Almacenes', 'AlmacenesMenu', 7, NULL, 13, TRUE, 'NO', NULL, NULL);
-- AlmacenesIncidentes
-- AlmacenesRequerimientos


SELECT
FROM control_inventarios.id_bodegas



SELECT LENGTH('-----------------------------------------------------------------------------')



SELECT *
FROM control_inventarios.items
WHERE descripcion LIKE '%Ñ%'


SELECT *
FROM puntos_venta.requerimientos_consulta('', '', '', '', '')

select *
from recursos_humanos.


SELECT referencia,
       item,
       descripcion,
       unidad_medida,
       cantidad,
       precio,
       descuento,
       total_precio
FROM control_inventarios.reporte_detalledocumentosfs($P{preferencia} )



select TRANSLATE('Ádios', 'ÁÍÓÚ', 'AIOS')::varchar as hola




select *
from puntos_venta.caja_totales
where caja = '06'


select *
from puntos_venta.reporte_cierrecajafs('60637', 'S')


select *
from sistema.parametros
where modulo_id like'%FERIA%'



select fc.referencia, fc.fecha, fd.precio
from puntos_venta.facturas_cabecera fc
join puntos_venta.facturas_detalle fd on fc.referencia = fd.referencia
WHERE fc.caja NOT IN ('90')
AND POSITION('.' IN TRIM(TRAILING '0' FROM TO_CHAR(fd.precio, 'FM999999999.999999'))) + 2 < LENGTH(TRIM(TRAILING '0' FROM TO_CHAR(fd.precio, 'FM999999999.999999')))
order by fc.fecha DESC



  SELECT recibe_incidencias
  FROM sistema.usuarios u
  WHERE codigo = '3191'
    AND email != ALL (STRING_TO_ARRAY(
          (SELECT p.alfa
           FROM sistema.parametros p
           WHERE p.modulo_id = 'SISTEMA'
             AND p.codigo = 'CORREO_AUTO_INCIDEN_REQUERIM'), ','))


select *
from sistema.usuarios_activos
where computador = 'ANALISTA3'

  SELECT codigo
  FROM sistema.usuarios u
  WHERE codigo = '7293'
    AND email = any (STRING_TO_ARRAY(
          (SELECT p.alfa
           FROM sistema.parametros p
           WHERE p.modulo_id = 'SISTEMA'
             AND p.codigo = 'CORREO_AUTO_INCIDEN_REQUERIM'), ','))

select *
from sistema.usuarios
where email = 'janeth.rodas@pasa.ec';

select *
from sistema.usuarios
where nombres like '%ADRIANA%'; -- 1894

SELECT *
FROM puntos_venta.incidencias_estados
where numero_incidencia = 5


  SELECT ie.fecha::date as fecha, ie.estado, ie.observacion, u.nombres as usuario, ie.fecha::time as hora
  FROM puntos_venta.incidencias_estados ie
  join sistema.usuarios u on ie.usuario = u.codigo
  WHERE numero_incidencia = 5