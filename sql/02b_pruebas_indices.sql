-- =====================================================================
-- Pruebas de la estrategia de índices (punto 3).
-- Ejecutar una vez ANTES de 02_indices.sql y otra DESPUÉS, y comparar:
--   key  -> índice usado (NULL = no usa ninguno)
--   type -> ALL = recorre la tabla entera; ref/range = usa un índice
--   rows -> filas que MySQL estima leer
--   Extra -> "Using index" = se resuelve sin leer la fila (índice cubriente)
--            "Using filesort" = ordena aparte, sin aprovechar un índice
-- Para tiempos reales, cambiar EXPLAIN por EXPLAIN ANALYZE.
-- =====================================================================
USE hoteles;

-- Q1 Disponibilidad: habitaciones del hotel 7 libres del 20 al 27/12/2026
EXPLAIN
SELECT h.id, h.numero
  FROM habitaciones h
 WHERE h.hotel_id = 7 AND h.activa
   AND NOT EXISTS (SELECT 1 FROM reservas r
                    WHERE r.habitacion_id = h.id
                      AND r.estado <> 'cancelada'
                      AND r.fecha_inicio < '2026-12-27'
                      AND r.fecha_fin    > '2026-12-20');

-- Q2 Chequeo del trigger para una habitación
EXPLAIN
SELECT 1 FROM reservas r
 WHERE r.habitacion_id = 123 AND r.estado <> 'cancelada'
   AND r.fecha_inicio < '2026-12-27' AND r.fecha_fin > '2026-12-20'
 LIMIT 1;

-- Q3 Historial de un huésped, de la más reciente a la más vieja
EXPLAIN
SELECT id, fecha_inicio, fecha_fin, estado
  FROM reservas WHERE huesped_id = 1234
 ORDER BY fecha_inicio DESC;

-- Q4 Cantidad de reservas que empiezan en marzo de 2025
EXPLAIN
SELECT COUNT(*) FROM reservas
 WHERE fecha_inicio >= '2025-03-01' AND fecha_inicio < '2025-04-01';

-- Q5 Próximas 50 reservas confirmadas
EXPLAIN
SELECT id, habitacion_id, fecha_inicio FROM reservas
 WHERE estado = 'confirmada' AND fecha_inicio >= '2026-10-01'
 ORDER BY fecha_inicio LIMIT 50;

-- Q6 Buscar un huésped por apellido y comienzo del nombre
EXPLAIN
SELECT id, nombre, apellido FROM huespedes
 WHERE apellido = 'Apellido123' AND nombre LIKE 'Nombre1%';