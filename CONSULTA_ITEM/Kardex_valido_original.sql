-- DROP FUNCTION control_inventarios.items_kardex_valido(varchar, date, date, _varchar);

CREATE OR REPLACE FUNCTION control_inventarios.items_kardex_valido(p_item character varying, p_fecha_inicial date, p_fecha_final date, p_bodega character varying[])
 RETURNS TABLE(documento character varying, movimiento character varying, referencia character varying, cantidad numeric, costo numeric, bodini character varying, ubicini character varying, bodfin character varying, ubicfin character varying, fecha date, cantidad_recibida numeric, fecha_recepcion date, codigo_proveedor character varying, nombre_proveedor character varying, creacion_usuario character varying, usuario_nombre character varying, creacion_hora character varying, periodo character varying, secuencia1 numeric)
 LANGUAGE plpgsql
AS $function$--LWO En el parámetro p_bodega debe venir con el siguiente formato '{225,001}'

DECLARE
    registro                RECORD;
    --p_bodega VARCHAR[]:= '{225,001}';
    wCantidad               NUMERIC := 0;
    wDocumento              VARCHAR := '';
    wCli_Prov               VARCHAR := '';
    wNombrescli             VARCHAR := '';
    wBodIni                 VARCHAR := '';
    wUbicIni                VARCHAR := '';
    wBodFin                 VARCHAR := '';
    wUbicFin                VARCHAR := '';
    WSecuencia              NUMERIC := 0;
    wNumeroSecuencia        NUMERIC := 0;
    WActualizaTransferencia BOOLEAN := FALSE;
    wPeriodo                VARCHAR := '';
    wLongitud               INTEGER := 0;

