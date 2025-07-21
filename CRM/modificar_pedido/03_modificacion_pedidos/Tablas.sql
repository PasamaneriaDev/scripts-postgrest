-- drop table ordenes_venta.pedidos_detalle_bitacora
CREATE TABLE ordenes_venta.pedidos_detalle_bitacora
(
    secuencia_bitacora            serial,

    numero_pedido                 varchar(10)   NOT NULL,
    item                          varchar(15)   NOT NULL,
    secuencia                     integer       NOT NULL,
    cliente                       varchar(6)    NOT NULL,
    cliente_catalogo              varchar(13)   NOT NULL,
    color_comercial               varchar(80)   NOT NULL,

    porcentaje_descuento_anterior numeric(7, 3) NOT NULL,
    porcentaje_descuento_nuevo    numeric(7, 3),

    precio_anterior               numeric(15, 5)         DEFAULT 0,
    precio_nuevo                  numeric(15, 5)         DEFAULT 0,

    descripcion_anterior          varchar(120),
    descripcion_nueva             varchar(120),

    creacion_usuario              varchar(4),
    creacion_fecha                timestamp     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_pedidos_detalle_bitacora
        PRIMARY KEY (secuencia_bitacora)
);


SELECT *
FROM ordenes_venta.pedidos_detalle_bitacora

-- drop table ordenes_venta.pedidos_cabecera_bitacora
CREATE TABLE ordenes_venta.pedidos_cabecera_bitacora
(
    secuencia_bitacora       serial,
    numero_pedido            varchar(10) NOT NULL,

    cliente_anterior         varchar(6),
    terminos_pago_anterior   varchar(20),
    dias_plazo_anterior      numeric(3),
    monto_iva_anterior       numeric(13, 2),
    monto_pendiente_anterior numeric(15, 2),
    vendedor_anterior        varchar(4),
    codigo_venta_anterior    varchar(3),
    bodega_anterior          varchar(3),

    cliente_nuevo            varchar(6),
    terminos_pago_nuevo      varchar(20),
    dias_plazo_nuevo         numeric(3),
    monto_iva_nuevo          numeric(13, 2),
    monto_pendiente_nuevo    numeric(15, 2),
    vendedor_nuevo           varchar(4),
    codigo_venta_nuevo       varchar(3),
    bodega_nueva             varchar(3),

    creacion_usuario         varchar(4),
    creacion_fecha           timestamp   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_pedidos_cabecera_bitacora
        PRIMARY KEY (secuencia_bitacora)
);
