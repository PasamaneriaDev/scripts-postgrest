SELECT m.nombre, m.grupo, m.exenombre, m.path, m.icono
FROM sistema.modulo m
         INNER JOIN LATERAL (SELECT *
                             FROM sistema.accesos a
                             WHERE m.nombre = a.modulo
                             LIMIT 1) AS a ON TRUE
WHERE a.codigo = '8805';

ALTER TABLE sistema.modulo
    ADD COLUMN grupo VARCHAR(255) DEFAULT NULL;
ALTER TABLE sistema.modulo
    ADD COLUMN path_icono VARCHAR(255) DEFAULT NULL;

ALTER TABLE sistema.modulo
    ADD COLUMN path_linux       varchar(255) DEFAULT NULL,
    ADD COLUMN path_icono_linux varchar(255) DEFAULT NULL,
    ADD COLUMN path_mac         varchar(255) DEFAULT NULL,
    ADD COLUMN path_icono_mac   varchar(255) DEFAULT NULL;

ALTER TABLE sistema.modulo
    RENAME COLUMN path TO path_windows;
ALTER TABLE sistema.modulo
    RENAME COLUMN path_icono TO path_icono_windows;

SELECT grupo
FROM sistema.modulo m
WHERE grupo IS NOT NULL
group by grupo
ORDER BY grupo;

SELECT *
FROM sistema.modulo m
WHERE grupo IS NOT NULL
ORDER BY TITULO;


SELECT *
FROM sistema.modulo m
WHERE grupo = 'SISTEMAS'
ORDER BY TITULO;


SELECT string_agg(m.moduloid::text, ',') AS modulos
FROM sistema.modulo m
WHERE grupo = 'SISTEMAS'
group by m.grupo;



SELECT *
FROM sistema.usuarios_activos
WHERE computador = 'ANALISTA3';



SELECT *
FROM sistema.usuarios
WHERE codigo = '1666';

SELECT *
FROM sistema.usuarios
WHERE nombreS like '%RODAS%';

SELECT *
FROM sistema.accesos
WHERE codigo = '7991'


INSERT INTO sistema.modulo (titulo, nombre, exenombre, migracion)
VALUES ('Utilitarios', 'UTILITARIOS', NULL, 'NO');


SELECT m.nombre, m.grupo, m.exenombre, m.path, m.icono
FROM sistema.modulo m
         INNER JOIN LATERAL ( SELECT * FROM sistema.accesos a WHERE m.nombre = a.modulo LIMIT 1) AS a ON TRUE
WHERE a.codigo = '3191'

SELECT m.nombre,
       m.grupo,
       m.exenombre,
       m.titulo,
       m.path_icono_windows,
       m.path_icono_mac,
       m.path_icono_linux,
       m.path_windows,
       m.path_mac,
       m.path_linux
FROM sistema.modulo m
         INNER JOIN LATERAL (
    SELECT a.codigo
    FROM sistema.accesos a
    WHERE m.nombre = a.modulo
      AND a.codigo = '7991'
    LIMIT 1) AS a ON TRUE
WHERE m.grupo IS NOT NULL



SELECT moduloid, path_windows, path_icono_windows, path_mac, path_icono_mac, path_linux, path_icono_linux
FROM sistema.modulo m
WHERE grupo is not null
ORDER BY TITULO;

