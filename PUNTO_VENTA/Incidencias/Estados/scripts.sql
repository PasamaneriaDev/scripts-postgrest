select *
from sistema.usuarios_activos
where computador = 'ANALISTA3';

select *
from sistema.usuarios
where codigo = '9665';


select usuario, nombres
from puntos_venta.incidencias_consultar_usuarios_ejecucion()



select *
from puntos_venta.incidencias


    SELECT recibe_incidencias
    FROM sistema.usuarios
    WHERE codigo = '9565';



    SELECT subcentro, correo
    FROM activos_fijos.centros_costos
    WHERE codigo = 'V43'


select *
from sistema.email_masivo_cabecera
where numero_email is not NULL
order by numero_email desc


select *
from sistema.email_masivo_detalle
where numero_email = 2894




SELECT pi.numero_incidencia, pi.creacion_fecha::date as creacion_fecha, cc.subcentro,
  pi.grupo, pi.observacion, pi.estado, pi.autorizacion_fecha::date as autorizacion_fecha, pi.finalizacion_fecha::date as finalizacion_fecha,
  pi.noautorizado_fecha::date as noautorizado_fecha, pi.observacion_noautorizado, pi.ejecucion_usuario, pi.ejecucion_fecha::date,
  pi.noejecutado_usuario, pi.noejecutado_fecha::date, pi.observacion_noejecutado
FROM puntos_venta.incidencias pi
JOIN activos_fijos.centros_costos cc on pi.centro_costo = cc.codigo

WHERE (pi.numero_incidencia = $1 or $1 = -1)
  AND (pi.centro_costo = $2 or $2 = '' )
  AND (pi.estado = $3 or $3 = '' )
  AND ($4 = '' or $5 = '' or pi.creacion_fecha::date between $4::date AND $5::date)
  AND (pi.grupo = $6 or $6 = '')
  AND (pi.ejecucion_usuario = $7 or $7 = '')
ORDER BY pi.creacion_fecha desc



INSERT INTO puntos_venta.incidencias ( centro_costo, grupo, observacion, estado, creacion_usuario,
                                      creacion_fecha, autorizacion_usuario, autorizacion_fecha, finalizacion_usuario,
                                      finalizacion_fecha, noautorizado_usuario, noautorizado_fecha,
                                      observacion_noautorizado, ejecucion_usuario, ejecucion_fecha, noejecutado_usuario,
                                      noejecutado_fecha, observacion_noejecutado)
VALUES ( 'V74', 'MOBILIARIO', 'INCIDENCIA NUEVA 21', 'NO EJECUTADO', 'CAJA', '2024-10-31 08:15:29.830303', '9665',
        '2024-11-25 15:26:23.744049', '', NULL, NULL, NULL, NULL, '9665', NULL, NULL, NULL,
        NULL);


SELECT recibe_incidencias
FROM sistema.usuarios
WHERE email != ALL (string_to_array('janeth.rodas@pasa.ec,lourdes.rugel@pasa.ec', ','));

SELECT alfa
FROM sistema.parametros
WHERE modulo_id = 'SISTEMA'
  AND codigo = 'CORREO_AUTO_INCIDEN_REQUERIM';

SELECT u.codigo, u.nombres::text as nombres, email
        FROM sistema.usuarios u
        WHERE u.recibe_incidencias;

SELECT *, recibe_incidencias
        FROM sistema.usuarios u
        WHERE codigo='9665';

select numero_incidencia
from puntos_venta.incidencias
where estado = 'AUTORIZADO';

SELECT *
FROM sistema.email_masivo_cabecera
WHERE numero_email IS NOT NULL
ORDER BY numero_email DESC;


select current_timestamp::time

select *
from puntos_venta.incidencias