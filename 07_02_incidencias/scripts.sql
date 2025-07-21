select *
from sistema.usuarios_activos
where computador = 'ANALISTA3'


SELECT *
FROM puntos_venta.incidencias;

SELECT *
FROM puntos_venta.incidencias_estados AS bf;

SELECT pi.numero_incidencia,
       pie.fecha::date                                                                            AS creacion_fecha,
       cc.subcentro,
       pi.grupo,
       pi.observacion,
       pi.estado,
       puntos_venta.incidencias_estados_obtener_fecha(pi.numero_incidencia,
                                                      'AUTORIZADO')::date                         AS autorizacion_fecha,
       puntos_venta.incidencias_estados_obtener_fecha(pi.numero_incidencia,
                                                      'COMPLETO')::date                           AS finalizacion_fecha,
       puntos_venta.incidencias_estados_obtener_fecha(pi.numero_incidencia,
                                                      'NO AUTORIZADO')::date                      AS noautorizado_fecha,
       puntos_venta.incidencias_estados_obtener_observacion(pi.numero_incidencia,
                                                            'NO AUTORIZADO')                      AS observacion_noautorizado,
       pi.ejecucion_usuario,
       puntos_venta.incidencias_estados_obtener_fecha(pi.numero_incidencia, 'EN EJECUCION')::date AS ejecucion_fecha,
       puntos_venta.incidencias_estados_obtener_fecha(pi.numero_incidencia, 'NO EJECUTADO')::date AS noejecutado_fecha,
       puntos_venta.incidencias_estados_obtener_observacion(pi.numero_incidencia,
                                                            'NO EJECUTADO')                       AS observacion_noejecutado,
       uej.nombres                                                                                AS ejecucion_nombres
FROM puntos_venta.incidencias pi
         JOIN puntos_venta.incidencias_estados pie
              ON pi.numero_incidencia = pie.numero_incidencia AND pie.estado = 'EN TRAMITE'
         JOIN activos_fijos.centros_costos cc ON pi.centro_costo = cc.codigo
         LEFT JOIN sistema.usuarios uej ON pi.ejecucion_usuario = uej.codigo
WHERE (pi.numero_incidencia = $1 OR $1 = -1)
  AND (pi.centro_costo = $2 OR $2 = '')
  AND (pi.estado = $3 OR $3 = '')
  AND ($4 = '' OR $5 = '' OR pie.fecha::date BETWEEN $4::date AND $5::date)
  AND (pi.grupo = $6 OR $6 = '')
  AND (pi.ejecucion_usuario = $7 OR $7 = '')
ORDER BY pi.creacion_fecha DESC



SELECT *
FROM sistema.usuarios
WHERE codigo = '9665'


SELECT pi.centro_costo
FROM puntos_venta.incidencias pi
         JOIN activos_fijos.centros_costos cc ON pi.centro_costo = cc.codigo
WHERE numero_incidencia = 27;


SELECT *
FROM activos_fijos.centros_costos cc
WHERE codigo = 'A09'


SELECT fecha::date, estado, observacion
FROM puntos_venta.incidencias_estados;



SELECT *
FROM sistema.email_masivo_cabecera
WHERE numero_email IS NOT NULL
ORDER BY numero_email DESC;

lorena.washima@pasa.ec


SELECT recibe_incidencias, email
FROM sistema.usuarios u
WHERE codigo = '9665'
  AND email != ALL (STRING_TO_ARRAY(
        (SELECT p.alfa
         FROM sistema.parametros p
         WHERE p.modulo_id = 'SISTEMA'
           AND p.codigo = 'CORREO_AUTO_INCIDEN_REQUERIM')
    , ','))


select 'lorena.washima@pasa.ec' != ALL (STRING_TO_ARRAY(
        'janeth.rodas@pasa.ec,lourdes.rugel@pasa.ec,lorena.washima@pasa.ec'
    , ','))


select *
from puntos_venta.correos_enviados_encargados_incidencias








  select *
  from control_inventarios.ciclo_conteo
  order by fecha desc

  INSERT INTO control_inventarios.ciclo_conteo (fecha, ciclos_conteo, no_se_cuenta, referencia, migracion) VALUES ('2024-12-31', '53.153.353.553', null, null, 'NO');



select * from GENERATE_SERIES('2025-01-01', '2025-01-31', '1 day'::interval)


DO
$$
DECLARE
    fecha DATE;
BEGIN
    FOR fecha IN SELECT GENERATE_SERIES('2025-01-01'::date, '2025-01-31'::date, '1 day'::interval) LOOP
        INSERT INTO control_inventarios.ciclo_conteo (fecha, ciclos_conteo, no_se_cuenta, referencia, migracion)
        VALUES (fecha, '53.153.353.553', null, null, 'NO');
    END LOOP;
END
$$;


SELECT c.fecha,
       REGEXP_SPLIT_TO_TABLE(COALESCE(c.no_se_cuenta, ''), ',') AS bodega_origen --split no_se_cuenta
FROM control_inventarios.ciclo_conteo c
WHERE c.fecha BETWEEN '2025-01-01'::date AND '2025-01-31'::date


select *
FROM control_inventarios.ciclo_conteo c
order by fecha desc



select bodega, item, existencia, corte_conteo, conteo_grabado, fecha_conteo
from control_inventarios.bodegas
where not auditoria_conteo
and fecha_conteo > '2024-01-01';