const express = require('express');
const router = express.Router();
const PedidosController = require('../controllers/pedidosController');

// Rutas de pedidos

// GET - Obtener estadísticas
router.get('/estadisticas', PedidosController.obtenerEstadisticas);

// GET - Obtener todos los pedidos esperados
router.get('/esperados', PedidosController.obtenerPedidosEsperados);

// GET - Obtener historial de pedidos
router.get('/historial', PedidosController.obtenerHistorial);

// GET - Obtener un pedido por ID
router.get('/:id', PedidosController.obtenerPedidoPorId);

// POST - Crear nuevo pedido
router.post('/', PedidosController.crearPedido);

// PATCH - Notificar al usuario (actualizar con hora y día)
router.patch('/:id/notificar', PedidosController.notificarUsuario);

// PATCH - Marcar pedido como entregado
router.patch('/:id/entregar', PedidosController.marcarEntregado);

module.exports = router;