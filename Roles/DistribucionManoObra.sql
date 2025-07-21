DROP FUNCTION roles.distribucion_mano_obra_empleados(varchar, date);

CREATE OR REPLACE FUNCTION roles.distribucion_mano_obra_empleados(pperiodo character varying, pfecha_inicial date)
    RETURNS TABLE
            (
                cargo        character varying,
                tipomobra    character varying,
                porcentaje   numeric,
                descripcio   character varying,
                seccprorra   character varying,
                modalidad    character varying,
                codigo       character varying,
                nombres      character varying,
                hnormal      numeric,
                fechaingre   date,
                fechasalid   date,
                hextras      numeric,
                descodmob    character varying,
                seccion      character varying,
                periodo      character varying,
                codmobra     character varying
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    RETURN QUERY
        SELECT t3.cargo,
               t3.tipo_mano_obra                                       AS tipomobra,
               ROUND(t3.porcentaje, 2)                                 AS porcentaje,
               c.descripcion                                           AS descripcio,
               t3.centro_costo,
               t3.modalidad,
               t1.codigo,
               v.nombres::character varying,
               ROUND(COALESCE(t2.horas_pagadas * t3.porcentaje, 0), 2) AS hnormal,
               v.fecha_ingreso                                         AS fechaingre,
               v.fecha_salida                                          AS fechasalid,
               COALESCE(t2.horas_extras * t3.porcentaje, 0)            AS hextras,
               cs.descripcion                                          AS descodmob,
               v.seccion                                               AS seccprorra,
               pperiodo                                                AS periodo,
               t3.codigo_sistemas_metodo                               AS codmobra
        FROM roles.aportes t1
                 JOIN roles.v_personal_nombres v ON t1.codigo = v.codigo --AND left(v.codigo, 1) = 'P'
                 JOIN roles.distribucion_mano_obra t3
                      ON t1.codigo = t3.codigo
                          AND t3.periodo = pperiodo
                          AND (t3.rol_aplica = '02'
                              OR (t3.rol_aplica = '49'
                                  AND NOT EXISTS (SELECT 1
                                                  FROM roles.distribucion_mano_obra t3_alt
                                                  WHERE t3_alt.codigo = t1.codigo
                                                    AND t3_alt.periodo = pperiodo
                                                    AND t3_alt.rol_aplica = '02')
                                   )
                             )
                 LEFT JOIN roles.horas_pagadas t2
                           ON t1.codigo = t2.codigo AND t2.fecha_inicial = pfecha_inicial
                 LEFT JOIN activos_fijos.centros_costos c
                           ON c.codigo = t3.centro_costo
                 LEFT JOIN roles.clasificacion_sistemas_metodos cs
                           ON cs.codigo_mano_obra = t3.codigo_sistemas_metodo
        WHERE t1.periodo = pperiodo
        ORDER BY t1.codigo;

END;
$function$
;


SELECT *
FROM roles.distribucion_mano_obra_empleados('202412', '2024-10-01');


