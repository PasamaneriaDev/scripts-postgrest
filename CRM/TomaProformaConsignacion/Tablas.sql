CREATE SEQUENCE cuentas_cobrar.clientes_consignacion_seq START 1;
DROP TABLE IF EXISTS cuentas_cobrar.clientes_consignacion;
CREATE TABLE cuentas_cobrar.clientes_consignacion
(
    id_cliente_consignacion integer    DEFAULT NEXTVAL('cuentas_cobrar.clientes_consignacion_seq'::regclass)
        CONSTRAINT pk_clientes_consignacion
            PRIMARY KEY,
    codigo                  varchar(6) NOT NULL,
    bodega                  varchar(3) NOT NULL,
    dias_plazo              numeric(3) DEFAULT 0,
    activo                  BOOLEAN    DEFAULT TRUE,
    creacion_fecha          timestamp  DEFAULT NOW()
);
ALTER TABLE cuentas_cobrar.clientes_consignacion
    ADD CONSTRAINT uq_codigo_bodega UNIQUE (codigo, bodega);

INSERT INTO cuentas_cobrar.clientes_consignacion
    (codigo, bodega, activo, dias_plazo)
VALUES ('110887', '157', TRUE, 60),
       ('111004', '158', FALSE, 60),
       ('111128', '159', TRUE, 90),
       ('200570', '160', FALSE, 45),
       ('200570', '161', TRUE, 45),
       ('108001', '162', TRUE, 90);

SELECT *
FROM cuentas_cobrar.clientes_consignacion;


SELECT ib.bodega, ib.descripcion
FROM cuentas_cobrar.clientes_consignacion cc
         JOIN control_inventarios.id_bodegas ib ON cc.bodega = ib.bodega
WHERE cc.activo = TRUE;


SELECT *
FROM cuentas_cobrar.clientes
WHERE codigo = '108001'


SELECT *
FROM control_inventarios.id_bodegas
WHERE bodega = '161'

INSERT INTO control_inventarios.id_bodegas (bodega, descripcion, ciudad, lugar, tipo_bodega, ubicacion_default,
                                            cuenta_materia_prima, cuenta_mano_obra, cuenta_gastos_fabricacion,
                                            ajuste_materia_prima, ajuste_mano_obra, ajuste_gastos_fabricacion,
                                            cuenta_iva, cuenta_efectivo, cuenta_cheques, cuenta_vales_devoluciones,
                                            cuenta_tarjeta_pasa, cuenta_retenciones, cuenta_herramientas, cuenta_cash,
                                            cuenta_diners, cuenta_visa, cuenta_american, cuenta_master,
                                            cuenta_filancard, cuenta_cuota_facil, cuenta_tombola, cuenta_cambios,
                                            cuenta_comisariato, codigo_integracion_venta, codigo_integracion_devolucion,
                                            planta_o_bodega, tipo_gasto, tiene_existencia, tiene_transito,
                                            es_punto_venta, es_almacen_saldos, imprime_etiquetas_saldos,
                                            es_ventas_xmayor, tipo_distribucion, tiempo_reposicion, controla_toc, nivel,
                                            relacion, envio_paquetes, redondeo, relacion_reposicion,
                                            relacion_devolucion, fecha_inicio_transacciones, codigo_encera_buffer,
                                            provincia, creacion_usuario, creacion_fecha, creacion_hora, fecha_migrada,
                                            relacion_devolucion_obsoletos, direccion, migracion, permite_pedidos,
                                            cuenta_payphone, numero_pediddo_bodega, activo, cuenta_bono_pasa,
                                            cuenta_venta_programada, ubicacion_reserva, cuenta_billete_pasa,
                                            tiene_existencia_diaria, region, calcula_dias_desabastecimiento,
                                            cuenta_descuento_adicional, cuenta_union_pay, cuenta_billete_sol,
                                            nombre_corto, fecha_fin_transacciones, externo, cuenta_deuna, centro_costo,
                                            lugar_venta)
VALUES ('162', 'GORDILLO MARGARITA (Transito)', 'QUITO', '', 'S DHE', '0000', '11304010100000000', '11304010100000000',
        '11304010100000000', '11304010200000000', '11304010200000000', '11304010200000000', '21303010101000000',
        '11101030201000000', '11101030201000000', '21202010000000000', '11201030700000000', '11204020201000000', '',
        '11201030100000000', '11201030200000000', '11201030300000000', '11201030300000000', '11201030400000000',
        '11201030300000000', '11201030070000000', '', '61301000000000000', '', 'VAQ', 'DAQ', '', '1143', TRUE, FALSE,
        FALSE, FALSE, FALSE, FALSE, 'X', 18, TRUE, '02', '100', FALSE, 1, '100', '', NULL, '', '', '', NULL, '', NULL,
        '', 'AV. EDMUNDO CARV. (C.C.BOSQUE)', 'SI', TRUE, '11101040100000000', '101', FALSE, NULL, NULL, NULL, NULL,
        FALSE, NULL, FALSE, NULL, '11201040700000000', '11201030800000000', NULL, NULL, FALSE, '11201040800000000',
        NULL, NULL);


SELECT cc.id_cliente_consignacion, cc.bodega, c.nombre
FROM cuentas_cobrar.clientes_consignacion cc
         JOIN cuentas_cobrar.clientes c ON cc.codigo = c.codigo
WHERE cc.activo = TRUE;