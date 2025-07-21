select *
from sistema.usuarios_activos
where computador = 'ANALISTA3'

SELECT usuarios_activos.usuario, usuarios.nombres
FROM sistema.usuarios_activos
         INNER JOIN sistema.usuarios ON sistema.usuarios_activos.usuario = sistema.usuarios.codigo
WHERE TRIM(computador) = 'ANALISTA3'
  AND estado = 'ACTIVO'
  AND fecha = CURRENT_DATE


select *
FROM puntos_venta.reclamos_cabecera
where recepcion_fecha is null;




select transaccion
from control_inventarios.transacciones
where tipo_movimiento = 'TRANSFER+'
order by fecha desc





SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_name LIKE '%seccion%'
  AND table_type = 'BASE TABLE';


select *
from activos_fijos.seccion_grupo


select *
from puntos_venta.requerimientos_estados

select nro_requerimiento, item, descripcion, unidad_medida, numero_decimales, cantidad_solicitada, existencias
from puntos_venta.requerimientos_consulta_modifica_cantidad('0000721588') d


select substring('P32221' from 2);

INSERT INTO sistema.accesos (codigo,proceso,creacion_usuario,creacion_fecha,creacion_hora,modulo,migracion,acceso_especial,observacion_acceso_especial) VALUES
	 ('5022','RevisionReclamos',NULL,'2025-04-23','11:05:11','CRM','NO',false,'');
INSERT INTO sistema.accesos (codigo,proceso,creacion_usuario,creacion_fecha,creacion_hora,modulo,migracion,acceso_especial,observacion_acceso_especial) VALUES
	 ('5022','DespachosFacturaciónReclamosAlmacenesClientes',NULL,'2025-04-23','11:08:17','CRM','NO',false,'');


select *
from sistema.usuarios_activos
where computador = 'ANALISTA3'

