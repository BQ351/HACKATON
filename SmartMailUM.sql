USE OficinaPaqueteria
GO

---------------------------TABLA DE ADMINS-------------------------------
IF OBJECT_ID('dbo.UsuariosAdmin', 'U') IS NOT NULL DROP TABLE dbo.UsuariosAdmin;
CREATE TABLE [dbo].[UsuariosAdmin](
	IdAdmin int IDENTITY(1,1) PRIMARY KEY,
	NombreReceptor varchar(250) NOT NULL,
    Activo bit DEFAULT 1
);

---------------------------TABLA DE CLIENTES--------------------------------
IF OBJECT_ID('dbo.UsuariosCliente', 'U') IS NOT NULL DROP TABLE dbo.UsuariosCliente;
CREATE TABLE [dbo].[UsuariosCliente](
	Matricula int NOT NULL PRIMARY KEY,
	NombreDestinatario varchar(250) NOT NULL,
	Residencia varchar(50) CHECK (Residencia IN ('INTERNO','EXTERNO')),
	Telefono varchar(20)
);

-----------------TABLA MAESTRA DE ENTREGAS (Con los nuevos campos)---------------------
IF OBJECT_ID('dbo.Delivery_Master', 'U') IS NOT NULL DROP TABLE dbo.Delivery_Master;
CREATE TABLE [dbo].[Delivery_Master](
	DeliveryID INT IDENTITY(1,1) PRIMARY KEY,
	NumDeGuia varchar(150) UNIQUE NOT NULL,
	Matricula int NOT NULL,
	Paqueteria varchar(100),
	NombreDelivery varchar(250), -- Aquí guardaremos el "Proveedor" o "Remitente"
	
    -- Facilidades de almacenamiento
    Anaquel varchar(50),
    Ubicacion varchar(150),
    
    IdAdmin int NOT NULL,
	FechaEntrada DATETIME DEFAULT GETDATE(),
	FechaEntrega DATETIME NULL,
	Estado varchar(50) DEFAULT 'EN OFICINA' CHECK (Estado IN ('EN OFICINA', 'ENTREGADO')),
	
    CONSTRAINT FK_Matricula_UC FOREIGN KEY (Matricula) REFERENCES [dbo].[UsuariosCliente](Matricula),
	CONSTRAINT FK_IdAdmin_UA FOREIGN KEY (IdAdmin) REFERENCES [dbo].[UsuariosAdmin](IdAdmin)
);
GO

---------------VISTA DE PAQUETES EN STOCK (Corregida)----------------------
IF OBJECT_ID('dbo.DeliveryInStock', 'V') IS NOT NULL DROP VIEW dbo.DeliveryInStock;
GO
CREATE VIEW [dbo].[DeliveryInStock] AS
SELECT
	dm.DeliveryID,
	dm.Matricula,
	uc.NombreDestinatario,
	dm.NumDeGuia,
	dm.Paqueteria,
    dm.NombreDelivery, -- Proveedor
    dm.Anaquel,        -- Nuevo
    dm.Ubicacion,      -- Nuevo
	dm.FechaEntrada,
	dm.IdAdmin
FROM [dbo].[Delivery_Master] as dm
INNER JOIN [dbo].[UsuariosCliente] AS uc -- Corregido: antes decías 'AS us' pero usabas 'uc'
	ON dm.Matricula = uc.Matricula
WHERE dm.Estado = 'EN OFICINA';
GO

--------------VISTA DE HISTORIAL DE SALIDAS (Opcional, pero útil)--------------------
IF OBJECT_ID('dbo.DeliveryOutStock', 'V') IS NOT NULL DROP VIEW dbo.DeliveryOutStock;
GO
CREATE VIEW [dbo].[DeliveryOutStock] AS
SELECT
	dm.DeliveryID,
	dm.Matricula,
	uc.NombreDestinatario,
	dm.NumDeGuia,
	dm.Paqueteria,
    dm.NombreDelivery,
	dm.FechaEntrada,
    dm.FechaEntrega,   -- Importante ver cuándo salió
	dm.IdAdmin
FROM [dbo].[Delivery_Master] as dm
INNER JOIN [dbo].[UsuariosCliente] AS uc
	ON dm.Matricula = uc.Matricula
WHERE dm.Estado = 'ENTREGADO';
GO

--------------------TRIGGER DE SALIDA (Soft Delete)-------------------
CREATE TRIGGER [dbo].[TR_Delivery_Salida]
ON [dbo].[DeliveryInStock]
INSTEAD OF DELETE
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE [dbo].[Delivery_Master]
	SET
		Estado = 'ENTREGADO',
		FechaEntrega = GETDATE()
	FROM [dbo].[Delivery_Master] as m
	INNER JOIN deleted as d ON m.DeliveryID = d.DeliveryID;
END;
GO

