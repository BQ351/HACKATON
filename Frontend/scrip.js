// Array para almacenar los pedidos temporalmente (sin base de datos)
let pedidos = [
    {
        id: 1,
        usuario: "Juan Pérez",
        numero_seguimiento: "DHL123456789",
        paqueteria: "DHL",
        fecha_registro: "2025-01-28",
        estado: "pendiente",
        hora_recogida: null,
        dia_recogida: null
    },
    {
        id: 2,
        usuario: "María García",
        numero_seguimiento: "FEDEX987654321",
        paqueteria: "FedEx",
        fecha_registro: "2025-01-27",
        estado: "pendiente",
        hora_recogida: null,
        dia_recogida: null
    },
    {
        id: 3,
        usuario: "Carlos López",
        numero_seguimiento: "UPS456789123",
        paqueteria: "UPS",
        fecha_registro: "2025-01-26",
        estado: "llegado",
        hora_recogida: "14:00",
        dia_recogida: "2025-01-29"
    },
    {
        id: 4,
        usuario: "Ana Martínez",
        numero_seguimiento: "ESTAFETA789456123",
        paqueteria: "Estafeta",
        fecha_registro: "2025-01-28",
        estado: "pendiente",
        hora_recogida: null,
        dia_recogida: null
    }
];

let pedidoIdCounter = 5;

// Función para cargar pedidos al inicio
document.addEventListener('DOMContentLoaded', function() {
    cargarPedidos();
    actualizarEstadisticas();
    establecerFechaActual();
});

// Establecer fecha actual en el formulario
function establecerFechaActual() {
    const fechaInput = document.getElementById('fecha');
    const hoy = new Date().toISOString().split('T')[0];
    fechaInput.value = hoy;
}

// Cargar y mostrar pedidos en la tabla
function cargarPedidos() {
    const tbody = document.getElementById('tabla-pedidos');
    tbody.innerHTML = '';

    if (pedidos.length === 0) {
        tbody.innerHTML = `
            <tr>
                <td colspan="6" style="text-align: center; padding: 40px;">
                    <i class="fas fa-inbox" style="font-size: 48px; color: #ccc;"></i>
                    <p style="margin-top: 10px; color: #999;">No hay pedidos registrados</p>
                </td>
            </tr>
        `;
        return;
    }

    pedidos.forEach(pedido => {
        const tr = document.createElement('tr');
        
        let estadoClass = '';
        let estadoTexto = '';
        
        switch(pedido.estado) {
            case 'pendiente':
                estadoClass = 'estado-pendiente';
                estadoTexto = '<i class="fas fa-clock"></i> Pendiente';
                break;
            case 'llegado':
                estadoClass = 'estado-llegado';
                estadoTexto = '<i class="fas fa-check-circle"></i> Llegado';
                break;
            case 'entregado':
                estadoClass = 'estado-entregado';
                estadoTexto = '<i class="fas fa-truck"></i> Entregado';
                break;
        }

        tr.innerHTML = `
            <td>${pedido.usuario}</td>
            <td><strong>${pedido.numero_seguimiento}</strong></td>
            <td><span class="badge badge-paqueteria">${pedido.paqueteria}</span></td>
            <td>${formatearFecha(pedido.fecha_registro)}</td>
            <td><span class="estado ${estadoClass}">${estadoTexto}</span></td>
            <td>
                <div class="action-buttons">
                    ${pedido.estado === 'pendiente' ? `
                        <button class="btn-action btn-notificar" onclick="abrirModalNotificar(${pedido.id})" title="Notificar">
                            <i class="fas fa-bell"></i>
                        </button>
                    ` : ''}
                    ${pedido.estado === 'llegado' ? `
                        <button class="btn-action btn-entregar" onclick="marcarEntregado(${pedido.id})" title="Marcar como entregado">
                            <i class="fas fa-truck"></i>
                        </button>
                    ` : ''}
                    <button class="btn-action btn-ver" onclick="verDetalle(${pedido.id})" title="Ver detalle">
                        <i class="fas fa-eye"></i>
                    </button>
                    <button class="btn-action btn-eliminar" onclick="eliminarPedido(${pedido.id})" title="Eliminar">
                        <i class="fas fa-trash"></i>
                    </button>
                </div>
            </td>
        `;
        
        tbody.appendChild(tr);
    });

    document.getElementById('pedidos-mostrados').textContent = pedidos.length;
    document.getElementById('pedidos-totales').textContent = pedidos.length;
}

