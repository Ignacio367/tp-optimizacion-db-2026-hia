-- =====================================================================
-- TP Hoteles - Punto 2: diseño físico
-- Motor: MySQL 8.4 / InnoDB. Charset utf8mb4.
-- Este script crea SOLO tablas, claves primarias, claves únicas, claves
-- foráneas y restricciones CHECK. Los índices secundarios se crean en
-- 02_indices.sql (punto 3) para poder medir antes y después.
-- La regla de no superposición está en 01b_trigger_superposicion.sql.
-- =====================================================================

CREATE DATABASE IF NOT EXISTS hoteles
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;
USE hoteles;

-- Para volver a ejecutar el script desde cero (hijas primero)
DROP TABLE IF EXISTS reservas;
DROP TABLE IF EXISTS emails_huesped;
DROP TABLE IF EXISTS telefonos_huesped;
DROP TABLE IF EXISTS huespedes;
DROP TABLE IF EXISTS habitaciones;
DROP TABLE IF EXISTS tipo_habitacion_comodidad;
DROP TABLE IF EXISTS comodidades;
DROP TABLE IF EXISTS tipos_habitacion;
DROP TABLE IF EXISTS hotel_punto_interes;
DROP TABLE IF EXISTS puntos_interes;
DROP TABLE IF EXISTS categorias_punto_interes;
DROP TABLE IF EXISTS contactos_hotel;
DROP TABLE IF EXISTS hoteles;
DROP TABLE IF EXISTS ciudades;
DROP TABLE IF EXISTS provincias;
DROP TABLE IF EXISTS paises;

-- ---------------------------------------------------------------------
-- Ubicación
-- ---------------------------------------------------------------------
CREATE TABLE paises (
  id          SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre      VARCHAR(100)      NOT NULL,
  codigo_iso  CHAR(2)           NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_paises_nombre (nombre),
  UNIQUE KEY uk_paises_codigo_iso (codigo_iso)
) ENGINE=InnoDB;

CREATE TABLE provincias (
  id       INT UNSIGNED      NOT NULL AUTO_INCREMENT,
  pais_id  SMALLINT UNSIGNED NOT NULL,
  nombre   VARCHAR(100)      NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_provincias_pais_nombre (pais_id, nombre),
  CONSTRAINT fk_provincias_pais FOREIGN KEY (pais_id) REFERENCES paises (id)
) ENGINE=InnoDB;

