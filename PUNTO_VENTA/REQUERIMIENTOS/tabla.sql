CREATE TABLE puntos_venta.requerimientos_estados
(
    secuencia         serial4      NOT NULL,
    nro_requerimiento varchar      NOT NULL,
    estado            varchar(20)  NULL,
    usuario           varchar(4)   NULL,
    fecha             timestamp DEFAULT CURRENT_TIMESTAMP,
    observacion       varchar(400) NULL,
    CONSTRAINT requerimientos_estados_pkey PRIMARY KEY (secuencia),
    CONSTRAINT requer_estad_requer_guia_fkey FOREIGN KEY (nro_requerimiento) REFERENCES trabajo_proceso.requerimiento_guia (nro_requerimiento)
);



/**********/
SELECT rg.nro_requerimiento, rg.item, rg.cantidad_solicitada, re.estado, re.fecha
FROM trabajo_proceso.requerimiento_guia rg
         JOIN LATERAL (
    SELECT re.estado, re.fecha
    FROM puntos_venta.requerimientos_estados re
    WHERE re.nro_requerimiento = rg.nro_requerimiento
    ORDER BY re.fecha DESC, re.secuencia DESC
    LIMIT 1
    ) re ON TRUE
WHERE item = 'M8351'



INSERT INTO sistema.parametros (modulo_id, codigo, descripcion, alfa)
    VALUES ('PVENTAS', 'BODEGAS_REQUERIMIENTOS', 'Bodegas usadas para validar la existencia al crear requerimientos', 'MD,079,MB');



SELECT item, count(*)
FROM control_inventarios.bodegas b
WHERE b.bodega = ANY('{MD,079,MB}'::TEXT[])
and existencia > 0
  --AND item = 'W230'
group by item
having count(*) > 1;

select *
FROM control_inventarios.bodegas b
WHERE b.bodega = ANY('{MD,079,MB}'::TEXT[])
and item = '0ESFERO';

select o_existencias
from puntos_venta.requerimientos_existencias_item('M6117-000')


alter table trabajo_proceso.requerimiento_guia
add column activo boolean default true;


select *
from trabajo_proceso.requerimiento_guia
where centro_costo_origen IN (SELECT DISTINCT pa.centro_costo
                                   FROM SISTEMA.parametros_almacenes AS pa)
order by fecha_solicitud desc limit 10;


select *
from puntos_venta.requerimientos_estados

SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_name LIKE '%estado%'
  AND table_type = 'BASE TABLE';


select *
from roles.tipos_estados


CREATE TABLE sistema.estados (
    id_estado SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    grupo VARCHAR(50) NOT NULL,
    descripcion TEXT,
    activo BOOLEAN DEFAULT TRUE,
    CONSTRAINT uq_nombre_grupo UNIQUE (nombre, grupo)
);

INSERT INTO sistema.estados (nombre, grupo, descripcion) VALUES
('EN TRAMITE', 'REQUERIMIENTOS_ALMACENES', 'Requerimiento creado por un almacen'),
('AUTORIZADO', 'REQUERIMIENTOS_ALMACENES', 'Requerimiento autorizado por personal de seguimiento'),
('ENVIADO', 'REQUERIMIENTOS_ALMACENES', 'Requerimiento Enviado por el personal de bodegas a la bodega de despachos'),
('RECIBIDO', 'REQUERIMIENTOS_ALMACENES', 'Requerimiento Recibido por el almacen'),
('NO AUTORIZADO', 'REQUERIMIENTOS_ALMACENES', 'Requerimiento no autorizado por personal de seguimiento'),
('NO ENVIADO', 'REQUERIMIENTOS_ALMACENES', 'Requerimiento no enviado por el personal de bodegas a la bodega de despachos');

INSERT INTO sistema.estados (nombre, grupo, descripcion) VALUES
('EN TRAMITE', 'INCIDENCIAS_ALMACENES', 'Incidencia creada por un almacen'),
('AUTORIZADO', 'INCIDENCIAS_ALMACENES', 'Incidencia autorizado por personal de seguimiento y asignada al encargado'),
('EN EJECUCION', 'INCIDENCIAS_ALMACENES', 'Incidencia recibida y puesta en marcha por el encargado'),
('EJECUTADO', 'INCIDENCIAS_ALMACENES', 'Incidencia completada o ejecutada por el encargado'),
('COMPLETO', 'INCIDENCIAS_ALMACENES', 'Incidencia marcada terminada por el almacen'),
('NO AUTORIZADO', 'INCIDENCIAS_ALMACENES', 'Incidencia no autorizada por el personal de seguimiento'),
('NO EJECUTADO', 'INCIDENCIAS_ALMACENES', 'Incidencia recibida y no puesta en marcha por el encargado');
