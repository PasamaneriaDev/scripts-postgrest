-- DROP FUNCTION puntos_venta.reporte_reclamos(p_numero_reclamo integer);

CREATE OR REPLACE FUNCTION puntos_venta.reporte_reclamos(p_numero_reclamo integer)
    RETURNS TABLE
            (
                numero_reclamo           integer,
                centro_costo_descripcion character varying,
                centro_costo             character varying,
                nombre_cliente           character varying,
                fecha_reclamo            date,
                fecha_compra             date,
                problema_solucionado     boolean,
                solucion                 character varying,
                productos_lavado         character varying,
                metodo_lavado            character varying,
                metodo_secado            character varying,
                observaciones            character varying,
                numero_transferencia     character varying,
                creacion_usuario         character varying,
                creacion_fecha           timestamp WITHOUT TIME ZONE,
                item                     character varying,
                cantidad                 numeric,
                anio_trimestre           numeric,
                defecto                  character varying,
                observaciones_item       character varying,
                titulo                   text,
                recepcion_fecha          date,
                nombre_cac               character varying,
                revision_calidad_fecha   date,
                nombre_calidad           character varying
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    /***/
    -- REPORTE USADO EN: Reclamos Almacenes - Clientes -> CRM
    --                   Reclamos -> Punto de Venta
    /***/
    RETURN QUERY
        SELECT rc.numero_reclamo,
               (SELECT cc.subcentro
                FROM activos_fijos.centros_costos cc
                WHERE cc.codigo = rc.centro_costo)                      AS centro_costo_descripcion,
               rc.centro_costo,
               rc.nombre_cliente,
               rc.fecha_reclamo,
               rc.fecha_compra,
               rc.problema_solucionado,
               rc.solucion,
               rc.productos_lavado,
               rc.metodo_lavado,
               rc.metodo_secado,
               rc.observaciones,
               rc.numero_transferencia,
               rc.creacion_usuario,
               rc.creacion_fecha,
               rd.item,
               rd.cantidad,
               rd.anio_trimestre,
               td.descripcion                                           AS defecto,
               rd.observaciones                                         AS observaciones_item,
               'RECEPCIÓN DE RECLAMOS Y DEVOLUCIONES DE CLIENTES'::text AS titulo,
               DATE(rc.recepcion_fecha)                                 AS recepcion_fecha,
               (SELECT df.nombres
                FROM sistema.usuarios df
                WHERE df.codigo = rc.recepcion_usuario)                 AS nombre_cac,
               DATE(rc.revision_calidad_fecha)                          AS revision_calidad_fecha,
               (SELECT df.nombres
                FROM sistema.usuarios df
                WHERE df.codigo = rc.revision_calidad_usuario)          AS nombre_calidad
        FROM puntos_venta.reclamos_cabecera rc
                 JOIN puntos_venta.reclamos_detalle rd
                      ON rc.numero_reclamo = rd.numero_reclamo
                 JOIN puntos_venta.tipos_defecto td
                      ON rd.codigo_defecto = td.codigo_defecto
        WHERE rc.numero_reclamo = p_numero_reclamo;
END;
$function$
;