CREATE TABLE ciudades (
  id            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  provincia_id  INT UNSIGNED NOT NULL,
  nombre        VARCHAR(100) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_ciudades_provincia_nombre (provincia_id, nombre),
  CONSTRAINT fk_ciudades_provincia FOREIGN KEY (provincia_id) REFERENCES provincias (id)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Hoteles
-- ---------------------------------------------------------------------
CREATE TABLE hoteles (
  id             INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  nombre         VARCHAR(150)     NOT NULL,
  descripcion    TEXT             NULL,
  estrellas      TINYINT UNSIGNED NOT NULL,
  ciudad_id      INT UNSIGNED     NOT NULL,
  direccion      VARCHAR(200)     NOT NULL,
  codigo_postal  VARCHAR(10)      NULL,
  latitud        DECIMAL(9,6)     NULL,
  longitud       DECIMAL(9,6)     NULL,
  hora_checkin   TIME             NOT NULL DEFAULT '14:00:00',
  hora_checkout  TIME             NOT NULL DEFAULT '10:00:00',
  activo         BOOLEAN          NOT NULL DEFAULT TRUE,
  fecha_alta     DATE             NOT NULL DEFAULT (CURRENT_DATE),
  PRIMARY KEY (id),
  CONSTRAINT chk_hoteles_estrellas CHECK (estrellas BETWEEN 1 AND 5),
  CONSTRAINT fk_hoteles_ciudad FOREIGN KEY (ciudad_id) REFERENCES ciudades (id)
) ENGINE=InnoDB;

CREATE TABLE contactos_hotel (
  id            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  hotel_id      INT UNSIGNED NOT NULL,
  tipo          ENUM('telefono','email','web','whatsapp') NOT NULL,
  valor         VARCHAR(255) NOT NULL,
  es_principal  BOOLEAN      NOT NULL DEFAULT FALSE,
  PRIMARY KEY (id),
  CONSTRAINT fk_contactos_hotel_hotel FOREIGN KEY (hotel_id) REFERENCES hoteles (id)
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Puntos de interés
-- ---------------------------------------------------------------------
CREATE TABLE categorias_punto_interes (
  id      SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre  VARCHAR(80)       NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_categorias_nombre (nombre)
) ENGINE=InnoDB;

CREATE TABLE puntos_interes (
  id            INT UNSIGNED      NOT NULL AUTO_INCREMENT,
  nombre        VARCHAR(150)      NOT NULL,
  categoria_id  SMALLINT UNSIGNED NOT NULL,
  ciudad_id     INT UNSIGNED      NOT NULL,
  direccion     VARCHAR(200)      NULL,
  latitud       DECIMAL(9,6)      NULL,
  longitud      DECIMAL(9,6)      NULL,
  descripcion   TEXT              NULL,
  PRIMARY KEY (id),
  CONSTRAINT fk_puntos_categoria FOREIGN KEY (categoria_id) REFERENCES categorias_punto_interes (id),
  CONSTRAINT fk_puntos_ciudad    FOREIGN KEY (ciudad_id)    REFERENCES ciudades (id)
) ENGINE=InnoDB;

CREATE TABLE hotel_punto_interes (
  hotel_id          INT UNSIGNED NOT NULL,
  punto_interes_id  INT UNSIGNED NOT NULL,
  distancia_km      DECIMAL(6,2) NOT NULL,
  PRIMARY KEY (hotel_id, punto_interes_id),
  CONSTRAINT chk_hpi_distancia CHECK (distancia_km >= 0),
  CONSTRAINT fk_hpi_hotel FOREIGN KEY (hotel_id) REFERENCES hoteles (id)
    ON DELETE CASCADE,
  CONSTRAINT fk_hpi_punto FOREIGN KEY (punto_interes_id) REFERENCES puntos_interes (id)
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Habitaciones
-- ---------------------------------------------------------------------
CREATE TABLE tipos_habitacion (
  id                SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre            VARCHAR(50)       NOT NULL,
  capacidad_maxima  TINYINT UNSIGNED  NOT NULL,
  descripcion       TEXT              NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_tipos_habitacion_nombre (nombre),
  CONSTRAINT chk_tipos_capacidad CHECK (capacidad_maxima > 0)
) ENGINE=InnoDB;

CREATE TABLE comodidades (
  id      SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  nombre  VARCHAR(80)       NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_comodidades_nombre (nombre)
) ENGINE=InnoDB;

CREATE TABLE tipo_habitacion_comodidad (
  tipo_habitacion_id  SMALLINT UNSIGNED NOT NULL,
  comodidad_id        SMALLINT UNSIGNED NOT NULL,
  PRIMARY KEY (tipo_habitacion_id, comodidad_id),
  CONSTRAINT fk_thc_tipo FOREIGN KEY (tipo_habitacion_id) REFERENCES tipos_habitacion (id)
    ON DELETE CASCADE,
  CONSTRAINT fk_thc_comodidad FOREIGN KEY (comodidad_id) REFERENCES comodidades (id)
    ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE habitaciones (
  id                  INT UNSIGNED      NOT NULL AUTO_INCREMENT,
  hotel_id            INT UNSIGNED      NOT NULL,
  tipo_habitacion_id  SMALLINT UNSIGNED NOT NULL,
  numero              VARCHAR(10)       NOT NULL,
  piso                SMALLINT          NULL,
  activa              BOOLEAN           NOT NULL DEFAULT TRUE,
  PRIMARY KEY (id),
  UNIQUE KEY uk_habitaciones_hotel_numero (hotel_id, numero),
  CONSTRAINT fk_habitaciones_hotel FOREIGN KEY (hotel_id) REFERENCES hoteles (id),
  CONSTRAINT fk_habitaciones_tipo  FOREIGN KEY (tipo_habitacion_id) REFERENCES tipos_habitacion (id)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Huéspedes
-- ---------------------------------------------------------------------
CREATE TABLE huespedes (
  id                INT UNSIGNED      NOT NULL AUTO_INCREMENT,
  tipo_documento    ENUM('dni','pasaporte','cedula','otro') NOT NULL,
  numero_documento  VARCHAR(20)       NOT NULL,
  nacionalidad_id   SMALLINT UNSIGNED NOT NULL,
  nombre            VARCHAR(80)       NOT NULL,
  apellido          VARCHAR(80)       NOT NULL,
  fecha_nacimiento  DATE              NULL,
  calle             VARCHAR(150)      NULL,
  numero_calle      VARCHAR(10)       NULL,
  piso_depto        VARCHAR(10)       NULL,
  codigo_postal     VARCHAR(10)       NULL,
  ciudad_id         INT UNSIGNED      NULL,
  fecha_alta        TIMESTAMP         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_huespedes_documento (nacionalidad_id, tipo_documento, numero_documento),
  CONSTRAINT fk_huespedes_nacionalidad FOREIGN KEY (nacionalidad_id) REFERENCES paises (id),
  CONSTRAINT fk_huespedes_ciudad       FOREIGN KEY (ciudad_id)       REFERENCES ciudades (id)
) ENGINE=InnoDB;

CREATE TABLE telefonos_huesped (
  id            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  huesped_id    INT UNSIGNED NOT NULL,
  tipo          ENUM('movil','fijo','laboral') NOT NULL,
  numero        VARCHAR(20)  NOT NULL,
  es_principal  BOOLEAN      NOT NULL DEFAULT FALSE,
  PRIMARY KEY (id),
  CONSTRAINT fk_telefonos_huesped FOREIGN KEY (huesped_id) REFERENCES huespedes (id)
    ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE emails_huesped (
  id            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  huesped_id    INT UNSIGNED NOT NULL,
  email         VARCHAR(255) NOT NULL,
  es_principal  BOOLEAN      NOT NULL DEFAULT FALSE,
  PRIMARY KEY (id),
  UNIQUE KEY uk_emails_email (email),
  CONSTRAINT fk_emails_huesped FOREIGN KEY (huesped_id) REFERENCES huespedes (id)
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Reservas (tabla del experimento: 6 millones de filas o más)
-- ---------------------------------------------------------------------
CREATE TABLE reservas (
  id                  BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
  huesped_id          INT UNSIGNED     NOT NULL,
  habitacion_id       INT UNSIGNED     NOT NULL,
  fecha_inicio        DATE             NOT NULL,
  fecha_fin           DATE             NOT NULL,
  cantidad_huespedes  TINYINT UNSIGNED NOT NULL DEFAULT 1,
  estado              ENUM('pendiente','confirmada','cancelada','finalizada')
                                       NOT NULL DEFAULT 'pendiente',
  tarifa_por_noche    DECIMAL(10,2)    NULL,
  fecha_creacion      TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  fecha_confirmacion  TIMESTAMP        NULL DEFAULT NULL,
  PRIMARY KEY (id),
  CONSTRAINT chk_reservas_fechas CHECK (fecha_fin > fecha_inicio),
  CONSTRAINT chk_reservas_huespedes CHECK (cantidad_huespedes > 0),
  -- La tarifa se fija solo al confirmar: pendiente no la tiene;
  -- confirmada y finalizada la tienen; cancelada puede tenerla o no.
  CONSTRAINT chk_reservas_tarifa CHECK (
        (estado = 'pendiente' AND tarifa_por_noche IS NULL)
     OR (estado IN ('confirmada','finalizada') AND tarifa_por_noche IS NOT NULL AND tarifa_por_noche > 0)
     OR  estado = 'cancelada'
  ),
  CONSTRAINT fk_reservas_huesped    FOREIGN KEY (huesped_id)    REFERENCES huespedes (id),
  CONSTRAINT fk_reservas_habitacion FOREIGN KEY (habitacion_id) REFERENCES habitaciones (id)
) ENGINE=InnoDB;