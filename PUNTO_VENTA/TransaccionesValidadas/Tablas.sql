-- Tabla sirve para saver que usuarios y bodegas deben aparecer en el listado o seleccionarse por defualt en la transferencias a la Bodega
-- Seleccionada,
-- EJM: PED-CLI, 001, 9171, ''
--      PED-CLI, 001, 4565, 'p000'
--      PED-CLI, 001, 4666, 'p000'
--      PED-CLI, 001, 4234, 'p000'
--      DEV-SUC, 001, 9171, ''
--      DEV-FAL, 001, 4565, 'p000'
--      DEV-FAL, 001, 4666, 'p000'
--      DEV-FAL, 001, 4234, 'p000'

CREATE TABLE control_inventarios.transacciones_encargado
(
    id        serial PRIMARY KEY,
    codigo    varchar(7) NOT NULL
        CONSTRAINT fk_transacciones_referencia
            REFERENCES control_inventarios.transacciones_referencia (codigo),
    bodega    varchar(3) NOT NULL,
    usuario   varchar(4) NOT NULL,
    ubicacion varchar(4) NULL
);

ALTER TABLE control_inventarios.transacciones_encargado
    ADD CONSTRAINT unique_codigo_bodega_usuario UNIQUE (codigo, bodega, usuario);

INSERT INTO control_inventarios.transacciones_encargado (codigo, bodega, usuario, ubicacion)
VALUES ('DEV-SUC', 'CAC', '5022', NULL),

       ('DEV-FAL', 'CAC', '7991', 'P120'),
       ('DEV-FAL', 'CAC', '0622', 'P121'),
       ('DEV-FAL', 'CAC', '1538', 'P119'),

       ('PED-CAT', 'CAC', '6666', 'CAT0'),

       ('PED-CLI', 'CAC', '5022', NULL),
       ('PED-CLI', 'CAC', '7991', 'P120'),
       ('PED-CLI', 'CAC', '0622', 'P121'),
       ('PED-CLI', 'CAC', '1538', 'P119');

SELECT te.*, u.nombres
FROM control_inventarios.transacciones_encargado te
join sistema.usuarios u on u.codigo = te.usuario
WHERE te.bodega = 'CAC'
  AND te.codigo = 'DEV-FAL';

-- MONICA CALDERON -> CAT0 -> 2168


SELECT *
FROM control_inventarios.id_ubicaciones
where ubicacion = 'P120'


select true in (select true
from generate_series(1, 5)
union ALL
SELECT false
from generate_series(1, 5))

SELECT *
FROM control_inventarios.transferencias_pendientes_resumen();



CREATE INDEX CONCURRENTLY idx_transacciones_transfer_plus_opt ON control_inventarios.transacciones
USING btree (fecha, bodega, ubicacion, transaccion)
WHERE tipo_movimiento = 'TRANSFER+'
AND recepcion_completa IS DISTINCT FROM TRUE;

select *
from sistema.ip_almacen
where ip = '127.0.0.1'

select *
from control_inventarios.id_bodegas
where bodega = '622'






select *

from cheques.depositos

where comprobante='000001425734';



select *

from cheques.detalle_efectivo

where comprobante='000001425734';



select *

from cheques.cheques

where comprobante_deposito='000001425734';


SELECT *
FROM cheques.detalle_efectivo
WHERE comprobante = '000000000049'
AND cuenta = '000006438148'

ALTER TABLE cheques.detalle_efectivo
ALTER COLUMN almacen SET DEFAULT '';

UPDATE cheques.detalle_efectivo
SET almacen = ''
WHERE almacen IS NULL;



ALTER TABLE cheques.detalle_efectivo
DROP CONSTRAINT pk_detalle_efectivo;

ALTER TABLE cheques.detalle_efectivo
ADD CONSTRAINT pk_detalle_efectivo PRIMARY KEY (cuenta, comprobante, secuencia, almacen);




SELECT *
FROM cheques.detalle_efectivo
WHERE comprobante = '000000000049'
AND cuenta = '000006438148';


select *
from cheques.depositos
where comprobante='000000000049';


select *
from cheques.cheques
where comprobante_deposito='000000000049';


SELECT * FROM puntos_venta.facturas_detalle order by fecha desc limit 50000