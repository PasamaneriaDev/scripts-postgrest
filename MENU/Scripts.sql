  SELECT m.nombre, m.grupo,  m.path, m.icono
  FROM sistema.modulo m
  INNER JOIN sistema.accesos a ON m.nombre = a.grupo
  WHERE a.codigo = '3191'