# Gestión de Ventas y Proveedores - PC Tech

Este repositorio contiene procedimientos en PL/SQL para apoyar en la gestión de ventas y proveedores en la empresa PC Tech. Se incluyen funcionalidades para auditar las ventas por proveedor y producto, así como garantizar la consistencia de los totales de las boletas.

## Requerimientos Cubiertos

1. **Análisis de Ventas por Proveedor**:
   - Procedimientos para registrar auditorías de ventas por proveedor y producto.
   - Función para obtener el precio de un producto en base a la fecha de venta.
   
2. **Consistencia de Totales de Boletas**:
   - Procedimiento y trigger para actualizar automáticamente el total de la boleta cada vez que se inserte un producto en el detalle de la boleta.

## Estructura de Tablas

- **`AUDITORIA`**: Registra las ventas de productos por proveedor.
- **`ERRORES_PROCESO`**: Almacena los errores generados durante la ejecución de los procedimientos.
- **`BOLETA` y `BOLETA_PRODUCTO`**: Controlan las boletas de ventas y sus detalles.
