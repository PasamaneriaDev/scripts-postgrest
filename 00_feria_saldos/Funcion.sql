-- DROP FUNCTION roles.cliente_tiene_cupo_credito(pcedula varchar, OUT cupo_saldo numeric, OUT transaccion_id bigint);
CREATE OR REPLACE FUNCTION roles.cliente_tiene_cupo_credito_fs(pcedula varchar,
                                                               OUT cupo_saldo numeric,
                                                               OUT transaccion_id bigint)
    RETURNS record
    LANGUAGE plpgsql
AS
$function$
DECLARE
    lv_codigo_usuario varchar;
BEGIN
    /**/
    -- Funcion para determinar si el cliente que compra en la feria de saldos tiene cupo de credito
    -- Aplica solo a los clientes que son personal de la empresa
    /**/

    -- Busca en la tabla de personal
    SELECT codigo
    INTO lv_codigo_usuario
    FROM roles.personal
    WHERE REPLACE(cedula_ruc, '-', '') = pcedula;

    IF FOUND THEN
        -- Si el cliente es personal de la empresa, busca en la tabla de cupos
        SELECT transaccionid,
               COALESCE(COALESCE(cupo_original, 0) - COALESCE(cupo_usado, 0), 0) AS cupo_saldo
        INTO transaccion_id, cupo_saldo
        FROM roles.cupos_feria_saldos
        WHERE codigo_usuario = lv_codigo_usuario
          AND procesado = FALSE
          AND periodo = TO_CHAR(CURRENT_DATE, 'YYYYMM');

    ELSE
        -- Si el cliente no es personal de la empresa
        cupo_saldo = 0;
        transaccion_id = NULL;
    END IF;
END
$function$
;


SELECT cupo_saldo, transaccion_id
FROM roles.cliente_tiene_cupo_credito_fs('0107177016');


CREATE OR REPLACE FUNCTION roles.actualizar_cupo_credito(ptransaccionid bigint, pvalor_usado numeric, OUT respuesta text)
    RETURNS text
    LANGUAGE plpgsql
AS
$function$
DECLARE
    v_cupo_original numeric;
    v_cupo_usado    numeric;
BEGIN

    SELECT cupo_original, cupo_usado
    INTO v_cupo_original, v_cupo_usado
    FROM roles.cupos_feria_saldos
    WHERE transaccionid = ptransaccionid;

    IF COALESCE(v_cupo_original, 0) >= (COALESCE(v_cupo_usado, 0) + COALESCE(pvalor_usado, 0)) THEN
        UPDATE roles.cupos_feria_saldos
        SET cupo_usado = cupo_usado + COALESCE(pvalor_usado, 0)
        WHERE transaccionid = ptransaccionid;

        respuesta = 'OK';
    ELSE
        RAISE EXCEPTION 'ERROR: El cupo usado sobrepasa el saldo disponible.';
    END IF;
END ;
$function$
;


SELECT *
FROM roles.actualizar_cupo_credito(1, 1)
