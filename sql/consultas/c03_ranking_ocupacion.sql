-- Punto 10: consultas complejas
USE hoteles;

-- ---------------------------------------------------------------------
-- C3. Ranking de hoteles por ocupación en 2025 (4 tablas)
-- Ocupación = noches ocupadas / noches disponibles (habitaciones x 365).
-- Una reserva que cruza el cambio de año solo suma las noches de 2025.
-- Usa: CTE (WITH), función de ventana RANK(), LEAST/GREATEST, agregación.
-- ---------------------------------------------------------------------
WITH ocupadas AS (
  SELECT h.hotel_id,
         SUM(DATEDIFF(LEAST(r.fecha_fin, '2026-01-01'),
                      GREATEST(r.fecha_inicio, '2025-01-01'))) AS noches_ocupadas
    FROM reservas r
    JOIN habitaciones h ON h.id = r.habitacion_id
   WHERE r.estado IN ('confirmada', 'finalizada')
     AND r.fecha_inicio < '2026-01-01'
     AND r.fecha_fin    > '2025-01-01'
   GROUP BY h.hotel_id
),
capacidad AS (
  SELECT hotel_id, COUNT(*) * 365 AS noches_disponibles
    FROM habitaciones
   WHERE activa
   GROUP BY hotel_id
)
SELECT RANK() OVER (ORDER BY o.noches_ocupadas / c.noches_disponibles DESC) AS puesto,
       ho.nombre AS hotel, ci.nombre AS ciudad, ho.estrellas,
       ROUND(100 * o.noches_ocupadas / c.noches_disponibles, 1) AS ocupacion_pct
  FROM ocupadas o
  JOIN capacidad c ON c.hotel_id = o.hotel_id
  JOIN hoteles ho  ON ho.id = o.hotel_id
  JOIN ciudades ci ON ci.id = ho.ciudad_id
 ORDER BY puesto
 LIMIT 10;