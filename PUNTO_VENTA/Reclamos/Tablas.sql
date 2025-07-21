CREATE TABLE puntos_venta.reclamos_cabecera (
	numero_reclamo serial4 NOT NULL,
	centro_costo varchar(3) NOT NULL,
	nombre_cliente varchar(70) NOT NULL,
	fecha_reclamo date NULL,
	fecha_compra date NULL,
	problema_solucionado bool NULL,
	solucion varchar(100) NULL,
	productos_lavado varchar(30) NULL,
	metodo_lavado varchar(30) NULL,
	metodo_secado varchar(30) NULL,
	observaciones varchar(300) NOT NULL,
	numero_transferencia varchar(10) NULL,
	numero_devolucion_planta varchar(10) NULL,
	numero_nota_credito varchar(10) NULL,
	creacion_usuario varchar(4) NULL,
	creacion_fecha timestamp DEFAULT '2024-09-24 14:42:00.259515'::timestamp without time zone NULL,
	recepcion_usuario varchar(4) NULL,
	recepcion_fecha timestamp NULL,
	revision_calidad_usuario varchar(4) NULL,
	revision_calidad_fecha timestamp NULL,
	CONSTRAINT pk_secuencia_cabecera_numero_reclamo PRIMARY KEY (numero_reclamo)
);

-- drop table puntos_venta.reclamos_detalle;
CREATE TABLE puntos_venta.reclamos_detalle (
	numero_reclamo numeric(10) NOT NULL,
	item varchar(15) NOT NULL,
	cantidad numeric(10, 3) DEFAULT 0 NOT NULL,
	anio_trimestre numeric(3) DEFAULT 0 NULL,
	codigo_defecto varchar(3) DEFAULT '001' NOT NULL,
	observaciones varchar NULL,
	CONSTRAINT pk_secuencia_detalle_numero_reclamo PRIMARY KEY (numero_reclamo, item)
);

-- drop table puntos_venta.tipos_defecto;
Create Table puntos_venta.tipos_defecto
(
    codigo_defecto varchar(4),
    descripcion varchar(100) NOT NULL,
    CONSTRAINT pk_tipo_defecto PRIMARY KEY (codigo_defecto)
);

select LPAD(codigo_defecto::text, 3, '0') codigo_defecto, descripcion
from puntos_venta.tipos_defecto

INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('001', 'FALLADO HILO GRUESO');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('002', 'FALLADO HILO DELGADO');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('003', 'RAYAS POR CONTAMINACIÓN DE FIBRA');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('004', 'MARIPOSAS');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('005', 'ZURCIDOS DE CIRCULARES');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('006', 'CAIDA DE TEJIDO');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('007', 'HUECOS');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('008', 'CONTAMINACIÓN CON OTROS MATERIALES');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('009', 'FALLA DE MALLA POR TENSIÓN');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('010', 'MALLA CON MOTAS');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('011', 'COSIDOS');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('012', 'HILO DOBLE');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('013', 'FALLA DE URDIDO');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('014', 'Licra rota ');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('015', 'Falla de aguja ');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('016', 'TONOS (diferencia de matiz)');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('017', 'MALLA MANCHADA');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('018', 'QUIEBRES');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('019', 'MANCHAS DE PINTURA');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('020', 'FALTA DE SOLIDEZ');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('021', 'DESENTRADO');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('022', 'FALTA DE ADHERENCIA');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('023', 'ESTAMPADO LADO INCORRECTO');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('024', 'ESTAMPADO EN OTRA MALLA');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('025', 'SIN ESTAMPAR');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('026', 'ESTAMPADO DIFERENTE');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('027', 'TRANSFER QUEMADO');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('028', 'PICADO DE AGUJA');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('029', 'PICADO DE TIJERA (OPERARIA)');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('030', 'PRENDA MAL ARMADA');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('031', 'PRENDAS ASIMETRICA ');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('032', 'DESFASE DE RAYAS');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('033', 'MALLA SESGADA');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('034', 'MEDIDAS INCORRECTAS');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('035', 'PRENDA INCOMPLETA');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('036', 'COSTURA DISPAREJA');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('037', 'COSTURA SOBRECOSIDA');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('038', 'DESCASE DE COSTURAS');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('039', 'DESCOSIDO');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('040', 'DOBLADILLO MAL PULIDO');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('041', 'FALTA DE OPERACIÓN');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('042', 'MAL RIBETEADO');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('043', 'MAL REMATADO');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('044', 'OJAL MAL REALIZADO');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('045', 'ONDEADO');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('046', 'PLIEGUES');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('047', 'PUNTADA MAL CALIBRADA');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('048', 'RECUBIERTO ACORDONADO');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('049', 'PUNTADA SALTADA');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('050', 'PUNTADA REVENTADA');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('051', 'PUNTADA INCOMPLETA');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('052', 'PIQUETE MAL REALIZADO');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('053', 'PUNTADA FLOJA');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('054', 'SIN ETIQUETA ');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('055', 'ETIQUETA EQUIVOCADA');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('056', 'ETIQUETA MAL COLOCADA/DESCENTRADA');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('057', 'ELASTICO ENCARRUJADO');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('058', 'ELASTICO MEDIDAS MAL  CALIBRADAS');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('059', 'ELASTICO MANCHADO (AGENTE EXTERNO)');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('060', 'MANCHAS DE ACEITE');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('061', 'MANCHAS DE OXIDO');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('062', 'PLIEGUES EN BORDADO');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('063', 'INSUMOS DEFECTUOSOS');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('064', 'PRENDA SUCIA (POLVO, LÁPIZ, MARCADOR)');
INSERT INTO puntos_venta.tipos_defecto(codigo_defecto, descripcion) VALUES ('065', 'MANCHAS POR BAJA SOLIDEZ A LA LUZ');






