-- Punto 10: consultas complejas
USE hoteles;

-- ---------------------------------------------------------------------
-- C2. Reservas e ingresos por zona y trimestre (6 tablas)
-- Para 2025: cantidad de reservas, noches vendidas e ingresos por país,
-- provincia y trimestre. Solo cuentan las confirmadas y finalizadas.
-- Usa: JOIN de 6 tablas, funciones de fecha, GROUP BY, agregación.
-- Candidata a optimizar (punto 18): YEAR() sobre la columna impide usar
-- el índice de fecha; se puede reescribir como un rango.
-- ---------------------------------------------------------------------
SELECT pa.nombre AS pais, pr.nombre AS provincia,
       QUARTER(r.fecha_inicio) AS trimestre,
       COUNT(*) AS reservas,
       SUM(DATEDIFF(r.fecha_fin, r.fecha_inicio)) AS noches,
       SUM(DATEDIFF(r.fecha_fin, r.fecha_inicio) * r.tarifa_por_noche) AS ingresos
  FROM reservas r
  JOIN habitaciones h ON h.id  = r.habitacion_id
  JOIN hoteles ho     ON ho.id = h.hotel_id
  JOIN ciudades ci    ON ci.id = ho.ciudad_id
  JOIN provincias pr  ON pr.id = ci.provincia_id
  JOIN paises pa      ON pa.id = pr.pais_id
 WHERE r.estado IN ('confirmada', 'finalizada')
   AND YEAR(r.fecha_inicio) = 2025
 GROUP BY pa.nombre, pr.nombre, QUARTER(r.fecha_inicio)
 ORDER BY ingresos DESC
 LIMIT 20;