USE OficinaPaqueteria
GO
--===================================
--ATENCION !!! LEER LOS COMENTARIOS. GUIA BACICA PARA DESARROLLAR El BACKEND !!!! UCIEL LE ESTO PLIS PORFAVOR
--===================================


--------------------------------LIMPIEZA INICIAL----------------------------------
IF OBJECT_ID('dbo.TR_Delivery_Entrada_PorNombre', 'TR') IS NOT NULL DROP TRIGGER dbo.TR_Delivery_Entrada_PorNombre;
IF OBJECT_ID('dbo.TR_Delivery_Salida', 'TR') IS NOT NULL DROP TRIGGER dbo.TR_Delivery_Salida;
IF OBJECT_ID('dbo.DeliveryInStock', 'V') IS NOT NULL DROP VIEW dbo.DeliveryInStock;
IF OBJECT_ID('dbo.DeliveryOutStock', 'V') IS NOT NULL DROP VIEW dbo.DeliveryOutStock;
IF OBJECT_ID('dbo.VW_InfoUsuarioLogin', 'V') IS NOT NULL DROP VIEW dbo.VW_InfoUsuarioLogin;
IF OBJECT_ID('dbo.Delivery_Master', 'U') IS NOT NULL DROP TABLE dbo.Delivery_Master;
IF OBJECT_ID('dbo.UsuariosCliente', 'U') IS NOT NULL DROP TABLE dbo.UsuariosCliente;
IF OBJECT_ID('dbo.UsuariosAdmin', 'U') IS NOT NULL DROP TABLE dbo.UsuariosAdmin;
IF OBJECT_ID('dbo.sp_RegistrarUsuarioAdmin', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_RegistrarUsuarioAdmin;
IF OBJECT_ID('dbo.sp_RegistrarCliente_SignUp', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_RegistrarCliente_SignUp;
IF OBJECT_ID('dbo.sp_ValidarLogin', 'P') IS NOT NULL DROP PROCEDURE dbo.sp_ValidarLogin;
IF OBJECT_ID('dbo.Login', 'U') IS NOT NULL DROP TABLE dbo.Login;
GO

--------------------------------LOGIN----------------------------------
CREATE TABLE [dbo].[Login](
	LoginId int IDENTITY(1,1) NOT NULL,
	Usuario nvarchar(200) NOT NULL,
	[Password] nvarchar(max) NOT NULL,
	Rol varchar(20) NOT NULL CHECK (Rol IN ('ADMIN', 'CLIENTE')),
    CONSTRAINT [PK_Login] PRIMARY KEY CLUSTERED (LoginId ASC)
);
GO

-------------------INDICE PARA ACELERAR LA BUSQUEDA----------------------
CREATE UNIQUE INDEX IX_Login_Usuario ON [dbo].[Login](Usuario);
GO

---------------------------TABLA DE ADMINS-------------------------------
CREATE TABLE [dbo].[UsuariosAdmin](
	IdAdmin int IDENTITY(1,1) PRIMARY KEY,
	NombreReceptor varchar(250) NOT NULL,
	LoginId int UNIQUE,
    Activo bit DEFAULT 1,
	CONSTRAINT FK_Admin_Login FOREIGN KEY (LoginId) REFERENCES [dbo].[Login](LoginId)
);
GO

---------------------------TABLA DE CLIENTES--------------------------------
CREATE TABLE [dbo].[UsuariosCliente](
	Matricula int NOT NULL PRIMARY KEY,
	LoginId int UNIQUE,
	NombreDestinatario varchar(250) NOT NULL,
	Residencia varchar(50) CHECK (Residencia IN ('INTERNO','EXTERNO')),
	Telefono varchar(20),
	CONSTRAINT FK_Cliente_Login FOREIGN KEY (LoginId) REFERENCES [dbo].[Login](LoginId)
);
GO

----------------------VISTA DE LA INFO DEL USIARIO PARA LOGIN--------------------------
GO
CREATE VIEW [dbo].[VW_InfoUsuarioLogin] AS
SELECT
	L.LoginId,
	L.Usuario,
	L.[Password],
	L.Rol,
	------------------
	UA.IdAdmin,
	UA.NombreReceptor AS Nombre,
	UA.Activo,
	---------------
	UC.Matricula,
    UC.Residencia,
	COALESCE(UA.NombreReceptor, UC.NombreDestinatario) AS NombreCompleto
FROM [dbo].[Login] as L
LEFT JOIN [dbo].[UsuariosAdmin] UA ON L.LoginId = UA.LoginId AND L.Rol = 'ADMIN' 
LEFT JOIN [dbo].[UsuariosCliente] UC ON L.LoginId = UC.LoginId AND L.Rol = 'CLIENTE';
GO

-------------------PROCEDIMIENTO PARA INGRESAR NUEVO USUARIO ADMINISTRADOR----------------------
CREATE PROCEDURE [dbo].[sp_RegistrarUsuarioAdmin]
    @Usuario varchar(50),
    @Password nvarchar(max),
    @NombreCompleto varchar(250)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;

    BEGIN TRY
        -- 1. Crear Login (Forzamos ROL = ADMIN)
        INSERT INTO [dbo].[Login] (Usuario, Password, Rol)
        VALUES (@Usuario, @Password, 'ADMIN');

        -- 2. Obtener el ID generado
        DECLARE @NuevoLoginId int = SCOPE_IDENTITY();

        -- 3. Crear Perfil de Admin
        INSERT INTO [dbo].[UsuariosAdmin] (NombreReceptor, LoginId, Activo)
        VALUES (@NombreCompleto, @NuevoLoginId, 1); -- Activo por defecto

        COMMIT TRANSACTION;
        PRINT 'Administrador registrado con éxito.';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW; -- Re-lanzar el error para que la App sepa qué pasó
    END CATCH
END;
GO
-----------------PRECEDIMIENTO DE SING UP CLIENTES------------------------------
CREATE PROCEDURE [dbo].[sp_RegistrarCliente_SignUp]
    @Usuario varchar(50),
    @Password nvarchar(max),
    @NombreCompleto varchar(250),
    @Matricula int,
    @Telefono varchar(20)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validación previa: Verificar si la matrícula ya existe
    IF EXISTS (SELECT 1 FROM [dbo].[UsuariosCliente] WHERE Matricula = @Matricula)
    BEGIN
        RAISERROR('Error: Esta matrícula ya está registrada.', 16, 1);
        RETURN;
    END

    -- Validación previa: Verificar si el usuario ya existe
    IF EXISTS (SELECT 1 FROM [dbo].[Login] WHERE Usuario = @Usuario)
    BEGIN
        RAISERROR('Error: Este nombre de usuario ya está ocupado.', 16, 1);
        RETURN;
    END

    BEGIN TRANSACTION;

    BEGIN TRY
        -- 1. Crear Login (Forzamos ROL = CLIENTE)
        INSERT INTO [dbo].[Login] (Usuario, Password, Rol)
        VALUES (@Usuario, @Password, 'CLIENTE');

        -- 2. Obtener el ID generado
        DECLARE @NuevoLoginId int = SCOPE_IDENTITY();

        -- 3. Crear Perfil de Cliente
        INSERT INTO [dbo].[UsuariosCliente] (Matricula, NombreDestinatario, Residencia, Telefono, LoginId)
        VALUES (@Matricula, @NombreCompleto, 'INTERNO', @Telefono, @NuevoLoginId); 
        -- Nota: Asumimos 'INTERNO' por defecto en el registro web, 
        -- o podrías agregar @Residencia como parámetro si el formulario lo pide.

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-----------------PROCEDIMIENTO DE VALIDACION DE LOGIN---------------------------
CREATE OR ALTER PROCEDURE [dbo].[sp_ValidarLogin]
    @UsuarioInput varchar(50),
    @PasswordInput nvarchar(max)
AS
BEGIN
    SET NOCOUNT ON;

    -- Consultamos la vista que une todo
    SELECT 
        LoginId,
        Usuario,
        Rol,           -- IMPORTANTE: Tu App leerá esto para saber a dónde ir
        IdAdmin,
        Matricula,
        NombreCompleto, -- Ya viene limpio gracias al COALESCE
        Activo
    FROM [dbo].[VW_InfoUsuarioLogin]
    WHERE Usuario = @UsuarioInput 
      AND Password = @PasswordInput
      -- Regla de Seguridad: Si es Admin, debe estar Activo. 
      -- (Los clientes devuelven NULL en Activo, por eso el "OR IS NULL")
      AND (Activo = 1 OR Activo IS NULL);
END;
GO

-----------------TABLA MAESTRA DE ENTREGAS (Con los nuevos campos)---------------------
CREATE TABLE [dbo].[Delivery_Master](
	DeliveryID INT IDENTITY(1,1) PRIMARY KEY,
	NumDeGuia varchar(150) UNIQUE NOT NULL,
	Matricula int NOT NULL,
	Paqueteria varchar(100),
	NombreDelivery varchar(250), 
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
GO
CREATE VIEW [dbo].[DeliveryInStock] AS
SELECT
	dm.DeliveryID,
	dm.Matricula,
	uc.NombreDestinatario,
	dm.NumDeGuia,
	dm.Paqueteria,
    dm.NombreDelivery, 
    dm.Anaquel,        
    dm.Ubicacion,      
	dm.FechaEntrada,
	dm.IdAdmin
FROM [dbo].[Delivery_Master] as dm
INNER JOIN [dbo].[UsuariosCliente] AS uc ON dm.Matricula = uc.Matricula
WHERE dm.Estado = 'EN OFICINA';
GO

--------------VISTA DE HISTORIAL DE SALIDAS (Opcional, pero útil)--------------------
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
    dm.FechaEntrega,   
	dm.IdAdmin
FROM [dbo].[Delivery_Master] as dm
INNER JOIN [dbo].[UsuariosCliente] AS uc ON dm.Matricula = uc.Matricula
WHERE dm.Estado = 'ENTREGADO'; --Vara ver el Historial de Paqueteria Entregada
GO

--------------------TRIGGER DE SALIDA (Soft Delete)-------------------
GO
CREATE TRIGGER [dbo].[TR_Delivery_Salida]
ON [dbo].[DeliveryInStock]
INSTEAD OF DELETE
AS
BEGIN
	SET NOCOUNT ON;
	UPDATE [dbo].[Delivery_Master]
	SET Estado = 'ENTREGADO', FechaEntrega = GETDATE()
	FROM [dbo].[Delivery_Master] as m
	INNER JOIN deleted as d ON m.DeliveryID = d.DeliveryID;
END;
GO

----------------TRIGGER DE ENTRADA INTELIGENTE (Actualizado al Formulario)---------------
GO
CREATE TRIGGER [dbo].[TR_Delivery_Entrada_PorNombre]
ON [dbo].[DeliveryInStock]
INSTEAD OF INSERT
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @NombreBusqueda varchar(250);
    DECLARE @MatriculaEncontrada int;
    
    DECLARE @NumDeGuia varchar(150);
    DECLARE @Paqueteria varchar(100);
    DECLARE @NombreProveedor varchar(250);
    DECLARE @Anaquel varchar(50);
    DECLARE @Ubicacion varchar(150);
    DECLARE @IdAdmin int;
    DECLARE @FechaRecibido datetime;
    
	SELECT 
        @NombreBusqueda = NombreDestinatario,
        @NumDeGuia = NumDeGuia,
        @Paqueteria = Paqueteria,
        @NombreProveedor = NombreDelivery, 
        @Anaquel = Anaquel,
        @Ubicacion = Ubicacion,
        @IdAdmin = IdAdmin,                
        @FechaRecibido = FechaEntrada      
    FROM inserted;

	SELECT @MatriculaEncontrada = Matricula
	FROM [dbo].[UsuariosCliente]
	WHERE NombreDestinatario = @NombreBusqueda;

	IF @MatriculaEncontrada IS NOT NULL
	BEGIN
		INSERT INTO [dbo].[Delivery_Master](
			NumDeGuia, Matricula, Paqueteria, NombreDelivery, 
            Anaquel, Ubicacion, IdAdmin, FechaEntrada)
		VALUES (
			@NumDeGuia, @MatriculaEncontrada, @Paqueteria, @NombreProveedor, 
            @Anaquel, @Ubicacion, @IdAdmin, ISNULL(@FechaRecibido, GETDATE())
        );
	END
	ELSE
	BEGIN
		RAISERROR ('Error: El usuario "%s" no está registrado.', 16, 1, @NombreBusqueda);
    END
END;
GO

------------------------------Insercion de Datos para Simulación------------------------------
EXEC sp_RegistrarUsuarioAdmin 
    @Usuario = 'admin_nuevo', 
    @Password = 'seguridad123', 
    @NombreCompleto = 'Lic. Nuevo Administrador';


EXEC sp_RegistrarCliente_SignUp 
    @Usuario = 'alumno2020', 
    @Password = 'pass_alumno', 
    @NombreCompleto = 'Juanito Alumno', 
    @Matricula = 1200351, 
    @Telefono = '826-123-0000';


INSERT INTO DeliveryInStock 
(FechaEntrada, Paqueteria, NumDeGuia, NombreDestinatario, IdAdmin, NombreDelivery, Anaquel, Ubicacion)
VALUES 
(GETDATE(), 'Amazon', 'AMZN-998877', 'Juanito Alumno', 1, 'Logistics AMZ', 'A1', 'Recepción Central');

INSERT INTO DeliveryInStock 
(FechaEntrada, Paqueteria, NumDeGuia, NombreDestinatario, IdAdmin, NombreDelivery, Anaquel, Ubicacion)
VALUES 
(GETDATE(), 'DHL', 'DHL-123456789', 'Juanito Alumno', 1, 'Repartidor José', 'B3', 'Bodega Externa');

INSERT INTO DeliveryInStock 
(Paqueteria, NumDeGuia, NombreDestinatario, IdAdmin, NombreDelivery, Anaquel, Ubicacion)
VALUES 
('Mercado Libre', 'ML-MX-555666', 'Juanito Alumno', 1, 'Repartidor ML', 'C2', 'Estante Pequeños');

INSERT INTO DeliveryInStock 
(FechaEntrada, Paqueteria, NumDeGuia, NombreDestinatario, IdAdmin, NombreDelivery, Anaquel, Ubicacion)
VALUES 
(GETDATE(), 'FedEx', 'FDX-000111222', 'Juanito Alumno', 1, 'Camión 45', 'A2', 'Recepción Central');
GO

------------------Vista de Tablas Usuario--------------------------
SELECT * FROM dbo.UsuariosAdmin;
SELECT * FROM dbo.UsuariosCliente;

----------------------Vista de los Datos Existentes------------------------
SELECT * FROM VW_InfoUsuarioLogin;
SELECT * FROM DeliveryInStock;

--------------------------BUSQUEDA DE PAQUETE-----------------------------------
SELECT NombreDestinatario, NumDeGuia, Paqueteria, Anaquel, Ubicacion 
FROM DeliveryInStock 
WHERE Matricula = 123003;

---------------------------------SALIDA---------------------------------------
DELETE FROM DeliveryInStock WHERE NumDeGuia = 'DHL-123456789';
DELETE FROM DeliveryInStock WHERE Matricula = 1200351;

SELECT * FROM DeliveryOutStock;

---------------------------------------------------------------------------------
EXEC sp_RegistrarUsuarioAdmin 'admin_test', '123', 'Admin de Prueba';
EXEC sp_RegistrarCliente_SignUp 'cliente_test', '123', 'Cliente de Prueba', 999001, '555-000-0000';
GO
-------------------------------------------------------------------------------------
-- Debería devolver 1 fila con ROL = 'ADMIN' e IdAdmin lleno
EXEC sp_ValidarLogin 'admin_test', '123';
-- Debería devolver 1 fila con ROL = 'CLIENTE' y Matricula llena
EXEC sp_ValidarLogin 'cliente_test', '123';
-- Debería devolver UNA TABLA VACÍA (0 filas)
EXEC sp_ValidarLogin 'admin_test', 'pass_falso'; --El login falla por datos falsos

