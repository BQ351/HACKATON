const Pedido = require('../models/pedido');

class PedidosController {
    // Obtener todos los pedidos esperados
    static async obtenerPedidosEsperados(req, res) {
        try {
            const pedidos = await Pedido.obtenerPedidosEsperados();
            res.status(200).json({
                success: true,
                data: pedidos
            });
        } catch (error) {
            console.error('Error al obtener pedidos:', error);
            res.status(500).json({
                success: false,
                message: 'Error al obtener los pedidos',
                error: error.message
            });
        }
    }

    // Obtener estadísticas
    static async obtenerEstadisticas(req, res) {
        try {
            const estadisticas = await Pedido.obtenerEstadisticas();
            res.status(200).json({
                success: true,
                data: {
                    pendientes: parseInt(estadisticas.pendientes) || 0,
                    llegados: parseInt(estadisticas.llegados) || 0,
                    entregados: parseInt(estadisticas.entregados) || 0,
                    hoy: parseInt(estadisticas.hoy) || 0
                }
            });
        } catch (error) {
            console.error('Error al obtener estadísticas:', error);
            res.status(500).json({
                success: false,
                message: 'Error al obtener estadísticas',
                error: error.message
            });
        }
    }

    // Crear nuevo pedido
    static async crearPedido(req, res) {
        try {
            const { usuario, numero_seguimiento, paqueteria } = req.body;

            // Validaciones
            if (!usuario || !numero_seguimiento || !paqueteria) {
                return res.status(400).json({
                    success: false,
                    message: 'Todos los campos son requeridos'
                });
            }

            const nuevoPedido = await Pedido.crearPedido({
                usuario,
                numero_seguimiento,
                paqueteria
            });

            res.status(201).json({
                success: true,
                message: 'Pedido creado exitosamente',
                data: nuevoPedido
            });
        } catch (error) {
            console.error('Error al crear pedido:', error);
            res.status(500).json({
                success: false,
                message: 'Error al crear el pedido',
                error: error.message
            });
        }
    }

    // Notificar al usuario
    static async notificarUsuario(req, res) {
        try {
            const { id } = req.params;
            const { hora_recogida, dia_recogida } = req.body;

            // Validaciones
            if (!hora_recogida || !dia_recogida) {
                return res.status(400).json({
                    success: false,
                    message: 'Hora y día de recogida son requeridos'
                });
            }

            // Verificar que el pedido existe
            const pedidoExistente = await Pedido.obtenerPorId(id);
            if (!pedidoExistente) {
                return res.status(404).json({
                    success: false,
                    message: 'Pedido no encontrado'
                });
            }

            const pedidoActualizado = await Pedido.notificarUsuario(id, {
                hora_recogida,
                dia_recogida
            });

            res.status(200).json({
                success: true,
                message: 'Usuario notificado exitosamente',
                data: pedidoActualizado
            });
        } catch (error) {
            console.error('Error al notificar usuario:', error);
            res.status(500).json({
                success: false,
                message: 'Error al notificar al usuario',
                error: error.message
            });
        }
    }

    // Marcar pedido como entregado
    static async marcarEntregado(req, res) {
        try {
            const { id } = req.params;

            // Verificar que el pedido existe
            const pedidoExistente = await Pedido.obtenerPorId(id);
            if (!pedidoExistente) {
                return res.status(404).json({
                    success: false,
                    message: 'Pedido no encontrado'
                });
            }

            const pedidoActualizado = await Pedido.marcarEntregado(id);

            res.status(200).json({
                success: true,
                message: 'Pedido marcado como entregado',
                data: pedidoActualizado
            });
        } catch (error) {
            console.error('Error al marcar pedido como entregado:', error);
            res.status(500).json({
                success: false,
                message: 'Error al actualizar el pedido',
                error: error.message
            });
        }
    }

    // Obtener historial
    static async obtenerHistorial(req, res) {
        try {
            const historial = await Pedido.obtenerHistorial();
            res.status(200).json({
                success: true,
                data: historial
            });
        } catch (error) {
            console.error('Error al obtener historial:', error);
            res.status(500).json({
                success: false,
                message: 'Error al obtener el historial',
                error: error.message
            });
        }
    }

    // Obtener pedido por ID
    static async obtenerPedidoPorId(req, res) {
        try {
            const { id } = req.params;
            const pedido = await Pedido.obtenerPorId(id);

            if (!pedido) {
                return res.status(404).json({
                    success: false,
                    message: 'Pedido no encontrado'
                });
            }

            res.status(200).json({
                success: true,
                data: pedido
            });
        } catch (error) {
            console.error('Error al obtener pedido:', error);
            res.status(500).json({
                success: false,
                message: 'Error al obtener el pedido',
                error: error.message
            });
        }
    }
}

module.exports = PedidosController;