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