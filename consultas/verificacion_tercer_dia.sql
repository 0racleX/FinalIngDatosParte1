-- 1) Los seis registros del 2026-10-03 -> resultados/final/verificacion_tercer_dia.csv
SELECT
    fecha,
    id_envio,
    ciudad,
    transportadora,
    estado,
    duracion_minutos
FROM entregas
WHERE fecha = '2026-10-03'
ORDER BY id_envio ASC;

-- 2) Conteo por estado del 2026-10-03 -> resultados/final/conteo_estado_tercer_dia.csv
SELECT
    fecha,
    estado,
    COUNT(*) AS total_intentos
FROM entregas
WHERE fecha = '2026-10-03'
GROUP BY fecha, estado
ORDER BY fecha ASC, estado ASC;

-- 3) Total de registros de la tabla (esperado 18) -> resultados/final/total_registros.csv
SELECT
    COUNT(*) AS total_registros,
    COUNT(DISTINCT fecha) AS total_fechas,
    SUM(CASE WHEN fecha = '2026-10-03' THEN 1 ELSE 0 END) AS registros_tercer_dia
FROM entregas;