BEGIN

    Wlongitud = COALESCE(ARRAY_LENGTH(p_bodega, 1), 0);

    DROP TABLE IF EXISTS AuxKardex;
    CREATE TEMP TABLE AuxKardex
    (
        documento         varchar(10),
        movimiento        varchar(15),
        referencia        varchar(60),
        cantidad          numeric(10, 3),
        costo             numeric(15, 5),
        bodini            varchar(3),
        ubicini           varchar(4),
        bodfin            varchar(3),
        ubicfin           varchar(4),
        fecha             date,
        cantidad_recibida numeric(10, 3),
        fecha_recepcion   date,
        codigo_proveedor  varchar(13),
        nombre_proveedor  varchar(60),
        creacion_usuario  varchar(4),
        usuario_nombre    varchar(50),
        creacion_hora     varchar(20),
        periodo           varchar(6),
        secuencial        numeric(5)
    );

    DROP TABLE IF EXISTS AuxUnicos;
    CREATE TEMP TABLE AuxUnicos
    AS
        (SELECT DISTINCT transaccion
         FROM control_inventarios.transacciones t
         WHERE t.fecha BETWEEN p_fecha_inicial AND p_fecha_final
           AND t.item = p_item
           AND ((Wlongitud > 0 AND t.bodega = ANY (p_bodega)) OR (1 = 1 AND Wlongitud = 0))
           AND t.tipo_movimiento IN ('REUB CANT-', 'REUB CANT-', 'TRANSFER+', 'TRANSFER-'));

    wSecuencia = 0;
    FOR registro IN (SELECT t.*,
                            (SELECT nombres FROM sistema.usuarios WHERE codigo = t.creacion_usuario) AS usuario_nombres
                     FROM control_inventarios.transacciones t
                     WHERE t.item = p_item
                       AND t.fecha BETWEEN p_fecha_inicial AND p_fecha_final
                       AND NOT t.tipo_movimiento IN ('APER ORDE', 'BORR ORDE', 'CERR ORDE', 'MODI ORDE', 'REAP ORDE')
                     --AND t.bodega = ANY (p_bodega)
                     ORDER BY t.secuencia)
        LOOP

            wDocumento = registro.transaccion::varchar;
            wCantidad = registro.cantidad::numeric;
            wBodIni = registro.bodega::varchar;
            wUbicIni = registro.ubicacion::varchar;
            wPeriodo = registro.periodo::varchar;
            wBodFin = '';
            wUbicFin = '';
            wCli_Prov = '';
            wNombrescli = '';

            wSecuencia = wSecuencia + 1;

            IF registro.tipo_movimiento::VARCHAR IN ('VTAS ALM', 'DEVO ALM') AND
               registro.bodega::VARCHAR = ANY (p_bodega) THEN
                wDocumento = registro.documento::varchar;

                SELECT f.cedula_ruc, c.apellidos || ' ' || c.nombres AS nombres
                INTO wCli_Prov, wNombrescli
                FROM puntos_venta.facturas_cabecera f
                         INNER JOIN puntos_venta.clientes c ON f.cedula_ruc = c.cedula_ruc
                WHERE f.referencia = registro.documento::varchar;

            ELSIF registro.tipo_movimiento::VARCHAR IN ('VTAS MAY', 'DEVO MAY') AND
                  registro.bodega::VARCHAR = ANY (p_bodega) THEN
                wDocumento = registro.documento::varchar;

                SELECT f.cliente, c.nombre AS nombres
                INTO wCli_Prov, wNombrescli
                FROM cuentas_cobrar.facturas_cabecera f
                         INNER JOIN cuentas_cobrar.clientes c ON f.cliente = c.codigo
                WHERE f.referencia = registro.documento::varchar;

            ELSIF registro.tipo_movimiento::VARCHAR IN ('COMP EXT', 'DEVO EXT') AND
                  registro.bodega::VARCHAR = ANY (p_bodega) THEN
                SELECT SUBSTRING(t.referencia, 25, 6) AS codigo, p.nombre AS nombres
                INTO wCli_Prov, wNombrescli
                FROM control_inventarios.transacciones t
                         INNER JOIN cuentas_pagar.proveedores p ON SUBSTRING(t.referencia, 25, 6) = p.codigo
                WHERE t.transaccion = registro.transaccion::varchar;

            ELSIF registro.tipo_movimiento::VARCHAR IN ('REUB CANT-', 'TRANSFER-') THEN
                IF (SELECT transaccion FROM AuxUnicos WHERE transaccion = registro.transaccion::varchar) <> '' THEN

                    wCantidad = registro.cantidad::numeric * -1;
                    wBodIni = registro.bodega::varchar;
                    wUbicIni = registro.ubicacion::varchar;

                    wBodFin = '';
                    wUbicFin = '';
                    WActualizaTransferencia = TRUE;

                ELSE
                    wCantidad = 0;
                    wBodIni = '';
                    wUbicIni = '';
                    wBodFin = '';
                    wUbicFin = '';
                    WActualizaTransferencia = FALSE;
                END IF;

            ELSIF registro.tipo_movimiento::VARCHAR IN ('REUB CANT+', 'TRANSFER+') THEN
                IF WActualizaTransferencia = TRUE THEN
                    wBodIni = '';
                    wUbicIni = '';
                    wBodFin = registro.bodega::varchar;
                    wUbicFin = registro.ubicacion::varchar;
                ELSE
                    wCantidad = 0;
                    wBodIni = '';
                    wUbicIni = '';
                    wBodFin = '';
                    wUbicFin = '';

                END IF;
            ELSEIF NOT registro.bodega::VARCHAR = ANY (p_bodega) THEN
                wCantidad = 0;
                wBodIni = '';
                wUbicIni = '';
                wBodFin = '';
                wUbicFin = '';
            END IF;

            IF wBodIni <> '' THEN
                INSERT INTO AuxKardex (documento, movimiento, referencia, cantidad, costo, bodini, ubicini, bodfin,
                                       ubicfin,
                                       fecha, cantidad_recibida, fecha_recepcion, codigo_proveedor,
                                       nombre_proveedor, creacion_usuario, usuario_nombre, creacion_hora, periodo,
                                       secuencial)
                VALUES (wDocumento, registro.tipo_movimiento::varchar, registro.referencia::varchar, wCantidad,
                        registro.costo::numeric,
                        wBodIni, wUbicIni, wBodFin, wUbicFin,
                        registro.fecha::date, 0, NULL, wCli_Prov,
                        wNombrescli, registro.creacion_usuario::varchar, registro.usuario_nombres::varchar,
                        registro.creacion_hora::varchar, wPeriodo, wsecuencia);
                wNumeroSecuencia = wsecuencia;
            END IF;

            IF wBodFin <> '' AND WActualizaTransferencia = TRUE THEN
                UPDATE AuxKardex
                SET bodfin            = wBodFin,
                    ubicfin           = wUbicFin,
                    cantidad_recibida = registro.cantidad_recibida::numeric,
                    fecha_recepcion   = registro.fecha_recepcion::date
                WHERE secuencial = wNumeroSecuencia;

                WActualizaTransferencia = FALSE;
            END IF;
        END LOOP;

    DROP TABLE IF EXISTS AuxUnicos;
    RETURN QUERY SELECT * FROM AuxKardex;
    DROP TABLE IF EXISTS AuxKardex;
END;
$function$
;
