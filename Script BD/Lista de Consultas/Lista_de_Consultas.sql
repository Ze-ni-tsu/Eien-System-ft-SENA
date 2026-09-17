-- 1. TABLA: roles
INSERT INTO roles (nombre, descripcion) VALUES ('SUPERVISOR', 'Acceso a reportes y auditoría');
SELECT * FROM roles WHERE nombre = 'SUPERVISOR';
UPDATE roles SET descripcion = 'Acceso a métricas globales' WHERE nombre = 'SUPERVISOR';
DELETE FROM roles WHERE id = 99;

-- 2. TABLA: usuarios
INSERT INTO usuarios (documento, nombre, apellido, correo, clave_hash, telefono, estado, rol_id)
VALUES ('1010203040', 'David', 'Meyer', 'david.meyer@kizuna.com', '$2b$12$eImigU...', '3001234567', TRUE, 1);
SELECT id, documento, nombre, apellido, correo FROM usuarios;
UPDATE usuarios SET telefono = '3009876543' WHERE documento = '1010203040';
DELETE FROM usuarios WHERE id = 99;

-- 3. TABLA: vehiculos
INSERT INTO vehiculos (placa, modelo, capacidad_peso_kg, estado) VALUES ('KZN-501', 'Chevrolet N300', 1200.50, 'DISPONIBLE');
SELECT placa, modelo, capacidad_peso_kg FROM vehiculos WHERE estado = 'DISPONIBLE';
UPDATE vehiculos SET estado = 'MANTENIMIENTO' WHERE placa = 'KZN-501';
DELETE FROM vehiculos WHERE id = 99;

-- 4. TABLA: conductores_vehiculos
INSERT INTO conductores_vehiculos (usuario_id, vehiculo_id, activo) VALUES (1, 1, TRUE);
SELECT cv.id, u.nombre, v.placa FROM conductores_vehiculos cv JOIN usuarios u ON cv.usuario_id = u.id JOIN vehiculos v ON cv.vehiculo_id = v.id;
UPDATE conductores_vehiculos SET activo = FALSE WHERE id = 1;
DELETE FROM conductores_vehiculos WHERE id = 99;

-- 5. TABLA: paquetes
INSERT INTO paquetes (numero_guia, direccion_destino, nombre_destinatario, telefono_destinatario, peso_kg, estado)
VALUES ('KZN-2026-001', 'Calle 100 # 15-20, Bogotá', 'Carlos Ruiz', '3109876543', 15.30, 'EN_BODEGA');
SELECT numero_guia, direccion_destino, peso_kg, estado FROM paquetes WHERE estado = 'EN_BODEGA';
UPDATE paquetes SET estado = 'EN_TRANSITO' WHERE numero_guia = 'KZN-2026-001';
DELETE FROM paquetes WHERE id = 99;

-- 6. TABLA: rutas
INSERT INTO rutas (codigo_ruta, estado, conductor_id) VALUES ('RUTA-NORTE-01', 'PROGRAMADA', 1);
SELECT r.codigo_ruta, r.estado, CONCAT(u.nombre, ' ', u.apellido) AS conductor FROM rutas r JOIN usuarios u ON r.conductor_id = u.id;
UPDATE rutas SET estado = 'EN_PROCESO' WHERE codigo_ruta = 'RUTA-NORTE-01';
DELETE FROM rutas WHERE id = 99;

-- 7. TABLA: detalle_ruta_paquetes
INSERT INTO detalle_ruta_paquetes (ruta_id, paquete_id, orden_visita) VALUES (1, 1, 1);
SELECT drp.orden_visita, r.codigo_ruta, p.numero_guia FROM detalle_ruta_paquetes drp JOIN rutas r ON drp.ruta_id = r.id JOIN paquetes p ON drp.paquete_id = p.id;
UPDATE detalle_ruta_paquetes SET orden_visita = 2 WHERE id = 1;
DELETE FROM detalle_ruta_paquetes WHERE id = 99;

-- 8. TABLA: evidencias_entrega
INSERT INTO evidencias_entrega (paquete_id, tipo_evidencia, url_archivo, observaciones) VALUES (1, 'AMBAS', 'https://storage.kizuna.com/evidencias/guia_001.pdf', 'Entrega sin novedades');
SELECT * FROM evidencias_entrega WHERE paquete_id = 1;
UPDATE evidencias_entrega SET observaciones = 'Entregado en portería' WHERE id = 1;
DELETE FROM evidencias_entrega WHERE id = 99;