----------------TRIGGER DE ENTRADA INTELIGENTE (Actualizado al Formulario)---------------
CREATE TRIGGER [dbo].[TR_Delivery_Entrada_PorNombre]
ON [dbo].[DeliveryInStock]
INSTEAD OF INSERT
AS
BEGIN
	SET NOCOUNT ON;

    -- Variables para recibir datos del formulario
	DECLARE @NombreBusqueda varchar(250);
    DECLARE @MatriculaEncontrada int;
    
    -- Variables mapeadas a la tabla
    DECLARE @NumDeGuia varchar(150);
    DECLARE @Paqueteria varchar(100);
    DECLARE @NombreProveedor varchar(250);
    DECLARE @Anaquel varchar(50);
    DECLARE @Ubicacion varchar(150);
    DECLARE @IdAdmin int;
    DECLARE @FechaRecibido datetime;
    
    -- Leemos los datos que envía la App/Web
	SELECT 
        @NombreBusqueda = NombreDestinatario,
        @NumDeGuia = NumDeGuia,
        @Paqueteria = Paqueteria,
        @NombreProveedor = NombreDelivery, -- "Nombre de Proveedor" en el form
        @Anaquel = Anaquel,
        @Ubicacion = Ubicacion,
        @IdAdmin = IdAdmin,                -- "Id" en el form
        @FechaRecibido = FechaEntrada      -- "Fecha Recibido" en el form
    FROM inserted;

    -- Buscamos la matrícula
	SELECT @MatriculaEncontrada = Matricula
	FROM [dbo].[UsuariosCliente]
	WHERE NombreDestinatario = @NombreBusqueda;

	IF @MatriculaEncontrada IS NOT NULL
	BEGIN
		-- Insertamos todo en la Maestra
		INSERT INTO [dbo].[Delivery_Master](
			NumDeGuia,
			Matricula,
			Paqueteria,
            NombreDelivery, 
            Anaquel,
            Ubicacion,
            IdAdmin,
            FechaEntrada    -- Usamos la fecha del form o la actual si viene nula
		)
		VALUES (
			@NumDeGuia,
			@MatriculaEncontrada,
			@Paqueteria,
            @NombreProveedor,
            @Anaquel,
            @Ubicacion,
            @IdAdmin,
            ISNULL(@FechaRecibido, GETDATE())
        );
	END
	ELSE
	BEGIN
        -- Mensaje de error formateado
		RAISERROR ('Error: El usuario "%s" no está registrado. Por favor verifique el nombre o regístrelo primero.', 16, 1, @NombreBusqueda);
    END
END;

GO

------------------------------Insercion de Datos para Simulación------------------------------
INSERT INTO UsuariosAdmin (NombreReceptor, Activo)
VALUES 
('Bequer Quiroga', 1),  -- Tendrá IdAdmin = 1
('María González', 1),  -- Tendrá IdAdmin = 2
('Roberto Admin', 1);   -- Tendrá IdAdmin = 3
GO

INSERT INTO UsuariosCliente (Matricula, NombreDestinatario, Residencia, Telefono)
VALUES 
(123001, 'Ana López', 'INTERNO', '811-111-2222'),
(123002, 'Carlos Ruiz', 'EXTERNO', '811-333-4444'),
(123003, 'Diana Prince', 'INTERNO', '811-555-6666'),
(123004, 'Bruce Wayne', 'EXTERNO', '811-777-8888'),
(123005, 'Clark Kent', 'INTERNO', '811-999-0000');
GO

------------------------------------------------------------------------------------------------------
INSERT INTO DeliveryInStock 
(FechaEntrada, Paqueteria, NumDeGuia, NombreDestinatario, IdAdmin, NombreDelivery, Anaquel, Ubicacion)
VALUES 
(GETDATE(), 'Amazon', 'AMZN-998877', 'Ana López', 1, 'Logistics AMZ', 'A1', 'Recepción Central');

INSERT INTO DeliveryInStock 
(FechaEntrada, Paqueteria, NumDeGuia, NombreDestinatario, IdAdmin, NombreDelivery, Anaquel, Ubicacion)
VALUES 
(GETDATE(), 'DHL', 'DHL-123456789', 'Carlos Ruiz', 2, 'Repartidor José', 'B3', 'Bodega Externa');

INSERT INTO DeliveryInStock 
(Paqueteria, NumDeGuia, NombreDestinatario, IdAdmin, NombreDelivery, Anaquel, Ubicacion)
VALUES 
('Mercado Libre', 'ML-MX-555666', 'Diana Prince', 1, 'Repartidor ML', 'C2', 'Estante Pequeños');

INSERT INTO DeliveryInStock 
(FechaEntrada, Paqueteria, NumDeGuia, NombreDestinatario, IdAdmin, NombreDelivery, Anaquel, Ubicacion)
VALUES 
(GETDATE(), 'FedEx', 'FDX-000111222', 'Bruce Wayne', 3, 'Camión 45', 'A2', 'Recepción Central');

GO

----------------------Vista de los Datos Existentes------------------------

SELECT * FROM UsuariosAdmin;
SELECT * FROM UsuariosCliente;
SELECT * FROM Delivery_Master;
SELECT * FROM DeliveryInStock;

--------------------------BUSQUEDA DE PAQUETE-----------------------------------

SELECT NombreDestinatario, NumDeGuia, Paqueteria, Anaquel, Ubicacion FROM DeliveryInStock 
WHERE Matricula = 123003
SELECT * FROM Delivery_Master;
SELECT * FROM DeliveryInStock;

---------------------------------SALIDA---------------------------------------

DELETE FROM DeliveryInStock 
WHERE NumDeGuia = 'DHL-123456789';
GO

DELETE FROM DeliveryInStock 
WHERE Matricula = 123003;
GO

SELECT * FROM DeliveryOutStock
