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