-- REPORTE
select *
from puntos_venta.reclamos_detalle

SELECT *
FROM puntos_venta.tipos_defecto
LIMIT 1;


delete
from puntos_venta.reclamos_detalle
where TRUE

INSERT INTO puntos_venta.reclamos_detalle (numero_reclamo, item, cantidad, anio_trimestre, codigo_defecto, observaciones) VALUES (2, '10701126919551', 1.000, 233, '008', '');
INSERT INTO puntos_venta.reclamos_detalle (numero_reclamo, item, cantidad, anio_trimestre, codigo_defecto, observaciones) VALUES (2, '0CHOCOLATE', 1.000, 233, '001', '');
INSERT INTO puntos_venta.reclamos_detalle (numero_reclamo, item, cantidad, anio_trimestre, codigo_defecto, observaciones) VALUES (2, '0CUPON', 1.000, 233, '016', '');
INSERT INTO puntos_venta.reclamos_detalle (numero_reclamo, item, cantidad, anio_trimestre, codigo_defecto, observaciones) VALUES (3, '10712066203221', 1.000, 204, '009', '');
INSERT INTO puntos_venta.reclamos_detalle (numero_reclamo, item, cantidad, anio_trimestre, codigo_defecto, observaciones) VALUES (4, '10722036522161', 1.000, 203, '001', '');
INSERT INTO puntos_venta.reclamos_detalle (numero_reclamo, item, cantidad, anio_trimestre, codigo_defecto, observaciones) VALUES (4, '100000M0000011', 1.000, 213, '013', '');
INSERT INTO puntos_venta.reclamos_detalle (numero_reclamo, item, cantidad, anio_trimestre, codigo_defecto, observaciones) VALUES (4, '10030006942051', 1.000, 241, '055', '');
INSERT INTO puntos_venta.reclamos_detalle (numero_reclamo, item, cantidad, anio_trimestre, codigo_defecto, observaciones) VALUES (5, '10722006938641', 1.000, 203, '008', '1');
INSERT INTO puntos_venta.reclamos_detalle (numero_reclamo, item, cantidad, anio_trimestre, codigo_defecto, observaciones) VALUES (6, '10722006938641', 1.000, 203, '012', '');
INSERT INTO puntos_venta.reclamos_detalle (numero_reclamo, item, cantidad, anio_trimestre, codigo_defecto, observaciones) VALUES (8, '10701066919551', 1.000, 203, '019', '');
INSERT INTO puntos_venta.reclamos_detalle (numero_reclamo, item, cantidad, anio_trimestre, codigo_defecto, observaciones) VALUES (8, '0OBSEQUIO-BO', 1.000, 204, '065', 'DESPINTADO');
INSERT INTO puntos_venta.reclamos_detalle (numero_reclamo, item, cantidad, anio_trimestre, codigo_defecto, observaciones) VALUES (10, '10701126522161', 1.000, 204, '001', 'ASDF');
INSERT INTO puntos_venta.reclamos_detalle (numero_reclamo, item, cantidad, anio_trimestre, codigo_defecto, observaciones) VALUES (1, '10701186522161', 1.000, 263, '021', '');
INSERT INTO puntos_venta.reclamos_detalle (numero_reclamo, item, cantidad, anio_trimestre, codigo_defecto, observaciones) VALUES (9, '0OBSEQUIO-BO', 1.000, 203, '001', 'SADF');
INSERT INTO puntos_venta.reclamos_detalle (numero_reclamo, item, cantidad, anio_trimestre, codigo_defecto, observaciones) VALUES (9, '10712186203221', 1.000, 244, '063', 'ASDF');
INSERT INTO puntos_venta.reclamos_detalle (numero_reclamo, item, cantidad, anio_trimestre, codigo_defecto, observaciones) VALUES (7, '10170006201091', 10.000, 203, '030', '');
INSERT INTO puntos_venta.reclamos_detalle (numero_reclamo, item, cantidad, anio_trimestre, codigo_defecto, observaciones) VALUES (7, '1017VARSURTID6', 1.000, 204, '057', 'ASDF');
INSERT INTO puntos_venta.reclamos_detalle (numero_reclamo, item, cantidad, anio_trimestre, codigo_defecto, observaciones) VALUES (7, '10722066916641', 1.000, 204, '015', 'ITEM DEVUELTO');
INSERT INTO puntos_venta.reclamos_detalle (numero_reclamo, item, cantidad, anio_trimestre, codigo_defecto, observaciones) VALUES (11, '0BOLETO', 1.000, 203, '001', 'SIN OBSERVACION');

select *
from puntos_venta.reclamos_detalle



ALTER TABLE reclamos_cabecera
ADD codigo_destinatario VARCHAR(5);