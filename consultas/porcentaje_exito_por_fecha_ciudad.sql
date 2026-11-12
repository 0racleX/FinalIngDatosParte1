-- Porcentaje de entregas exitosas por fecha y ciudad.
-- El denominador incluye todos los estados; se usa DOUBLE para evitar la division entera.
SELECT
    fecha,
    ciudad,
    CAST(
        ROUND(
            100.0 * CAST(SUM(CASE WHEN estado = 'entregado' THEN 1 ELSE 0 END) AS DOUBLE)
                  / CAST(COUNT(*) AS DOUBLE),
            2
        ) AS DECIMAL(5, 2)
    ) AS porcentaje_exito
FROM entregas
WHERE fecha BETWEEN '2026-10-01' AND '2026-10-03'
GROUP BY fecha, ciudad
ORDER BY fecha ASC, ciudad ASC;
