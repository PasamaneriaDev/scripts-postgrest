-- drop view puntos_venta.reclamos_personal_destinatario;

CREATE OR REPLACE VIEW puntos_venta.reclamos_personal_destinatario AS
SELECT x.codigo, x.nombre_completo, x.centro_costo, x.email
FROM (SELECT SUBSTRING(p.codigo FROM 2)                                 AS codigo,
             p.apellido_paterno || ' ' || p.nombre1 || ' ' || p.nombre2 AS nombre_completo,
             u.email,
             p.centro_costo
      FROM roles.personal p
               JOIN sistema.usuarios u ON u.codigo = SUBSTRING(p.codigo FROM 2)
      WHERE p.centro_costo = 'V05'
        AND p.fecha_salida IS NULL
      UNION ALL
      SELECT SUBSTRING(p.codigo FROM 2)                                 AS codigo,
             p.apellido_paterno || ' ' || p.nombre1 || ' ' || p.nombre2 AS nombre_completo,
             u.email,
             p.centro_costo
      FROM roles.personal p
               JOIN sistema.usuarios u ON u.codigo = SUBSTRING(p.codigo FROM 2)
      WHERE u.codigo = '5022'
        AND p.fecha_salida IS NULL) AS x;


SELECT *
FROM puntos_venta.reclamos_personal_destinatario;


SELECT SUBSTRING('aaa' FROM 1)