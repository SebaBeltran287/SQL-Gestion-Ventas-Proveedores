-- -----------------------------------------------
-- Integrantes del trabajo grupal: 
--             Integrante (nombre apellido) 1
--             Integrante (nombre apellido) 2
--             Integrante (nombre apellido) 3
--             Integrante (nombre apellido) 4
-- -----------------------------------------------

-- Requerimiento 1: Crear la tabla AUDITORIA para registrar las ventas por proveedor y producto
CREATE TABLE AUDITORIA (
    id_auditoria NUMBER PRIMARY KEY,
    id_proveedor NUMBER,
    nombre_proveedor VARCHAR2(100),
    id_producto NUMBER,
    cantidad_ventas NUMBER,
    monto_ventas NUMBER(10,2)
);

-- Tabla para registrar errores durante los procesos
CREATE TABLE ERRORES_PROCESO (
    id_error NUMBER PRIMARY KEY,
    codigo VARCHAR2(50),
    descripcion VARCHAR2(255)
);

-- Crear las secuencias necesarias para las claves primarias
CREATE SEQUENCE SEQ_AUDITORIA;
CREATE SEQUENCE SEQ_ERRORES_PROCESO;

-- -----------------------------------------------
-- Función para obtener el precio de un producto según la fecha de venta
-- Objetivo del Procedimiento:
-- 		Esta función devuelve el precio del producto en base a la fecha de la venta.
CREATE OR REPLACE FUNCTION fn_obtener_precio_producto (
    p_id_producto IN NUMBER, 
    p_fecha_venta IN DATE
) RETURN NUMBER IS
    v_precio NUMBER;
BEGIN
    -- Obtener el precio del producto en la fecha de la venta
    SELECT precio INTO v_precio 
    FROM PRODUCTO_PRECIO 
    WHERE id_producto = p_id_producto
      AND fecha_inicio <= p_fecha_venta
      AND (fecha_fin IS NULL OR fecha_fin >= p_fecha_venta)
    ORDER BY fecha_inicio DESC
    FETCH FIRST ROW ONLY;
    
    RETURN v_precio;

EXCEPTION
    WHEN OTHERS THEN
        -- Manejo de errores: Registrar en la tabla ERRORES_PROCESO
        INSERT INTO ERRORES_PROCESO (id_error, codigo, descripcion)
        VALUES (SEQ_ERRORES_PROCESO.NEXTVAL, SQLCODE, SQLERRM);
        ROLLBACK;
        RETURN NULL;
END;
/

-- -----------------------------------------------
-- Procedimiento para insertar registros en la tabla AUDITORIA
-- Objetivo del Procedimiento:
-- 		Este procedimiento agrega registros a la tabla de auditoría con el análisis de ventas.
CREATE OR REPLACE PROCEDURE sp_insertar_auditoria (
    p_id_proveedor IN NUMBER,
    p_nombre_proveedor IN VARCHAR2,
    p_id_producto IN NUMBER,
    p_cantidad_ventas IN NUMBER,
    p_fecha_venta IN DATE
) AS
    v_monto_ventas NUMBER;
    v_precio_producto NUMBER;
BEGIN
    -- Obtener el precio del producto según la fecha de venta
    v_precio_producto := fn_obtener_precio_producto(p_id_producto, p_fecha_venta);
    IF v_precio_producto IS NULL THEN
        RAISE_APPLICATION_ERROR(-20001, 'Error al obtener el precio del producto');
    END IF;

    -- Calcular el monto total de ventas
    v_monto_ventas := v_precio_producto * p_cantidad_ventas;

    -- Insertar los datos en la tabla AUDITORIA
    INSERT INTO AUDITORIA (id_auditoria, id_proveedor, nombre_proveedor, id_producto, cantidad_ventas, monto_ventas)
    VALUES (SEQ_AUDITORIA.NEXTVAL, p_id_proveedor, p_nombre_proveedor, p_id_producto, p_cantidad_ventas, v_monto_ventas);

    -- Confirmar la transacción
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        -- Registrar errores en la tabla ERRORES_PROCESO
        INSERT INTO ERRORES_PROCESO (id_error, codigo, descripcion)
        VALUES (SEQ_ERRORES_PROCESO.NEXTVAL, SQLCODE, SQLERRM);
        ROLLBACK;
END;
/

-- -----------------------------------------------
-- Requerimiento 2: Procedimiento para actualizar el total de la boleta
-- Objetivo del Procedimiento:
-- 		Actualizar el total de la boleta cada vez que se inserte un producto en BOLETA_PRODUCTO.
CREATE OR REPLACE PROCEDURE sp_actualizar_total_boleta (
    p_id_boleta IN NUMBER
) AS
    v_total_boleta NUMBER;
BEGIN
    -- Calcular el total de la boleta sumando los montos de los productos
    SELECT SUM(bp.precio_producto * bp.cantidad)
    INTO v_total_boleta
    FROM BOLETA_PRODUCTO bp
    WHERE bp.id_boleta = p_id_boleta;

    -- Actualizar el total de la boleta en la tabla BOLETA
    UPDATE BOLETA
    SET total = v_total_boleta
    WHERE id_boleta = p_id_boleta;

    -- Confirmar la transacción
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        -- Registrar errores en la tabla ERRORES_PROCESO
        INSERT INTO ERRORES_PROCESO (id_error, codigo, descripcion)
        VALUES (SEQ_ERRORES_PROCESO.NEXTVAL, SQLCODE, SQLERRM);
        ROLLBACK;
END;
/

-- -----------------------------------------------
-- Trigger para actualizar automáticamente el total de la boleta cuando se inserta un producto
-- Objetivo del Trigger:
-- 		Este trigger actualiza automáticamente el total de la boleta al agregar un producto.
CREATE OR REPLACE TRIGGER trg_actualizar_total_boleta
AFTER INSERT ON BOLETA_PRODUCTO
FOR EACH ROW
BEGIN
    -- Llamar al procedimiento para actualizar el total de la boleta
    sp_actualizar_total_boleta(:NEW.id_boleta);
END;
/
