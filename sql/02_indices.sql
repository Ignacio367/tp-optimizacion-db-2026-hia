-- =====================================================================
-- TP Hoteles - Punto 3: estrategia de índices
-- Ejecutar DESPUÉS de la carga masiva (punto 8) y ANTES del trigger
-- (01b_trigger_superposicion.sql). Crear los índices sobre la tabla ya
-- cargada es más rápido que mantenerlos fila por fila durante la carga.
--
-- Las claves primarias, únicas y foráneas ya las crea 01_schema.sql.
-- Este script agrega solo índices secundarios, cada uno pensado para un
-- tipo de consulta concreto. Es la estrategia "limitada" del punto 7.
--
-- Nota: MySQL crea automáticamente un índice por cada clave foránea que no
-- tenga uno. Si después se crea otro índice que empieza por esa columna,
-- MySQL borra el automático porque ya no hace falta. Por eso, después de
-- este script, desaparecen fk_reservas_habitacion y fk_reservas_huesped:
-- las claves foráneas pasan a usar los índices compuestos de abajo.
-- =====================================================================
USE hoteles;

-- 1. Disponibilidad y regla de no superposición.
--    Consultas: "¿qué habitaciones están libres entre X e Y?" y el chequeo
--    que hace el trigger antes de cada INSERT o UPDATE.
--    Orden: habitacion_id va primero porque se busca por igualdad; las
--    fechas después porque se filtran por rango. estado va al final para
--    que el índice sea "cubriente": la consulta se resuelve sin leer la fila.
CREATE INDEX idx_reservas_disponibilidad
    ON reservas (habitacion_id, fecha_inicio, fecha_fin, estado);

-- 2. Historial de un huésped.
--    Consulta: reservas de un huésped ordenadas por fecha.
--    Con fecha_inicio en el índice, MySQL devuelve las filas ya ordenadas
--    y evita el ordenamiento aparte (filesort).
CREATE INDEX idx_reservas_huesped_fecha
    ON reservas (huesped_id, fecha_inicio);

-- 3. Reservas por período (mes, año, futuras, históricas).
--    Consultas: conteos y listados con fecha_inicio entre dos fechas.
--    Es un índice simple porque el filtro es solo por fecha.
CREATE INDEX idx_reservas_fecha_inicio
    ON reservas (fecha_inicio);

-- 4. Reservas de un estado en un período.
--    Consultas: "confirmadas a partir de hoy", estadísticas de ocupación
--    con estado IN ('confirmada','finalizada').
--    Orden: estado primero (igualdad) y fecha_inicio después (rango). Al
--    revés, el índice cortaría en la fecha y no aprovecharía el estado.
CREATE INDEX idx_reservas_estado_fecha
    ON reservas (estado, fecha_inicio);

-- 5. Búsqueda de huéspedes por nombre.
--    Consulta: buscar un huésped por apellido, y opcionalmente por nombre.
--    Sirve para apellido solo, o apellido y nombre; no para nombre solo
--    (regla del prefijo izquierdo, punto 5).
CREATE INDEX idx_huespedes_apellido_nombre
    ON huespedes (apellido, nombre);

-- Actualizar las estadísticas para que el optimizador use los índices nuevos
ANALYZE TABLE reservas, huespedes;

-- Verificación: lista todos los índices de las dos tablas modificadas
SELECT table_name AS tabla, index_name AS indice,
       GROUP_CONCAT(column_name ORDER BY seq_in_index) AS columnas,
       IF(non_unique = 0, 'UNIQUE', '') AS tipo
  FROM information_schema.statistics
 WHERE table_schema = 'hoteles' AND table_name IN ('reservas', 'huespedes')
 GROUP BY table_name, index_name, non_unique
 ORDER BY table_name, index_name;