// Formatear fecha
function formatearFecha(fecha) {
    const date = new Date(fecha + 'T00:00:00');
    const opciones = { year: 'numeric', month: 'short', day: 'numeric' };
    return date.toLocaleDateString('es-ES', opciones);
}

// Actualizar estadísticas
function actualizarEstadisticas() {
    const pendientes = pedidos.filter(p => p.estado === 'pendiente').length;
    const llegados = pedidos.filter(p => p.estado === 'llegado').length;
    const entregados = pedidos.filter(p => p.estado === 'entregado').length;
    
    const hoy = new Date().toISOString().split('T')[0];
    const pedidosHoy = pedidos.filter(p => p.fecha_registro === hoy).length;

    document.getElementById('total-pendientes').textContent = pendientes;
    document.getElementById('total-llegados').textContent = llegados;
    document.getElementById('total-entregados').textContent = entregados;
    document.getElementById('total-hoy').textContent = pedidosHoy;
}

// Abrir modal para agregar pedido
function abrirModal() {
    document.getElementById('modal').classList.add('active');
    document.getElementById('form-pedido').reset();
    establecerFechaActual();
}

// Cerrar modal
function cerrarModal() {
    document.getElementById('modal').classList.remove('active');
}

// Guardar pedido
function guardarPedido() {
    const usuario = document.getElementById('usuario').value.trim();
    const numero_seguimiento = document.getElementById('guia').value.trim();
    const paqueteria = document.getElementById('paqueteria').value;
    const fecha_registro = document.getElementById('fecha').value;

    if (!usuario || !numero_seguimiento || !paqueteria || !fecha_registro) {
        mostrarToast('Por favor, completa todos los campos', 'error');
        return;
    }

    const existente = pedidos.find(p => p.numero_seguimiento === numero_seguimiento);
    if (existente) {
        mostrarToast('Este número de seguimiento ya está registrado', 'error');
        return;
    }

    const nuevoPedido = {
        id: pedidoIdCounter++,
        usuario: usuario,
        numero_seguimiento: numero_seguimiento,
        paqueteria: paqueteria,
        fecha_registro: fecha_registro,
        estado: 'pendiente',
        hora_recogida: null,
        dia_recogida: null
    };

    pedidos.unshift(nuevoPedido);

    cargarPedidos();
    actualizarEstadisticas();
    cerrarModal();
    
    mostrarToast('Pedido agregado exitosamente', 'success');
}

// Abrir modal para notificar
function abrirModalNotificar(id) {
    const pedido = pedidos.find(p => p.id === id);
    if (!pedido) return;

    const modalHTML = `
        <div id="modal-notificar" class="modal active">
            <div class="modal-contenido">
                <div class="modal-header">
                    <h3><i class="fas fa-bell"></i> Notificar a Usuario</h3>
                    <button class="btn-cerrar-modal" onclick="cerrarModalNotificar()">&times;</button>
                </div>
                
                <div class="pedido-info">
                    <p><strong>Usuario:</strong> ${pedido.usuario}</p>
                    <p><strong>No. Seguimiento:</strong> ${pedido.numero_seguimiento}</p>
                    <p><strong>Paquetería:</strong> ${pedido.paqueteria}</p>
                </div>

                <form id="form-notificar">
                    <div class="form-group">
                        <label for="dia-recogida"><i class="fas fa-calendar"></i> Día de Recogida:</label>
                        <input type="date" id="dia-recogida" required>
                    </div>
                    
                    <div class="form-group">
                        <label for="hora-recogida"><i class="fas fa-clock"></i> Hora de Recogida:</label>
                        <input type="time" id="hora-recogida" required>
                    </div>
                    
                    <div class="modal-actions">
                        <button type="button" onclick="enviarNotificacion(${id})" class="btn-guardar">
                            <i class="fas fa-paper-plane"></i> Enviar Notificación
                        </button>
                        <button type="button" onclick="cerrarModalNotificar()" class="btn-cancelar">
                            <i class="fas fa-times"></i> Cancelar
                        </button>
                    </div>
                </form>
            </div>
        </div>
    `;

    const modalExistente = document.getElementById('modal-notificar');
    if (modalExistente) {
        modalExistente.remove();
    }
    document.body.insertAdjacentHTML('beforeend', modalHTML);

    const hoy = new Date().toISOString().split('T')[0];
    document.getElementById('dia-recogida').min = hoy;
    document.getElementById('dia-recogida').value = hoy;
}

