SELECT periodo,
       SUM(CASE WHEN ih.bodega = '999' THEN ih.existencia ELSE 0 END) AS "999",
       SUM(CASE WHEN ih.bodega = '100' THEN ih.existencia ELSE 0 END) AS "100"
FROM control_inventarios.items_historico ih
WHERE ih.item = '1UZ30346942051'
  AND ih.periodo BETWEEN '202407' AND '202412'
  AND ih.bodega IN ('999', '100')
  AND ih.nivel = 'ILOC'
GROUP BY periodo

SELECT *
FROM control_inventarios.items_historico ih
WHERE ih.item = '10150006000133'
  AND ih.periodo BETWEEN '202407' AND '202412'
  AND ih.bodega IN ('999', '100')
  AND ih.nivel = 'ILOC' WHERE i.item = '10150006000133'


SELECT primera
FROM control_inventarios.bodegas
WHERE item = '10150006000133'


/***********************************************************************************************/
/***********************************************************************************************/
/***********************************************************************************************/
/***********************************************************************************************/
/***********************************************************************************************/


WITH cte AS (SELECT 'PS'                         AS MODULO,
                    fd.item,
                    fd.periodo,
                    fd.descuento,
                    fd.valor_descuento_adicional AS desc,
                    fd.precio,
                    fd.cantidad,
                    fd.total_precio
             FROM puntos_venta.facturas_detalle fd
             WHERE fd.item = '10150006000133'
               AND fd.periodo BETWEEN '202407' AND '202412'
             UNION ALL
             SELECT 'AR'                AS MODULO,
                    fd.item,
                    fd.periodo,
                    fd.descuento,
                    fd.descuento_etatex AS desc,
                    fd.precio,
                    fd.cantidad,
                    fd.total_precio
             FROM cuentas_cobrar.facturas_detalle fd
             WHERE fd.item = '10150006000133'
               AND fd.periodo BETWEEN '202407' AND '202412')
SELECT cte.MODULO,
       i.item,
       i.descripcion,
       i.codigo_rotacion,
       cte.periodo,
       cte.descuento,
       cte.desc,
       cte.precio,
       cte.cantidad,
       cte.total_precio
FROM control_inventarios.items i
         JOIN cte ON i.item = cte.item


SELECT *
FROM puntos_venta.reporte_ventas_ps_my_descuentos('202407', '202412')

select *
from puntos_venta.reporte_ventas_ps_my_unidades('202307', '202312')
/**********************************************************************/
-- SELECT RUTAS
-- IF SEEK(wruta) THEN
--    DO WHILE wruta=ruta AND !EOF()
--       wcentro=centro
--       VMinutosXU=0
--       IF Unidades = "UNO" THEN
--          VMinutosXU = minutos
--       ELSE
--          IF Unidades = "CIEN" THEN
--             vMinutosXU = minutos/100
--          ELSE
--             IF Unidades = "MIL" THEN
--                vMinutosXU = minutos/1000
--             ENDIF
--          ENDIF
--       ENDIF
--       SELECT CENTROS
--       IF SEEK(wcentro) THEN
--          IF departamen="11" AND RIGHT(ALLTRIM(rutas.operacion),1)<>'1'    && ALLTRIM(descripcio)<>"Modular" THEN			&& el modular suma todos los tiempos de costura
--             wtiemcostIN= wtiemcostIN + vMinutosXU
--          ENDIF
--       ENDIF
--       SELECT RUTAS
--       SKIP
--    ENDDO
-- ENDIF

-- select r.unidades, r.minutos, r.operacion, c.departamento, c.descripcion

SELECT SUM(CASE
               WHEN c.departamento = '11' AND RIGHT(TRIM(r.operacion), 1) <> '1'
                   THEN CASE
                            WHEN r.unidades = 'UNO' THEN r.minutos
                            WHEN r.unidades = 'CIEN' THEN r.minutos / 100
                            WHEN r.unidades = 'MIL' THEN r.minutos / 1000
                   END
               ELSE 0 END) AS aas
FROM rutas.rutas r
         JOIN rutas.centros c ON c.codigo = r.centro
WHERE r.ruta = '1NU72-P3 TQ'

--WHERE departamen = '11' AND RIGHT(TRIM(rutas.operacion), 1) <> '1'

SELECT ruta
FROM control_inventarios.items
WHERE item = '1NU72086002173'

select
from control_inventarios.bodegas
where item = '10150006000203'
and bodega = '999'








  Stream.WriteLine(_
  "modulo" + ";" + _
  "item" + ";" + _
  "descripcion" + ";" + _
  "codigo_rotacion" + ";" + _
  "periodo" + ";" + _
  "descuento" + ";" + _
  "descuento_adic" + ";" + _
  "precio" + ";" + _
  "cantidad" + ";" + _
  "total_precio")
