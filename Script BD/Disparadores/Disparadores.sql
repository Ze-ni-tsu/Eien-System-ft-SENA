-- 1. Tabla para almacenar el historial de cambios
CREATE TABLE IF NOT EXISTS auditoria_estados_paquetes (
    id SERIAL PRIMARY KEY,
    paquete_id INT NOT NULL,
    estado_anterior VARCHAR(25),
    estado_nuevo VARCHAR(25),
    fecha_cambio TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Función que ejecuta la lógica del disparador
CREATE OR REPLACE FUNCTION fn_trg_auditar_estado_paquete()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.estado IS DISTINCT FROM NEW.estado THEN
        INSERT INTO auditoria_estados_paquetes (paquete_id, estado_anterior, estado_nuevo)
        VALUES (NEW.id, OLD.estado, NEW.estado);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Definición del Trigger asociado a la tabla 'paquetes'
DROP TRIGGER IF EXISTS trg_auditoria_estado_paquete ON paquetes;

CREATE TRIGGER trg_auditoria_estado_paquete
AFTER UPDATE ON paquetes
FOR EACH ROW
EXECUTE FUNCTION fn_trg_auditar_estado_paquete();