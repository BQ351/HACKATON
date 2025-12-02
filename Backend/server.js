const express = require('express');
const cors = require('cors');
require('dotenv').config();

const pedidosRoutes = require('./routes/pedidos');

const app = express();
const PORT = process.env.PORT || 3000;

// Middlewares
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Rutas
app.use('/api/pedidos', pedidosRoutes);

// Ruta de prueba
app.get('/', (req, res) => {
    res.json({ 
        message: 'API de Pedidos funcionando correctamente',
        endpoints: {
            estadisticas: 'GET /api/pedidos/estadisticas',
            esperados: 'GET /api/pedidos/esperados',
            historial: 'GET /api/pedidos/historial',
            crear: 'POST /api/pedidos',
            notificar: 'PATCH /api/pedidos/:id/notificar',
            entregar: 'PATCH /api/pedidos/:id/entregar'
        }
    });
});

// Iniciar servidor
app.listen(PORT, () => {
    console.log(`🚀 Servidor corriendo en http://localhost:${PORT}`);
});