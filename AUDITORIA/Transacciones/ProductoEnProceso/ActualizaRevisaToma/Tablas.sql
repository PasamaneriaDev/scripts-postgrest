CREATE SCHEMA IF NOT EXISTS inventario_proceso;

CREATE TABLE inventario_proceso.items
(
    item            varchar(15)              NOT NULL
        CONSTRAINT pk_items
            PRIMARY KEY,
    descripcion     varchar(100),
    codigo_rotacion varchar(6),
    unidad_medida   varchar(6),
    costo_promedio  numeric(11, 5) DEFAULT 0 NOT NULL,
    costo_estandar  numeric(11, 5) DEFAULT 0 NOT NULL,
    ultimo_costo    numeric(11, 5) DEFAULT 0 NOT NULL,
    existencia      numeric(14, 5) DEFAULT 0 NOT NULL,
    transito        numeric(12, 3) DEFAULT 0 NOT NULL,
    creacion_fecha  date           DEFAULT ('now'::text)::date,
    creacion_hora   varchar(8)     DEFAULT ('now'::text)::time(0) WITHOUT TIME ZONE
);

CREATE TABLE inventario_proceso.bodegas
(
    bodega             varchar(3) NOT NULL,
    item               varchar(15),
    existencia         numeric(14, 5) DEFAULT 0,
    cuenta_inventarios varchar(24),
    codigo_integracion varchar(3),
    creacion_usuario   varchar(4),
    creacion_fecha     date           DEFAULT ('now'::text)::date,
    creacion_hora      varchar(8)     DEFAULT ('now'::text)::time(0) WITHOUT TIME ZONE,
    CONSTRAINT pk_bodegas
        PRIMARY KEY (bodega, item)
);

CREATE TABLE inventario_proceso.ubicaciones
(
    bodega           varchar(3)  NOT NULL,
    ubicacion        varchar(4)  NOT NULL,
    item             varchar(15) NOT NULL,
    existencia       numeric(14, 5) DEFAULT 0,
    creacion_usuario varchar(4),
    creacion_fecha   date           DEFAULT ('now'::text)::date,
    creacion_hora    varchar(8)     DEFAULT ('now'::text)::time(0) WITHOUT TIME ZONE,
    CONSTRAINT pk_ubicaciones
        PRIMARY KEY (bodega, ubicacion, item)
);

CREATE TABLE inventario_proceso.costos
(
    item                              varchar(15) NOT NULL,
    tipo_costo                        varchar(10) NOT NULL,
    mantenimiento_materia_prima_dolar numeric(14, 8) DEFAULT 0,
    mantenimiento_materia_prima       numeric(14, 8) DEFAULT 0,
    mantenimiento_mano_obra           numeric(14, 8) DEFAULT 0,
    mantenimiento_gastos_fabricacion  numeric(14, 8) DEFAULT 0,
    nivel_materia_prima               numeric(14, 8) DEFAULT 0,
    nivel_mano_obra                   numeric(14, 8) DEFAULT 0,
    nivel_gastos_fabricacion          numeric(14, 8) DEFAULT 0,
    acumulacion_materia_prima         numeric(14, 8) DEFAULT 0,
    acumulacion_mano_obra             numeric(14, 8) DEFAULT 0,
    acumulacion_gastos_fabricacion    numeric(14, 8) DEFAULT 0,
    creacion_fecha                    date           DEFAULT ('now'::text)::date,
    creacion_hora                     VARCHAR(8)     DEFAULT ('now'::TEXT)::TIME(0) WITHOUT TIME ZONE,
    CONSTRAINT pk_costos
        PRIMARY KEY (item, tipo_costo)
);



CREATE TABLE inventario_proceso.ajustes
(
    documento        varchar(10)                                  NOT NULL,
    item             varchar(15)                                  NOT NULL,
    costo            numeric(11, 5) DEFAULT 0,
    costo_nuevo      numeric(11, 5) DEFAULT 0,
    orden            varchar(15),
    cantidad         numeric(12, 3) DEFAULT 0,
    conos            numeric(4)     DEFAULT 0,
    tara             numeric(12, 3) DEFAULT 0,
    cajon            numeric(12, 3) DEFAULT 0,
    constante        numeric(12, 3) DEFAULT 0,
    bodega           varchar(3)                                   NOT NULL,
    ubicacion        varchar(4),
    fecha            date,
    status           varchar(1)     DEFAULT ''::character varying NOT NULL,
    tipo             varchar(1)                                   NOT NULL,
    cuenta_ajuste    varchar(24),
    cuenta           varchar(24),
    creacion_fecha   date,
    creacion_hora    varchar(8),
    creacion_usuario varchar(4),
    secuencia        integer                                      NOT NULL
        CONSTRAINT pk_ajuste
            PRIMARY KEY,
    cantidad_ajuste  numeric(12, 3) DEFAULT 0,
    muestra          varchar(255),
    anio_trimestre   numeric(3)     DEFAULT 0
);

