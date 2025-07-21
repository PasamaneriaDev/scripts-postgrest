CREATE OR REPLACE FUNCTION sistema.pedido_numero_obtener(p_bodega character varying)
    RETURNS TABLE
            (
                numero integer
            )
    LANGUAGE plpgsql
AS
$$
DECLARE
    w_numero INTEGER;
BEGIN
    -- Usa el numero actual e incrementa para el siguiente
    UPDATE sistema.parametros_almacenes
    SET numero_pedido = numero_pedido + 1
    WHERE bodega = p_bodega
    RETURNING numero_pedido::INTEGER - 1 INTO w_numero;

    IF (SELECT p_interface_activo FROM sistema.interface_activo_fnc()) = TRUE THEN
        INSERT INTO sistema.interface
        (usuarios, modulo,
         sql,
         proceso, directorio, tabla,
         buscar)
        SELECT '',
               'ORDENES_VENTA',
               'REPLACE numpedido WITH numpedido + 1',
               'UPDATE',
               'V:\SBTPRO\',
               'SYSCARG',
               '=SEEK([' || RPAD(p_bodega, 3, ' ') || '], [syscarg], [loctid])';
    END IF;

    RETURN QUERY
        SELECT w_numero;

END;
$$;


