-- Punto 10: consultas complejas
USE hoteles;

-- ---------------------------------------------------------------------
-- C5. Hoteles cerca de museos y su demanda futura (6 tablas)
-- Hoteles a menos de 3 km de un museo, con la distancia y la cantidad de
-- reservas confirmadas desde hoy. Los hoteles sin reservas futuras también
-- aparecen, con 0.
-- Usa: JOIN de 6 tablas, LEFT JOIN con condiciones en el ON, CURDATE(),
-- GROUP BY, COUNT sobre la tabla opcional.
-- ---------------------------------------------------------------------
SELECT ho.nombre AS hotel, ho.estrellas, pi.nombre AS museo,
       hpi.distancia_km,
       COUNT(r.id) AS reservas_futuras
  FROM categorias_punto_interes cat
  JOIN puntos_interes pi       ON pi.categoria_id = cat.id
  JOIN hotel_punto_interes hpi ON hpi.punto_interes_id = pi.id
  JOIN hoteles ho              ON ho.id = hpi.hotel_id
  JOIN habitaciones h          ON h.hotel_id = ho.id
  LEFT JOIN reservas r         ON r.habitacion_id = h.id
                              AND r.estado = 'confirmada'
                              AND r.fecha_inicio >= CURDATE()
 WHERE cat.nombre = 'Museo'
   AND hpi.distancia_km < 3
 GROUP BY ho.id, ho.nombre, ho.estrellas, pi.id, pi.nombre, hpi.distancia_km
 ORDER BY hpi.distancia_km
 LIMIT 20;