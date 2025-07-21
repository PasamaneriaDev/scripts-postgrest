CREATE TABLE inventario_proceso.toma_producto_proceso_preliminar
(
    id_public       serial PRIMARY KEY,
    computador      varchar(15) NOT NULL,
    usuario         varchar(15) NOT NULL,
    documento       varchar(10) NOT NULL,
    item            varchar(15) NOT NULL,
    costo           numeric(11, 5) DEFAULT 0,
    costo_nuevo     numeric(11, 5) DEFAULT 0,
    orden           varchar(15),
    cantidad        numeric(12, 3) DEFAULT 0,
    conos           numeric(4)     DEFAULT 0,
    tara            numeric(12, 3) DEFAULT 0,
    cajon           numeric(12, 3) DEFAULT 0,
    constante       numeric(12, 3) DEFAULT 0,
    muestra         varchar(255),
    cantidad_ajuste numeric(12, 3) DEFAULT 0,
    bodega          varchar(3)  NOT NULL,
    ubicacion       varchar(4),
    fecha           date           DEFAULT CURRENT_DATE,
    hora            time           DEFAULT CURRENT_TIME
);