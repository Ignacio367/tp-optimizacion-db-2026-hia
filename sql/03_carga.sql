-- =====================================================================
-- Punto 8: carga masiva. Lee los CSV de datos/ (montada en el contenedor
-- como /var/lib/mysql-files, la única carpeta desde la que MySQL permite
-- LOAD DATA INFILE). Ejecutar sobre la base vacía recién creada.
-- Después: 02_indices.sql y 01b_trigger_superposicion.sql.
-- =====================================================================
USE hoteles;

-- Acelera la carga: no verifica claves foráneas ni únicas fila por fila.
-- Es seguro porque el generador produce datos consistentes.
SET foreign_key_checks = 0;
SET unique_checks = 0;

LOAD DATA INFILE '/var/lib/mysql-files/paises.csv'     INTO TABLE paises     FIELDS TERMINATED BY ',' (id, nombre, codigo_iso);
LOAD DATA INFILE '/var/lib/mysql-files/provincias.csv' INTO TABLE provincias FIELDS TERMINATED BY ',' (id, pais_id, nombre);
LOAD DATA INFILE '/var/lib/mysql-files/ciudades.csv'   INTO TABLE ciudades   FIELDS TERMINATED BY ',' (id, provincia_id, nombre);
LOAD DATA INFILE '/var/lib/mysql-files/hoteles.csv'    INTO TABLE hoteles    FIELDS TERMINATED BY ',' (id, nombre, estrellas, ciudad_id, direccion);
LOAD DATA INFILE '/var/lib/mysql-files/contactos_hotel.csv' INTO TABLE contactos_hotel FIELDS TERMINATED BY ',' (hotel_id, tipo, valor);
LOAD DATA INFILE '/var/lib/mysql-files/categorias.csv' INTO TABLE categorias_punto_interes FIELDS TERMINATED BY ',' (id, nombre);
LOAD DATA INFILE '/var/lib/mysql-files/puntos_interes.csv' INTO TABLE puntos_interes FIELDS TERMINATED BY ',' (id, nombre, categoria_id, ciudad_id);
LOAD DATA INFILE '/var/lib/mysql-files/hotel_punto_interes.csv' INTO TABLE hotel_punto_interes FIELDS TERMINATED BY ',' (hotel_id, punto_interes_id, distancia_km);
LOAD DATA INFILE '/var/lib/mysql-files/tipos.csv'       INTO TABLE tipos_habitacion FIELDS TERMINATED BY ',' (id, nombre, capacidad_maxima);
LOAD DATA INFILE '/var/lib/mysql-files/comodidades.csv' INTO TABLE comodidades FIELDS TERMINATED BY ',' (id, nombre);
LOAD DATA INFILE '/var/lib/mysql-files/tipo_comodidad.csv' INTO TABLE tipo_habitacion_comodidad FIELDS TERMINATED BY ',' (tipo_habitacion_id, comodidad_id);
LOAD DATA INFILE '/var/lib/mysql-files/habitaciones.csv' INTO TABLE habitaciones FIELDS TERMINATED BY ',' (id, hotel_id, tipo_habitacion_id, numero, piso);
LOAD DATA INFILE '/var/lib/mysql-files/huespedes.csv'  INTO TABLE huespedes  FIELDS TERMINATED BY ',' (id, tipo_documento, numero_documento, nacionalidad_id, nombre, apellido, ciudad_id);
LOAD DATA INFILE '/var/lib/mysql-files/telefonos.csv'  INTO TABLE telefonos_huesped FIELDS TERMINATED BY ',' (huesped_id, tipo, numero);
LOAD DATA INFILE '/var/lib/mysql-files/emails.csv'     INTO TABLE emails_huesped    FIELDS TERMINATED BY ',' (huesped_id, email);
LOAD DATA INFILE '/var/lib/mysql-files/reservas.csv'   INTO TABLE reservas   FIELDS TERMINATED BY ','
  (huesped_id, habitacion_id, fecha_inicio, fecha_fin, cantidad_huespedes, estado, tarifa_por_noche, fecha_creacion, fecha_confirmacion);

SET unique_checks = 1;
SET foreign_key_checks = 1;
ANALYZE TABLE reservas, huespedes, habitaciones, hoteles;

-- Verificación
SELECT 'reservas' AS tabla, COUNT(*) AS filas FROM reservas
UNION ALL SELECT 'huespedes', COUNT(*) FROM huespedes
UNION ALL SELECT 'habitaciones', COUNT(*) FROM habitaciones;