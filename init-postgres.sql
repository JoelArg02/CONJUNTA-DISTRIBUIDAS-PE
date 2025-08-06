-- Script de inicialización para PostgreSQL
-- Crea las bases de datos necesarias para los microservicios

-- Crear base de datos para el servicio central
CREATE DATABASE central_db;

-- Crear base de datos para el servicio billing
CREATE DATABASE billing_db;

-- Opcional: Crear usuarios específicos para cada servicio (puedes descomentar si es necesario)
-- CREATE USER central_user WITH ENCRYPTED PASSWORD 'central_password';
-- CREATE USER billing_user WITH ENCRYPTED PASSWORD 'billing_password';

-- Otorgar permisos (descomentar si creas usuarios específicos)
-- GRANT ALL PRIVILEGES ON DATABASE central_db TO central_user;
-- GRANT ALL PRIVILEGES ON DATABASE billing_db TO billing_user;

-- Mostrar las bases de datos creadas
\l
