-- =====================================================================
-- Regla: una habitación no puede tener reservas con períodos superpuestos.
-- MySQL no tiene restricciones de exclusión (PostgreSQL sí: EXCLUDE USING gist),
-- así que se implementa con triggers.
--
-- Criterio de superposición: dos períodos [inicio, fin) se superponen si
--   existente.fecha_inicio < nueva.fecha_fin  Y  existente.fecha_fin > nueva.fecha_inicio
-- La fecha de salida de una reserva puede ser la fecha de entrada de la
-- siguiente (el huésped sale y entra otro el mismo día). Las reservas
-- canceladas no ocupan la habitación.
--
-- IMPORTANTE para la carga masiva (punto 8): ejecutar este archivo DESPUÉS
-- de cargar los 6 millones de filas. El trigger consulta la tabla en cada
-- INSERT y haría la carga muy lenta. Los datos se generan ya sin superposiciones.
-- =====================================================================
USE hoteles;

DROP TRIGGER IF EXISTS trg_reservas_sin_superposicion_ins;
DROP TRIGGER IF EXISTS trg_reservas_sin_superposicion_upd;

DELIMITER $$

CREATE TRIGGER trg_reservas_sin_superposicion_ins
BEFORE INSERT ON reservas
FOR EACH ROW
BEGIN
  IF NEW.estado <> 'cancelada' AND EXISTS (
       SELECT 1
         FROM reservas r
        WHERE r.habitacion_id = NEW.habitacion_id
          AND r.estado <> 'cancelada'
          AND r.fecha_inicio < NEW.fecha_fin
          AND r.fecha_fin    > NEW.fecha_inicio
     ) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'La habitacion ya tiene una reserva en ese periodo';
  END IF;
END$$

CREATE TRIGGER trg_reservas_sin_superposicion_upd
BEFORE UPDATE ON reservas
FOR EACH ROW
BEGIN
  IF NEW.estado <> 'cancelada' AND EXISTS (
       SELECT 1
         FROM reservas r
        WHERE r.habitacion_id = NEW.habitacion_id
          AND r.id <> NEW.id
          AND r.estado <> 'cancelada'
          AND r.fecha_inicio < NEW.fecha_fin
          AND r.fecha_fin    > NEW.fecha_inicio
     ) THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'La habitacion ya tiene una reserva en ese periodo';
  END IF;
END$$

DELIMITER ;