-- Punto 10: consultas complejas
USE hoteles;

-- ---------------------------------------------------------------------
-- C4. Huéspedes frecuentes (4 tablas)
-- Huéspedes con 10 o más estadías finalizadas, con su nacionalidad, email
-- y gasto total, clasificados en categorías de fidelidad.
-- Usa: JOIN, LEFT JOIN, GROUP BY, HAVING, CASE WHEN, agregación.
-- Candidata a optimizar (punto 18): agrupa todas las reservas finalizadas
-- (millones de filas) antes de filtrar con HAVING.
-- ---------------------------------------------------------------------
SELECT hu.id, CONCAT(hu.nombre, ' ', hu.apellido) AS huesped,
       pa.nombre AS nacionalidad, e.email,
       COUNT(*) AS estadias,
       SUM(DATEDIFF(r.fecha_fin, r.fecha_inicio) * r.tarifa_por_noche) AS gasto_total,
       CASE WHEN COUNT(*) >= 14 THEN 'Oro'
            WHEN COUNT(*) >= 12 THEN 'Plata'
            ELSE 'Bronce' END AS categoria
  FROM huespedes hu
  JOIN reservas r          ON r.huesped_id = hu.id AND r.estado = 'finalizada'
  JOIN paises pa           ON pa.id = hu.nacionalidad_id
  LEFT JOIN emails_huesped e ON e.huesped_id = hu.id
 GROUP BY hu.id, hu.nombre, hu.apellido, pa.nombre, e.email
HAVING COUNT(*) >= 10
 ORDER BY estadias DESC, gasto_total DESC
 LIMIT 20;