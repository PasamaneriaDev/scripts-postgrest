-- drop table control_inventarios.item_seccion

CREATE TABLE control_inventarios.item_seccion
(
    codigo  character varying(1) NOT NULL
        CONSTRAINT item_seccion_pkey PRIMARY KEY,
    seccion character varying(50) NOT NULL
);

COMMENT ON TABLE control_inventarios.item_seccion IS 'El primer digito del item indica la seccion a la que pertenece.';

INSERT INTO control_inventarios.item_seccion (codigo, seccion) VALUES
('1', 'CONFECCIONES'),
('2', 'TELARES'),
('3', 'TRENZADORAS'),
('4', 'HILANDERIA'),
('5', 'MEDIAS'),
('6', 'ENCAJES'),
('7', 'MALLAS'),
('8', 'CONSIGNACION'),
('9', 'HILOS DE SEDA'),
('B', 'HILOS DE COSER'),
('M', 'FUNDAS ALMACENES'),
('W', 'ARTICULOS PROMOCIONALES'),
('Z', 'DESPERDICIO')
;