// Cerrar modal de notificación
function cerrarModalNotificar() {
    const modal = document.getElementById('modal-notificar');
    if (modal) {
        modal.remove();
    }
}

// Enviar notificación
function enviarNotificacion(id) {
    const dia_recogida = document.getElementById('dia-recogida').value;
    const hora_recogida = document.getElementById('hora-recogida').value;

    if (!dia_recogida || !hora_recogida) {
        mostrarToast('Por favor, completa todos los campos', 'error');
        return;
    }

    const pedido = pedidos.find(p => p.id === id);
    if (pedido) {
        pedido.estado = 'llegado';
        pedido.dia_recogida = dia_recogida;
        pedido.hora_recogida = hora_recogida;

        cargarPedidos();
        actualizarEstadisticas();
        cerrarModalNotificar();

        mostrarToast(`Notificación enviada a ${pedido.usuario}`, 'success');
    }
}

// Marcar como entregado
function marcarEntregado(id) {
    const pedido = pedidos.find(p => p.id === id);
    if (!pedido) return;

    if (confirm(`¿Marcar el pedido de ${pedido.usuario} como entregado?`)) {
        pedido.estado = 'entregado';
        cargarPedidos();
        actualizarEstadisticas();
        mostrarToast('Pedido marcado como entregado', 'success');
    }
}

// Ver detalle del pedido
function verDetalle(id) {
    const pedido = pedidos.find(p => p.id === id);
    if (!pedido) return;

    let detalleHTML = `
Usuario: ${pedido.usuario}
No. Seguimiento: ${pedido.numero_seguimiento}
Paquetería: ${pedido.paqueteria}
Fecha Registro: ${formatearFecha(pedido.fecha_registro)}
Estado: ${pedido.estado}`;

    if (pedido.estado === 'llegado' || pedido.estado === 'entregado') {
        detalleHTML += `
Día de Recogida: ${formatearFecha(pedido.dia_recogida)}
Hora de Recogida: ${pedido.hora_recogida}`;
    }

    alert(detalleHTML);
}

// Eliminar pedido
function eliminarPedido(id) {
    const pedido = pedidos.find(p => p.id === id);
    if (!pedido) return;

    if (confirm(`¿Estás seguro de eliminar el pedido de ${pedido.usuario}?`)) {
        const index = pedidos.findIndex(p => p.id === id);
        pedidos.splice(index, 1);
        
        cargarPedidos();
        actualizarEstadisticas();
        mostrarToast('Pedido eliminado', 'success');
    }
}

// Mostrar toast de notificación
function mostrarToast(mensaje, tipo = 'info') {
    const toast = document.getElementById('toast');
    toast.textContent = mensaje;
    toast.className = `toast ${tipo}`;
    toast.classList.add('show');

    setTimeout(() => {
        toast.classList.remove('show');
    }, 3000);
}

// Búsqueda de pedidos
document.getElementById('buscar-pedido')?.addEventListener('input', function(e) {
    const busqueda = e.target.value.toLowerCase();
    const filas = document.querySelectorAll('#tabla-pedidos tr');

    filas.forEach(fila => {
        const texto = fila.textContent.toLowerCase();
        if (texto.includes(busqueda)) {
            fila.style.display = '';
        } else {
            fila.style.display = 'none';
        }
    });
});

// Cerrar modal al hacer clic fuera
window.onclick = function(event) {
    const modal = document.getElementById('modal');
    if (event.target === modal) {
        cerrarModal();
    }
    
    const modalNotificar = document.getElementById('modal-notificar');
    if (event.target === modalNotificar) {
        cerrarModalNotificar();
    }
}