-- 1. LIMPIEZA Y CREACIÓN DE BASE DE DATOS
DROP DATABASE IF EXISTS eien_system_db;
CREATE DATABASE eien_system_db;
\c eien_system_db;

-- 2. CREACIÓN DE USUARIOS Y ASIGNACIÓN DE PRIVILEGIOS
CREATE USER admin_eien WITH PASSWORD 'AdminEien2026!';
CREATE USER despachador_eien WITH PASSWORD 'Despachador2026!';
CREATE USER conductor_eien WITH PASSWORD 'Conductor2026!';

-- 3. CREACIÓN DE TABLAS Y RESTRICCIONES (DDL)

-- Tabla: Roles
CREATE TABLE roles (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL UNIQUE,
    descripcion VARCHAR(150)
);

-- Tabla: Usuarios (Administradores, Despachadores, Conductores)
CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    documento VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    correo VARCHAR(100) NOT NULL UNIQUE,
    clave_hash VARCHAR(255) NOT NULL, -- Soporte para encriptación BCrypt
    telefono VARCHAR(15) NOT NULL,
    estado BOOLEAN NOT NULL DEFAULT TRUE,
    rol_id INT NOT NULL,
    CONSTRAINT fk_usuarios_roles FOREIGN KEY (rol_id) REFERENCES roles(id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Tabla: Vehiculos
CREATE TABLE vehiculos (
    id SERIAL PRIMARY KEY,
    placa VARCHAR(10) NOT NULL UNIQUE,
    modelo VARCHAR(50) NOT NULL,
    capacidad_peso_kg DECIMAL(8,2) NOT NULL,
    estado VARCHAR(20) NOT NULL DEFAULT 'DISPONIBLE',
    CONSTRAINT chk_capacidad_positiva CHECK (capacidad_peso_kg > 0),
    CONSTRAINT chk_estado_vehiculo CHECK (estado IN ('DISPONIBLE', 'EN_RUTA', 'MANTENIMIENTO'))
);

-- Tabla: Conductores_Vehiculos (Asignación)
CREATE TABLE conductores_vehiculos (
    id SERIAL PRIMARY KEY,
    usuario_id INT NOT NULL,
    vehiculo_id INT NOT NULL,
    fecha_asignacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    activo BOOLEAN DEFAULT TRUE,
    CONSTRAINT fk_cv_usuario FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
    CONSTRAINT fk_cv_vehiculo FOREIGN KEY (vehiculo_id) REFERENCES vehiculos(id)
);

-- Tabla: Paquetes (Guías Logísticas)
CREATE TABLE paquetes (
    id SERIAL PRIMARY KEY,
    numero_guia VARCHAR(30) NOT NULL UNIQUE,
    direccion_destino VARCHAR(200) NOT NULL,
    nombre_destinatario VARCHAR(100) NOT NULL,
    telefono_destinatario VARCHAR(15) NOT NULL,
    peso_kg DECIMAL(6,2) NOT NULL,
    ancho_cm DECIMAL(6,2),
    alto_cm DECIMAL(6,2),
    largo_cm DECIMAL(6,2),
    estado VARCHAR(25) NOT NULL DEFAULT 'EN_BODEGA',
    fecha_ingreso TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_peso_positivo CHECK (peso_kg > 0), -- Validación RF-01
    CONSTRAINT chk_estado_paquete CHECK (estado IN ('EN_BODEGA', 'ASIGNADO', 'EN_TRANSITO', 'ENTREGADO', 'NO_ENTREGADO'))
);

-- Tabla: Rutas
CREATE TABLE rutas (
    id SERIAL PRIMARY KEY,
    codigo_ruta VARCHAR(20) NOT NULL UNIQUE,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    estado VARCHAR(20) NOT NULL DEFAULT 'PROGRAMADA',
    conductor_id INT NOT NULL,
    CONSTRAINT fk_rutas_conductor FOREIGN KEY (conductor_id) REFERENCES usuarios(id),
    CONSTRAINT chk_estado_ruta CHECK (estado IN ('PROGRAMADA', 'EN_PROCESO', 'FINALIZADA'))
);

-- Tabla: Detalle_Ruta_Paquetes
CREATE TABLE detalle_ruta_paquetes (
    id SERIAL PRIMARY KEY,
    ruta_id INT NOT NULL,
    paquete_id INT NOT NULL,
    orden_visita INT NOT NULL,
    CONSTRAINT fk_drp_ruta FOREIGN KEY (ruta_id) REFERENCES rutas(id),
    CONSTRAINT fk_drp_paquete FOREIGN KEY (paquete_id) REFERENCES paquetes(id)
);

-- Tabla: Evidencias_Entrega (Firma o Fotografía)
CREATE TABLE evidencias_entrega (
    id SERIAL PRIMARY KEY,
    paquete_id INT NOT NULL UNIQUE,
    tipo_evidencia VARCHAR(20) NOT NULL,
    url_archivo VARCHAR(255) NOT NULL, -- Ruta o Hash de la firma/foto
    fecha_captura TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    observaciones TEXT,
    CONSTRAINT fk_evidencia_paquete FOREIGN KEY (paquete_id) REFERENCES paquetes(id),
    CONSTRAINT chk_tipo_evidencia CHECK (tipo_evidencia IN ('FIRMA', 'FOTO', 'AMBAS'))
);

-- 4. SEGURIDAD Y PERMISOS DE USUARIOS SQL (Mínimo Privilegio)
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin_eien;

-- Despachador: Puede registrar paquetes, crear rutas y consultar datos
GRANT SELECT, INSERT, UPDATE ON paquetes, rutas, detalle_ruta_paquetes, vehiculos TO despachador_eien;

-- Conductor: Solo consulta rutas y actualiza el estado de paquetes / registra evidencia
GRANT SELECT ON rutas, detalle_ruta_paquetes TO conductor_eien;
GRANT SELECT, UPDATE ON paquetes TO conductor_eien;
GRANT INSERT ON evidencias_entrega TO conductor_eien;

-- 5. OBJETOS COMPLEMENTARIOS (Vista, Función y Procedimiento)

-- Vista: Monitoreo de Rutas y Paquetes
CREATE VIEW vista_monitoreo_rutas AS
SELECT 
    r.codigo_ruta,
    CONCAT(u.nombre, ' ', u.apellido) AS conductor,
    p.numero_guia,
    p.direccion_destino,
    p.estado AS estado_paquete
FROM rutas r
JOIN usuarios u ON r.conductor_id = u.id
JOIN detalle_ruta_paquetes drp ON r.id = drp.ruta_id
JOIN paquetes p ON drp.paquete_id = p.id;

-- Función: Contar entregas realizadas por un conductor
CREATE OR REPLACE FUNCTION fn_total_entregas_conductor(p_conductor_id INT)
RETURNS INT AS $$
DECLARE
    v_total INT;
BEGIN
    SELECT COUNT(DISTINCT drp.paquete_id) INTO v_total
    FROM rutas r
    JOIN detalle_ruta_paquetes drp ON r.id = drp.ruta_id
    JOIN paquetes p ON drp.paquete_id = p.id
    WHERE r.conductor_id = p_conductor_id AND p.estado = 'ENTREGADO';
    
    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

-- Procedimiento Almacenado: Cambiar estado de un paquete
CREATE OR REPLACE PROCEDURE sp_actualizar_estado_paquete(
    p_paquete_id INT,
    p_nuevo_estado VARCHAR
)
AS $$
BEGIN
    UPDATE paquetes
    SET estado = p_nuevo_estado
    WHERE id = p_paquete_id;
END;
$$ LANGUAGE plpgsql;