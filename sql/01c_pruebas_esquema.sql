-- =====================================================================
-- Pruebas del esquema, las restricciones y el trigger de superposición.
-- Ejecutar sobre la base RECIÉN creada (01_schema.sql + 01b_trigger...)
-- y con --force, para que siga después de cada error esperado:
--   mysql --force -uroot -proot < sql/01c_pruebas_esquema.sql
-- Después de probar, volver a ejecutar 01_schema.sql para dejar la base vacía.
-- =====================================================================
USE hoteles;

-- Datos mínimos
INSERT INTO paises(nombre, codigo_iso) VALUES ('Argentina', 'AR');
INSERT INTO provincias(pais_id, nombre) VALUES (1, 'Cordoba');
INSERT INTO ciudades(provincia_id, nombre) VALUES (1, 'Cordoba');
INSERT INTO hoteles(nombre, estrellas, ciudad_id, direccion) VALUES ('Hotel Uno', 4, 1, 'Calle 1');
INSERT INTO tipos_habitacion(nombre, capacidad_maxima) VALUES ('Doble', 2);
INSERT INTO habitaciones(hotel_id, tipo_habitacion_id, numero, piso) VALUES (1, 1, '101', -1), (1, 1, '102', 1);
INSERT INTO huespedes(tipo_documento, numero_documento, nacionalidad_id, nombre, apellido)
VALUES ('dni', '30111222', 1, 'Ana', 'Perez');

-- T1  DEBE PASAR: reserva pendiente sin tarifa
INSERT INTO reservas(huesped_id, habitacion_id, fecha_inicio, fecha_fin, estado)
VALUES (1, 1, '2026-10-10', '2026-10-15', 'pendiente');

-- T2  DEBE FALLAR (chk_reservas_fechas): salida igual a la entrada
INSERT INTO reservas(huesped_id, habitacion_id, fecha_inicio, fecha_fin)
VALUES (1, 2, '2026-10-10', '2026-10-10');

-- T3  DEBE FALLAR (chk_reservas_tarifa): pendiente con tarifa
INSERT INTO reservas(huesped_id, habitacion_id, fecha_inicio, fecha_fin, estado, tarifa_por_noche)
VALUES (1, 2, '2026-11-01', '2026-11-03', 'pendiente', 100);

-- T4  DEBE FALLAR (chk_reservas_tarifa): confirmada sin tarifa
INSERT INTO reservas(huesped_id, habitacion_id, fecha_inicio, fecha_fin, estado)
VALUES (1, 2, '2026-11-01', '2026-11-03', 'confirmada');

-- T5  DEBE PASAR: confirmada con tarifa
INSERT INTO reservas(huesped_id, habitacion_id, fecha_inicio, fecha_fin, estado, tarifa_por_noche)
VALUES (1, 2, '2026-11-01', '2026-11-03', 'confirmada', 85000.50);

-- T6  DEBE FALLAR (trigger): se superpone parcialmente con T1
INSERT INTO reservas(huesped_id, habitacion_id, fecha_inicio, fecha_fin)
VALUES (1, 1, '2026-10-12', '2026-10-18');

-- T7  DEBE FALLAR (trigger): queda dentro de T1
INSERT INTO reservas(huesped_id, habitacion_id, fecha_inicio, fecha_fin)
VALUES (1, 1, '2026-10-11', '2026-10-13');

-- T8  DEBE PASAR: entra el mismo día que sale T1
INSERT INTO reservas(huesped_id, habitacion_id, fecha_inicio, fecha_fin)
VALUES (1, 1, '2026-10-15', '2026-10-20');

-- T9  DEBE PASAR: mismo período que T1 pero cancelada (no ocupa la habitación)
INSERT INTO reservas(huesped_id, habitacion_id, fecha_inicio, fecha_fin, estado)
VALUES (1, 1, '2026-10-10', '2026-10-15', 'cancelada');

-- T10 DEBE FALLAR (trigger de UPDATE): extender T1 pisa a T8
UPDATE reservas SET fecha_fin = '2026-10-17'
 WHERE habitacion_id = 1 AND fecha_inicio = '2026-10-10' AND estado = 'pendiente';

-- T11 DEBE FALLAR (chk_hoteles_estrellas): 6 estrellas
INSERT INTO hoteles(nombre, estrellas, ciudad_id, direccion) VALUES ('X', 6, 1, 'Y');

-- T12 DEBE FALLAR (uk_habitaciones_hotel_numero): número repetido en el hotel
INSERT INTO habitaciones(hotel_id, tipo_habitacion_id, numero) VALUES (1, 1, '101');

-- T13 DEBE FALLAR (uk_huespedes_documento): documento repetido
INSERT INTO huespedes(tipo_documento, numero_documento, nacionalidad_id, nombre, apellido)
VALUES ('dni', '30111222', 1, 'Otro', 'Persona');

-- T14 DEBE FALLAR (fk_reservas_habitacion): habitación inexistente
INSERT INTO reservas(huesped_id, habitacion_id, fecha_inicio, fecha_fin)
VALUES (1, 999, '2027-01-01', '2027-01-03');

-- T15 DEBE FALLAR (fk_reservas_huesped): huésped con reservas no se puede borrar
DELETE FROM huespedes WHERE id = 1;

-- T16 DEBE FALLAR (uk_emails_email): mismo email con otra capitalización
INSERT INTO emails_huesped(huesped_id, email) VALUES (1, 'ana@mail.com');
INSERT INTO emails_huesped(huesped_id, email) VALUES (1, 'ANA@mail.com');

-- Estado final esperado: 4 reservas (T1, T5, T8, T9)
SELECT id, habitacion_id, fecha_inicio, fecha_fin, estado, tarifa_por_noche FROM reservas ORDER BY id;