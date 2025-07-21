-- DROP FUNCTION roles.distribucion_mano_obra_empleados(varchar, date);

CREATE OR REPLACE FUNCTION roles.distribucion_mano_obra_empleados(pperiodo character varying, pfecha_inicial date)
    RETURNS TABLE
            (
                codigo     character varying,
                nombres    character varying,
                fechaingre date,
                fechasalid date,
                seccion    character varying,
                seccprorra character varying,
                descripcio character varying,
                cargo      character varying,
                tipomobra  character varying,
                modalidad  character varying,
                porcentaje numeric,
                hnormal    numeric,
                hextras    numeric,
                codmobra   character varying,
                descodmob  character varying,
                periodo    character varying
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    RETURN QUERY
        SELECT t1.codigo,
               v.nombres::character varying,
               v.fecha_ingreso                                         AS fechaingre,
               v.fecha_salida                                          AS fechasalid,
               v.seccion                                               AS seccprorra,
               t3.centro_costo,
               c.descripcion                                           AS descripcio,
               t3.cargo,
               t3.tipo_mano_obra                                       AS tipomobra,
               t3.modalidad,
               ROUND(t3.porcentaje, 2)                                 AS porcentaje,
               ROUND(COALESCE(t2.horas_pagadas * t3.porcentaje, 0), 2) AS hnormal,
               COALESCE(t2.horas_extras * t3.porcentaje, 0)            AS hextras,
               t3.codigo_sistemas_metodo                               AS codmobra,
               cs.descripcion                                          AS descodmob,
               pperiodo                                                AS periodo
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
