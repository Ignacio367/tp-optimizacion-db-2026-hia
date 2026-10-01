-- Punto 10: consultas complejas
USE hoteles;

-- ---------------------------------------------------------------------
-- C1. Disponibilidad (6 tablas)
-- Suites libres en hoteles de Argentina para el 20 al 27 de diciembre de
-- 2026, de los hoteles con más estrellas a los de menos.
-- Usa: JOIN, NOT EXISTS, criterio de superposición de períodos, LIMIT.
-- ---------------------------------------------------------------------
SELECT ho.nombre AS hotel, ho.estrellas, ci.nombre AS ciudad,
       h.numero AS habitacion, t.nombre AS tipo, t.capacidad_maxima
  FROM habitaciones h
  JOIN hoteles ho          ON ho.id = h.hotel_id
  JOIN ciudades ci         ON ci.id = ho.ciudad_id
  JOIN provincias pr       ON pr.id = ci.provincia_id
  JOIN tipos_habitacion t  ON t.id  = h.tipo_habitacion_id
 WHERE pr.pais_id = (SELECT id FROM paises WHERE codigo_iso = 'AR')
   AND t.nombre = 'Suite'
   AND ho.activo AND h.activa
   AND NOT EXISTS (SELECT 1 FROM reservas r
                    WHERE r.habitacion_id = h.id
                      AND r.estado <> 'cancelada'
                      AND r.fecha_inicio < '2026-12-27'
                      AND r.fecha_fin    > '2026-12-20')
 ORDER BY ho.estrellas DESC, ho.nombre, h.numero
 LIMIT 20;