CREATE SEQUENCE inventario_proceso.transacciones_secuencia_seq START 1;
CREATE TABLE inventario_proceso.transacciones
(
    transaccion      varchar(10)    DEFAULT LPAD(
            ((sistema.secuencia_diaria_get('TRANSACCIONES_INVENTARIO_PROCESO'::text))::character varying)::text, 10,
            '0'::text),
    bodega           varchar(3),
    item             varchar(15),
    referencia       varchar(60),
    tipo_movimiento  varchar(40),
    fecha            date,
    cantidad         numeric(14, 5) DEFAULT 0,
    costo            numeric(11, 5) DEFAULT 0,
    modulo           varchar(30),
    documento        varchar(10),
    ubicacion        varchar(4),
    precio           numeric(11, 5) DEFAULT 0,
    creacion_usuario varchar(4),
    creacion_fecha   date           DEFAULT ('now'::text)::date,
    creacion_hora    varchar(8)     DEFAULT ('now'::text)::time(0) WITHOUT TIME ZONE,
    periodo          varchar(6),
    secuencia        integer        DEFAULT NEXTVAL('inventario_proceso.transacciones_secuencia_seq'::regclass) NOT NULL
        CONSTRAINT pk_secuencia_transacciones_inventarios
            PRIMARY KEY
);

CREATE SEQUENCE inventario_proceso.distribucion_secuencia_seq START 1;
CREATE TABLE inventario_proceso.distribucion
(
    secuencia        integer        DEFAULT NEXTVAL('inventario_proceso.distribucion_secuencia_seq'::regclass) NOT NULL
        CONSTRAINT pk_distribucion
            PRIMARY KEY,
    cuenta           varchar(24),
    monto            numeric(12, 3) DEFAULT 0,
    fecha            date,
    transaccion      varchar(10)                                                                               NOT NULL,
    tipo_transaccion varchar(2),
    periodo          varchar(2),
    ano              varchar(4),
    creacion_usuario varchar(4),
    creacion_fecha   date           DEFAULT ('now'::text)::date,
    creacion_hora    varchar(8)     DEFAULT ('now'::text)::time(0) WITHOUT TIME ZONE
);



INSERT INTO inventario_proceso.items (item, descripcion, codigo_rotacion, unidad_medida, costo_promedio, costo_estandar,
                                      ultimo_costo, existencia, transito)
SELECT item,
       descripcion,
       codigo_rotacion,
       unidad_medida,
       costo_promedio,
       costo_estandar,
       ultimo_costo,
       existencia,
       transito
FROM control_inventarios.items
WHERE LEFT(item, 1) IN ('2', '4', 'M');

SELECT *
FROM inventario_proceso.items;

INSERT INTO inventario_proceso.bodegas (bodega, item, existencia, cuenta_inventarios, codigo_integracion,
                                        creacion_usuario, creacion_fecha, creacion_hora)
SELECT b.bodega,
       b.item,
       b.existencia,
       b.cuenta_inventarios,
       b.codigo_integracion,
       b.creacion_usuario,
       b.creacion_fecha,
       b.creacion_hora
FROM control_inventarios.bodegas b
WHERE LEFT(b.item, 1) IN ('2', '4', 'M');

SELECT *
FROM inventario_proceso.bodegas;

-- Insert for ubicaciones
INSERT INTO inventario_proceso.ubicaciones (bodega, ubicacion, item, existencia, creacion_usuario, creacion_fecha,
                                            creacion_hora)
SELECT u.bodega, u.ubicacion, u.item, u.existencia, u.creacion_usuario, u.creacion_fecha, u.creacion_hora
FROM control_inventarios.ubicaciones u
WHERE LEFT(u.item, 1) IN ('2', '4', 'M');

SELECT *
FROM inventario_proceso.ubicaciones;

-- Insert for costos
INSERT INTO inventario_proceso.costos (item, tipo_costo, mantenimiento_materia_prima_dolar, mantenimiento_materia_prima,
                                       mantenimiento_mano_obra, mantenimiento_gastos_fabricacion, nivel_materia_prima,
                                       nivel_mano_obra, nivel_gastos_fabricacion, acumulacion_materia_prima,
                                       acumulacion_mano_obra, acumulacion_gastos_fabricacion)
SELECT c.item,
       c.tipo_costo,
       c.mantenimiento_materia_prima_dolar,
       c.mantenimiento_materia_prima,
       c.mantenimiento_mano_obra,
       c.mantenimiento_gastos_fabricacion,
       c.nivel_materia_prima,
       c.nivel_mano_obra,
       c.nivel_gastos_fabricacion,
       c.acumulacion_materia_prima,
       c.acumulacion_mano_obra,
       c.acumulacion_gastos_fabricacion
FROM costos.costos c
WHERE LEFT(c.item, 1) IN ('2', '4', 'M');


SELECT *
FROM inventario_proceso.costos