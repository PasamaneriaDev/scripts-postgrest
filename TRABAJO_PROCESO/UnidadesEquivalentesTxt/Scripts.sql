SELECT *
FROM trabajo_proceso.reporte_unidades_equivalentes_txt('[{"item":"1MX400M6522101","cantidad":1.0},{"item":"1MX400M6522101","cantidad":3.0},{"item":"1MX400M6522101","cantidad":5.0},{"item":"1MX400M6522101","cantidad":6.0},{"item":"1MX400M6522101","cantidad":7.0},{"item":"1MX400M6522101","cantidad":12.0},{"item":"1MX400M6522101","cantidad":1.0}]')


select ROUND(EXTRACT(EPOCH FROM (now() - (now() - interval '1'))) / 60, 2)