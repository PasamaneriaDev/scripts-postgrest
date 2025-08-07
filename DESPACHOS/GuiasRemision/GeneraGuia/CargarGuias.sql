CREATE OR REPLACE FUNCTION cuentas_cobrar.guias_remision_cargar_pendientes(p_bod_entorno varchar, p_tipo_documento varchar)
    RETURNS table
            (
                tipo_documento varchar,
                fecha date,
                cliente varchar,
                nombre varchar,
                direccion varchar,
                referencia varchar,
                factura varchar,
                numero_autorizacion_factura varchar,
                numero_guia varchar
            )
    LANGUAGE plpgsql
AS
$function$
BEGIN
    RETURN QUERY
        SELECT g.tipo_documento,
               g.fecha,
               g.cliente,
               c.nombre,
               c.direccion,
               g.referencia,
               g.factura,
               g.numero_autorizacion_factura,
               g.numero_guia
        FROM cuentas_cobrar.guias_remision g
                 INNER JOIN cuentas_cobrar.clientes c ON g.cliente = c.codigo
        WHERE TRIM(COALESCE(g.impreso, '')) = ''
          AND (g.bodega = p_bod_entorno OR
               (p_bod_entorno = '001' AND g.bodega = '023'))
          AND g.tipo_documento = p_tipo_documento
        ORDER BY numero_guia;
END;
$function$
;
