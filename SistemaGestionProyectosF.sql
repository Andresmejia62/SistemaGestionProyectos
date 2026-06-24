use master;
go

if exists (select name from sys.databases where name = 'SistemaGestionProyectos')
begin
    drop database SistemaGestionProyectos;
end
go

create database SistemaGestionProyectos
go


use SistemaGestionProyectos;
go

-- Creación de Esquemas
create schema Catalogos;
go
create schema Proyectos;
go
create schema Financiero;
go
create schema Seguridad;
go
create schema Auditoria;
go

-- 1. TABLAS DEL ESQUEMA CATALOGOS
create table Catalogos.COLABORADOR (
    id_colaborador int identity(1,1) constraint PK_colaborador_id primary key,
    nombre varchar(100) not null,
    apellido varchar(100) not null,
    role varchar(80) not null,
    perfil_profesional nvarchar(max),
    horas_max_semana int not null constraint df_horas_max_semana default 40,
    
    created_at datetime constraint df_colaborador_created_at default getdate(),
    updated_at datetime null,
    deleted_at datetime null,

    constraint CK_HORAS_MAX check (horas_max_semana > 0)
);
go

create table Catalogos.PROVEEDOR (
    id_proveedor int identity(1,1) constraint PK_proveedor_id primary key,
    nombre_empresa varchar(150) not null constraint uk_nombre_empresa unique,
    contacto varchar(100),
    telefono varchar(20),
    rubro varchar(80),
    
    created_at datetime constraint df_proveedor_created_at default getdate(),
    updated_at datetime null,
    deleted_at datetime null
);
go

create table Catalogos.TIPO_INCIDENCIA (
    id_tipo_incidencia int identity(1,1) constraint PK_tipo_incidencia_id primary key,
    nombre_tipo varchar(100) not null unique,
    prioridad varchar(20) not null default 'Media',
    tiempo_respuesta int not null default 24,
    
    created_at datetime constraint df_tipo_incidencia_created_at default getdate(),
    updated_at datetime null,
    deleted_at datetime null,

    constraint CK_PRIORIDAD check (prioridad in ('Baja', 'Media', 'Alta', 'Critica'))
);
go

create table Catalogos.HABILIDAD (
    id_habilidad int identity(1,1) constraint PK_habilidad_id primary key,
    nombre_habilidad varchar(100) not null unique,
    categoria varchar(60) not null,
    
    created_at datetime constraint df_habilidad_created_at default getdate(),
    updated_at datetime null,
    deleted_at datetime null
);
go

create table Catalogos.IDIOMA (
    id_idioma int identity(1,1) constraint PK_idioma_id primary key,
    nombre_idioma varchar(60) not null unique,
    codigo_iso char(2) not null unique,
    
    created_at datetime constraint df_idioma_created_at default getdate(),
    updated_at datetime null,
    deleted_at datetime null
);
go

-- 2. TABLAS DEL ESQUEMA SEGURIDAD
create table Seguridad.USUARIO_SISTEMA (
    id_usuario int identity(1,1) constraint PK_usuariosistema_id primary key,
    id_colaborador int unique not null,
    nombre_usuario varchar(80) not null unique,
    rol_sistema varchar(30) not null default 'Colaborador',
    activo bit not null default 1,
    
    created_at datetime constraint df_usuariosistema_created_at default getdate(),
    updated_at datetime null,
    deleted_at datetime null,

    constraint FK_usuariosistema_colaborador foreign key (id_colaborador) references Catalogos.COLABORADOR(id_colaborador),
    constraint CK_ROL_USUARIO check (rol_sistema in ('Administrador', 'Coordinador', 'RRHH', 'Colaborador'))
);
go

-- 3. TABLAS DEL ESQUEMA PROYECTOS
create table Proyectos.PROYECTO (
    id_proyecto int identity(1,1) constraint PK_proyecto_id primary key,
    nombre nvarchar(200) not null unique,
    objetivo nvarchar(max) not null,
    tipo varchar(50) not null,
    fecha_inicio date not null,
    fecha_fin date not null,
    presupuesto_inicial decimal(15,2) not null default 0.00,
    estado varchar(30) not null default 'Creado',
    
    created_at datetime constraint df_proyecto_created_at default getdate(),
    updated_at datetime null,
    deleted_at datetime null,

    constraint CK_PROYECTO_ESTADO check (estado in ('Creado', 'En ejecución', 'En evaluación', 'Cerrado')),
    constraint CK_PROYECTO_FECHAS check (fecha_inicio < fecha_fin)
);
go

create table Proyectos.HITO (
    id_hito int identity(1,1) constraint PK_hito_id primary key,
    id_proyecto int not null,
    nombre_hito varchar(150) not null,
    fecha_clave date not null,
    entregable nvarchar(max),
    es_critico bit not null default 0,
    
    created_at datetime constraint df_hito_created_at default getdate(),
    updated_at datetime null,
    deleted_at datetime null,

    constraint FK_hito_proyecto foreign key (id_proyecto) references Proyectos.PROYECTO(id_proyecto)
);
go

create table Proyectos.TAREA (
    id_tarea int identity(1,1) constraint PK_tarea_id primary key,
    id_proyecto int not null,
    id_hito int null,
    descripcion nvarchar(max) not null,
    estado varchar(30) not null default 'Pendiente',
    
    created_at datetime constraint df_tarea_created_at default getdate(),
    updated_at datetime null,
    deleted_at datetime null,

    constraint FK_tarea_proyecto foreign key (id_proyecto) references Proyectos.PROYECTO(id_proyecto),
    constraint FK_tarea_hito foreign key (id_hito) references Proyectos.HITO(id_hito),
    constraint CK_TAREA_ESTADO check (estado in ('Pendiente', 'En progreso', 'Completada', 'Bloqueada'))
);
go

create table Proyectos.INCIDENCIA (
    id_incidencia int identity(1,1) constraint PK_incidencia_id primary key,
    id_tarea int not null,
    id_colaborador int not null,
    id_tipo_incidencia int not null,
    descripcion nvarchar(max) not null,
    plan_mitigacion nvarchar(max) not null,
    fecha_reporte datetime not null default getdate(),
    
    created_at datetime constraint df_incidencia_created_at default getdate(),
    updated_at datetime null,
    deleted_at datetime null,

    constraint FK_incidencia_tarea foreign key (id_tarea) references Proyectos.TAREA(id_tarea),
    constraint FK_incidencia_colaborador foreign key (id_colaborador) references Catalogos.COLABORADOR(id_colaborador),
    constraint FK_incidencia_tipo_incidencia foreign key (id_tipo_incidencia) references Catalogos.TIPO_INCIDENCIA(id_tipo_incidencia)
);
go

create table Proyectos.ENTREGABLE (
    id_entregable int identity(1,1) constraint PK_entregable_id primary key,
    id_proyecto int not null,
    nombre varchar(200) not null,
    criterio_aceptacion nvarchar(max) not null,
    estado_validacion varchar(30) not null default 'Pendiente',
    fecha_validacion date null,
    
    created_at datetime constraint df_entregable_created_at default getdate(),
    updated_at datetime null,
    deleted_at datetime null,

    constraint FK_entregable_proyecto foreign key (id_proyecto) references Proyectos.PROYECTO(id_proyecto),
    constraint CK_ESTADO_VALIDACION check (estado_validacion in ('Pendiente', 'Aceptado', 'Rechazado'))
);
go

create table Proyectos.BITACORA (
    id_registro int identity(1,1) constraint PK_bitacora_id primary key,
    id_tarea int not null,
    id_colaborador int not null,
    fecha_registro date not null default getdate(),
    horas_trabajadas decimal(5,2) not null default 0.00,
    descripcion_actividad nvarchar(max) not null,
    porcentaje_avance decimal(5,2) not null default 0.00, -- Corregido typo de 'percentage' a 'porcentaje'
    
    created_at datetime constraint df_bitacora_created_at default getdate(),
    updated_at datetime null,
    deleted_at datetime null,

    constraint FK_bitacora_tarea foreign key (id_tarea) references Proyectos.TAREA(id_tarea),
    constraint FK_bitacora_colaborador foreign key (id_colaborador) references Catalogos.COLABORADOR(id_colaborador)
);
go

create table Proyectos.DOCUMENTO_PROYECTO (
    id_documento int identity(1,1) constraint PK_documento_id primary key,
    id_proyecto int not null,
    nombre_documento varchar(200) not null,
    tipo_documento varchar(100) not null,
    ruta_archivo varchar(300) not null,
    fecha_subida datetime not null default getdate(),
    
    created_at datetime constraint df_documentoproyecto_created_at default getdate(),
    updated_at datetime null,
    deleted_at datetime null,

    constraint FK_documentoproyecto_proyecto foreign key (id_proyecto) references Proyectos.PROYECTO(id_proyecto)
);
go

create table Proyectos.RETROALIMENTACION (
    id_retroalimentacion int identity(1,1) constraint PK_retroalimentacion_id primary key,
    id_proyecto int not null,
    descripcion nvarchar(max) not null,
    categoria varchar(100) not null,
    fecha_registro date not null default getdate(),
    
    created_at datetime constraint df_retroalimentacion_created_at default getdate(),
    updated_at datetime null,
    deleted_at datetime null,

    constraint FK_retroalimentacion_proyecto foreign key (id_proyecto) references Proyectos.PROYECTO(id_proyecto)
);
go

-- 4. TABLAS DEL ESQUEMA FINANCIERO
create table Financiero.PRESUPUESTO (
    id_presupuesto int identity(1,1) constraint PK_presupuesto_id primary key,
    id_proyecto int not null,
    monto_aprobado decimal(15,2) not null default 0.00,
    monto_ejecutado decimal(15,2) not null default 0.00,
    saldo_disponible decimal(15,2) not null default 0.00,
    estado_presupuesto varchar(30) not null default 'Aprobado',
    
    created_at datetime constraint df_presupuesto_created_at default getdate(),
    updated_at datetime null,
    deleted_at datetime null,

    constraint FK_presupuesto_proyecto foreign key (id_proyecto) references Proyectos.PROYECTO(id_proyecto)
);
go

create table Financiero.ADQUISICION (
    id_adquisicion int identity(1,1) constraint PK_adquisicion_id primary key,
    id_proyecto int not null,
    id_proveedor int not null,
    insumo varchar(200) not null,
    cantidad int not null default 1,
    costo_unitario decimal(12,2) not null default 0.00,
    estado_compra varchar(30) not null default 'Solicitada',
    
    created_at datetime constraint df_adquisicion_created_at default getdate(),
    updated_at datetime null,
    deleted_at datetime null,

    constraint FK_adquisicion_proyecto foreign key (id_proyecto) references Proyectos.PROYECTO(id_proyecto),
    constraint FK_adquisicion_proveedor foreign key (id_proveedor) references Catalogos.PROVEEDOR(id_proveedor),
    constraint CK_ESTADO_COMPRA check (estado_compra in ('Solicitada', 'Aprobada', 'Rechazada', 'Entregada'))
);
go

create table Financiero.GASTO_PRESUPUESTARIO (
    id_gasto int identity(1,1) constraint PK_gasto_id primary key,
    id_proyecto int not null,
    id_adquisicion int null,
    id_presupuesto int not null,
    rubro varchar(100) not null,
    monto decimal(15,2) not null default 0.00,
    fecha_gasto date not null default getdate(),
    numero_factura varchar(50),
    
    created_at datetime constraint df_gastopresupuestario_created_at default getdate(),
    updated_at datetime null,
    deleted_at datetime null,

    constraint FK_gastopresupuestario_proyecto foreign key (id_proyecto) references Proyectos.PROYECTO(id_proyecto),
    constraint FK_gastopresupuestario_adquisicion foreign key (id_adquisicion) references Financiero.ADQUISICION(id_adquisicion),
    constraint FK_gastopresupuestario_presupuesto foreign key (id_presupuesto) references Financiero.PRESUPUESTO(id_presupuesto)
);
go

-- 5. TABLAS DEL ESQUEMA AUDITORIA
create table Auditoria.AUDITORIA (
    id_auditoria int identity(1,1) constraint PK_auditoria_id primary key,
    tabla_modificada varchar(100) not null,
    id_registro int not null,
    accion varchar(20) not null,
    usuario_responsable int not null,
    fecha_cambio datetime not null default getdate(),
    detalle_cambio nvarchar(max) not null,
    
    created_at datetime constraint df_auditoria_created_at default getdate(),
    updated_at datetime null,
    deleted_at datetime null,

    constraint FK_auditoria_usuariosistema foreign key (usuario_responsable) references Seguridad.USUARIO_SISTEMA(id_usuario),
    constraint CK_ACCION_AUDITORIA check (accion in ('INSERT', 'UPDATE', 'DELETE'))
);
go

-- 6. TABLAS INTERMEDIAS Y DE RELACIONES N:M
create table Proyectos.ASIGNACION (
    id_colaborador int not null,
    id_proyecto int not null,
    horas_asignadas int not null default 0,
    rol_en_proyecto varchar(80) not null,
    fecha_asignacion date not null default cast(getdate() as date),
    
    created_at datetime constraint df_asignacion_created_at default getdate(),
    updated_at datetime null,
    deleted_at datetime null,

    constraint FK_asignacion_colaborador foreign key (id_colaborador) references Catalogos.COLABORADOR(id_colaborador),
    constraint FK_asignacion_proyecto foreign key (id_proyecto) references Proyectos.PROYECTO(id_proyecto),
    constraint PK_asignacion primary key (id_colaborador, id_proyecto)
);
go

create table Proyectos.TAREA_RESPONSABLE (
    id_tarea int not null,
    id_colaborador int not null,
    es_responsable_principal bit not null default 0,
    
    created_at datetime constraint df_tarearesponsable_created_at default getdate(),
    updated_at datetime null,
    deleted_at datetime null,

    constraint FK_tarearesponsable_tarea foreign key (id_tarea) references Proyectos.TAREA(id_tarea),
    constraint FK_tarearesponsable_colaborador foreign key (id_colaborador) references Catalogos.COLABORADOR(id_colaborador),
    constraint PK_tarea_responsable primary key (id_tarea, id_colaborador)
);
go

create table Proyectos.DEPENDENCIA_TAREA (
    id_tarea int not null,
    id_predecesora int not null,
    tipo_dependencia varchar(30) default 'FS',
    
    created_at datetime constraint df_dependenciatarea_created_at default getdate(),
    updated_at datetime null,
    deleted_at datetime null,

    constraint FK_dependenciatarea_tarea foreign key (id_tarea) references Proyectos.TAREA(id_tarea),
    constraint FK_dependenciatarea_predecesora foreign key (id_predecesora) references Proyectos.TAREA(id_tarea),
    constraint PK_dependencia_tarea primary key (id_tarea, id_predecesora)
);
go

create table Proyectos.COLABORADOR_HABILIDAD (
    id_colaborador int not null,
    id_habilidad int not null,
    nivel varchar(20) not null default 'Básico',
    fecha_certificacion date null,
    
    created_at datetime constraint df_colaboradorhabilidad_created_at default getdate(),
    updated_at datetime null,
    deleted_at datetime null,

    constraint FK_colaboradorhabilidad_colaborador foreign key (id_colaborador) references Catalogos.COLABORADOR(id_colaborador),
    constraint FK_colaboradorhabilidad_habilidad foreign key (id_habilidad) references Catalogos.HABILIDAD(id_habilidad),
    constraint PK_colaborador_habilidad primary key (id_colaborador, id_habilidad),
    constraint CK_NIVEL_HABILIDAD check (nivel in ('Básico', 'Intermedio', 'Avanzado', 'Experto'))
);
go

create table Proyectos.COLABORADOR_IDIOMA (
    id_colaborador int not null,
    id_idioma int not null,
    nivel_idioma varchar(20) not null default 'B1',
    
    created_at datetime constraint df_colaboradoridioma_created_at default getdate(),
    updated_at datetime null,
    deleted_at datetime null,

    constraint FK_colaboradoridioma_colaborador foreign key (id_colaborador) references Catalogos.COLABORADOR(id_colaborador),
    constraint FK_colaboradoridioma_idioma foreign key (id_idioma) references Catalogos.IDIOMA(id_idioma),
    constraint PK_colaborador_idioma primary key (id_colaborador, id_idioma),
    constraint CK_NIVEL_IDIOMA check (nivel_idioma in ('A1', 'A2', 'B1', 'B2', 'C1', 'C2', 'Nativo'))
);
go


-- =====================================================================
-- 1. INSERTS EN TABLAS MAESTRAS (CON CONFIGURACIÓN DE FECHA UNIVERSAL)
-- =====================================================================
set dateformat ymd; -- <--- SOLUCIÓN AL ERROR DE CONVERSIÓN DE FECHAS
go

insert into Proyectos.PROYECTO (nombre, objetivo, tipo, fecha_inicio, fecha_fin, presupuesto_inicial, estado) values
('Sistema ERP Fase 1', 'Desarrollo del módulo de inventario y facturación.', 'Desarrollo de Software', '2026-01-10', '2026-06-30', 45000.00, 'En ejecución'),
('Migración Infraestructura Nube', 'Trasladar servidores locales a servicios AWS.', 'Infraestructura TI', '2026-02-15', '2026-05-20', 25000.00, 'En ejecución'),
('Portal de Clientes Móvil', 'Creación de app híbrida para autogestión de clientes.', 'Desarrollo Móvil', '2026-04-01', '2026-09-15', 18000.00, 'Creado'),
('Auditoría de Ciberseguridad 2026', 'Evaluación integral de vulnerabilidades en la red.', 'Seguridad', '2026-01-05', '2026-03-10', 12000.00, 'Cerrado');
go

insert into Catalogos.COLABORADOR (nombre, apellido, role, perfil_profesional, horas_max_semana) values
('Carlos', 'Mendoza', 'Líder de Proyecto', 'PMP certificado con 8 años de experiencia en metodologías ágiles.', 40),
('Ana', 'Silva', 'Desarrollador Senior', 'Especialista en backend con SQL Server, .NET y arquitectura de microservicios.', 40),
('Jorge', 'Reyes', 'Administrador Cloud', 'Certificado en AWS Solutions Architect con experiencia en despliegues automatizados.', 40),
('Elena', 'Gómez', 'Analista QA', 'Experta en pruebas automatizadas y aseguramiento de la calidad de software.', 30),
('Luis', 'Torres', 'Especialista en Seguridad', 'Hacker ético certificado enfocado en auditorías de infraestructura corporativa.', 40);
go

insert into Catalogos.PROVEEDOR (nombre_empresa, contacto, telefono, rubro) values
('Tecnologías Globales S.A.', 'Ing. Mario Juárez', '+505 8888-1111', 'Licencias y Servidores'),
('Cloud Solutions Group', 'Lic. Claudia Borge', '+505 7777-2222', 'Servicios en la Nube'),
('Seguridad Digital Corp', 'Dr. Roberto Mendoza', '+505 5555-3333', 'Consultoría de Seguridad');
go

insert into Catalogos.TIPO_INCIDENCIA (nombre_tipo, prioridad, tiempo_respuesta) values
('Bloqueo de Código', 'Alta', 4),
('Error de Servidor / Caída', 'Critica', 2),
('Falta de Especificación', 'Media', 12),
('Ajuste de Interfaz Menor', 'Baja', 48);
go

insert into Catalogos.HABILIDAD (nombre_habilidad, categoria) values
('Transact-SQL', 'Bases de Datos'),
('AWS Cloud Architecture', 'Cloud Computing'),
('C# .NET', 'Desarrollo de Software'),
('Automatización con Selenium', 'Calidad de Software'),
('Análisis de Vulnerabilidades', 'Ciberseguridad');
go

insert into Catalogos.IDIOMA (nombre_idioma, codigo_iso) values
('Español', 'ES'),
('Inglés', 'EN'),
('Portugués', 'PT');
go


-- ==========================================
-- 2. INSERTS EN TABLAS DEPENDIENTES
-- ==========================================
set dateformat ymd;
go

insert into Proyectos.HITO (id_proyecto, nombre_hito, fecha_clave, entregable, es_critico) values
(1, 'Diseño de Base de Datos Aprobado', '2026-02-01', 'Diagrama entidad-relación y scripts DDL.', 1),
(1, 'Módulo de Inventario Funcional', '2026-04-15', 'API de gestión de inventario desplegada en staging.', 0),
(2, 'Migración de Datos de Prueba', '2026-03-01', 'Base de datos replicada con éxito en AWS RDS.', 1),
(4, 'Entrega de Informe Final', '2026-03-05', 'Documento detallado de vulnerabilidades encontradas.', 1);
go

insert into Proyectos.TAREA (id_proyecto, id_hito, descripcion, estado) values
(1, 1, 'Crear modelo lógico y físico de la base de datos ERP.', 'Completada'),
(1, 2, 'Programar los controladores de la API de Productos.', 'En progreso'),
(2, 3, 'Configurar VPC y subredes seguras en el entorno AWS.', 'Completada'),
(2, 3, 'Ejecutar script de migración masiva de datos antiguos.', 'Pendiente'),
(3, null, 'Definir requerimientos de interfaz con el cliente.', 'Pendiente');
go

insert into Financiero.ADQUISICION (id_proyecto, id_proveedor, insumo, cantidad, costo_unitario, estado_compra) values
(1, 1, 'Licencias de Desarrollo IDE', 5, 250.00, 'Aprobada'),
(2, 2, 'Suscripción Mensual Instancias EC2 y RDS', 1, 1500.00, 'Entregada'),
(4, 3, 'Kit de Herramientas de Escaneo de Vulnerabilidades', 2, 600.00, 'Entregada');
go

insert into Proyectos.INCIDENCIA (id_tarea, id_colaborador, id_tipo_incidencia, descripcion, plan_mitigacion, fecha_reporte) values
(2, 2, 1, 'Incompatibilidad de tipos en la librería de conexión SQL.', 'Actualizar dependencias de NuGet e implementar parches.', '2026-03-10 09:30:00'),
(3, 3, 2, 'Fallo de autenticación temporal al conectar la terminal local con AWS.', 'Configurar llaves SSH de respaldo y revisar políticas IAM.', '2026-02-18 14:15:00');
go

insert into Proyectos.ENTREGABLE (id_proyecto, nombre, criterio_aceptacion, estado_validacion, fecha_validacion) values
(1, 'Esquema de Base de Datos', 'Debe pasar pruebas de integridad referencial y normalización 3FN.', 'Aceptado', '2026-02-05'),
(2, 'Servidores de Producción en AWS', 'Disponibilidad del 99.9% evaluada por 48 horas seguidas.', 'Pendiente', null),
(4, 'Reporte Ejecutivo de Mitigación', 'Firmado por el especialista y libre de hallazgos críticos sin resolver.', 'Aceptado', '2026-03-08');
go

insert into Proyectos.BITACORA (id_tarea, id_colaborador, fecha_registro, horas_trabajadas, descripcion_actividad, porcentaje_avance) values
(1, 1, '2026-01-15', 4.5, 'Reunión de requerimientos iniciales para el diseño del ERP.', 20.00),
(1, 2, '2026-01-20', 8.0, 'Modelado y normalización de las tablas del inventario.', 70.00),
(3, 3, '2026-02-16', 6.0, 'Creación de scripts de infraestructura como código usando Terraform.', 100.00),
(2, 2, '2026-04-05', 5.5, 'Desarrollo de los métodos CRUD para la gestión de productos.', 40.00);
go

insert into Financiero.PRESUPUESTO (id_proyecto, monto_aprobado, monto_ejecutado, saldo_disponible, estado_presupuesto) values
(1, 45000.00, 1250.00, 43750.00, 'Aprobado'),
(2, 25000.00, 1500.00, 23500.00, 'Aprobado'),
(3, 18000.00, 0.00, 18000.00, 'Aprobado'),
(4, 12000.00, 1200.00, 10800.00, 'Aprobado');
go

insert into Financiero.GASTO_PRESUPUESTARIO (id_proyecto, id_adquisicion, id_presupuesto, rubro, monto, fecha_gasto, numero_factura) values
(1, 1, 1, 'Software y Licenciamiento', 1250.00, '2026-01-25', 'FACT-2026-001'),
(2, 2, 2, 'Servicios en la Nube', 1500.00, '2026-02-28', 'AWS-FEB-9982'),
(4, 3, 4, 'Consultoría / Herramientas', 1200.00, '2026-01-10', 'SDC-77412');
go

insert into Seguridad.USUARIO_SISTEMA (id_colaborador, nombre_usuario, rol_sistema, activo) values
(1, 'cmendoza', 'Coordinador', 1),
(2, 'asilva', 'Colaborador', 1),
(3, 'jreyes', 'Colaborador', 1),
(4, 'egomez', 'Colaborador', 1),
(5, 'ltorres', 'Administrador', 1);
go

insert into Proyectos.DOCUMENTO_PROYECTO (id_proyecto, nombre_documento, tipo_documento, ruta_archivo, fecha_subida) values
(1, 'Especificacion_Requerimientos_V1.0', 'PDF', '/docs/proyecto1/srs_v1.0.pdf', '2026-01-12 08:00:00'),
(2, 'Arquitectura_Red_AWS', 'PNG', '/docs/proyecto2/aws_network.png', '2026-02-16 11:30:00');
go

insert into Proyectos.RETROALIMENTACION (id_proyecto, descripcion, categoria, fecha_registro) values
(4, 'La comunicación con el proveedor de auditoría externa fue excelente, facilitando los accesos a tiempo.', 'Lecciones Aprendidas', '2026-03-12'),
(1, 'Se requiere definir de forma más clara las historias de usuario del módulo de facturación.', 'Mejora Continua', '2026-02-20');
go

insert into Auditoria.AUDITORIA (tabla_modificada, id_registro, accion, usuario_responsable, fecha_cambio, detalle_cambio)
values ('PROYECTO', 1, 'INSERT', 5, '2026-01-10 08:15:22', 'Inserción del registro inicial del proyecto Sistema ERP Fase 1.');

insert into Auditoria.AUDITORIA (tabla_modificada, id_registro, accion, usuario_responsable, fecha_cambio, detalle_cambio) values
('PRESUPUESTO', 1, 'UPDATE', 5, '2026-01-25 16:40:00', 'Modificación de monto_ejecutado y saldo_disponible por registro de gasto FACT-2026-001.');
go


-- ==========================================
-- 3. INSERTS EN TABLAS INTERMEDIAS
-- ==========================================
set dateformat ymd;
go

insert into Proyectos.ASIGNACION (id_colaborador, id_proyecto, horas_asignadas, rol_en_proyecto, fecha_asignacion) values
(1, 1, 20, 'Gerente de Proyecto', '2026-01-10'),
(2, 1, 40, 'Desarrollador Backend Principal', '2026-01-10'),
(4, 1, 15, 'Ingeniero de Automatización QA', '2026-01-15'),
(3, 2, 40, 'Arquitecto Cloud', '2026-02-15'),
(5, 4, 30, 'Auditor de Seguridad Principal', '2026-01-05');
go

insert into Proyectos.TAREA_RESPONSABLE (id_tarea, id_colaborador, es_responsable_principal) values
(1, 2, 1),
(2, 2, 1),
(3, 3, 1),
(4, 3, 0);
go

insert into Proyectos.DEPENDENCIA_TAREA (id_tarea, id_predecesora, tipo_dependencia) values
(2, 1, 'FS'),
(4, 3, 'FS');
go

insert into Proyectos.COLABORADOR_HABILIDAD (id_colaborador, id_habilidad, nivel, fecha_certificacion) values
(2, 1, 'Experto', '2025-06-15'),
(2, 3, 'Avanzado', null),
(3, 2, 'Experto', '2024-11-20'),
(4, 4, 'Intermedio', null),
(5, 5, 'Avanzado', '2025-02-10');
go

insert into Proyectos.COLABORADOR_IDIOMA (id_colaborador, id_idioma, nivel_idioma) values
(1, 1, 'Nativo'),
(1, 2, 'B2'),
(2, 1, 'Nativo'),
(2, 2, 'C1'),
(3, 1, 'Nativo'),
(3, 2, 'B1');
go

-- =====================================================================
-- NUEVA SECCIÓN: OPERACIONES ALTER TABLE (Estructura)
-- =====================================================================
print '====================================================================='
print 'NUEVA SECCIÓN: EJECUTANDO ALTER TABLE...'
print '====================================================================='
go

-- ALTER 1: Agregar una nueva columna a la tabla de Proyectos
alter table Proyectos.PROYECTO 
add cliente_corporativo varchar(150) null;
go

-- ALTER 2: Modificar el tipo de dato o longitud de una columna existente
alter table Catalogos.PROVEEDOR 
alter column telefono varchar(35);
go

-- ALTER 3: Agregar una restricción CHECK nueva a la tabla COLABORADOR
alter table Catalogos.COLABORADOR 
add constraint CK_HORAS_MAX_LEGAL check (horas_max_semana <= 60);
go

-- Verificación de los cambios estructurales mediante consulta al catálogo del sistema
print 'Verificando columnas agregadas en PROYECTO...'
select table_schema, table_name, column_name, data_type, character_maximum_length 
from information_schema.columns 
where table_name = 'PROYECTO' and column_name = 'cliente_corporativo';
go


-- =====================================================================
-- NUEVA SECCIÓN: OPERACIONES DELETE (Manejo Seguro de Datos)
-- =====================================================================
print '====================================================================='
print 'NUEVA SECCIÓN: EJECUTANDO DELETES...'
print '====================================================================='
go

-- CASO DELETE 1: Eliminación directa de un registro sin dependencias activas.
print 'Antes del DELETE 1 (Idiomas disponibles):'
select id_idioma, nombre_idioma from Catalogos.IDIOMA;

delete from Catalogos.IDIOMA 
where nombre_idioma = 'Portugués';

print 'Después del DELETE 1 (Idiomas disponibles):'
select id_idioma, nombre_idioma from Catalogos.IDIOMA;
go


-- CASO DELETE 2: Eliminación en cadena controlada / con dependencias.
print 'Antes del DELETE 2 - Presupuestos vigentes:'
select id_proyecto, monto_aprobado, estado_presupuesto from Financiero.PRESUPUESTO;

-- 1º Limpiar dependencias del esquema Financiero de ese proyecto específico
delete from Financiero.GASTO_PRESUPUESTARIO where id_proyecto = 4;
delete from Financiero.ADQUISICION where id_proyecto = 4;
delete from Financiero.PRESUPUESTO where id_proyecto = 4;

-- 2º Limpiar dependencias del esquema Proyectos de ese proyecto específico
delete from Proyectos.RETROALIMENTACION where id_proyecto = 4;
delete from Proyectos.ENTREGABLE where id_proyecto = 4;
delete from Proyectos.ASIGNACION where id_proyecto = 4;

-- Limpieza de cascada manual en tareas asociadas
delete from Proyectos.INCIDENCIA where id_tarea in (select id_tarea from Proyectos.TAREA where id_proyecto = 4);
delete from Proyectos.TAREA_RESPONSABLE where id_tarea in (select id_tarea from Proyectos.TAREA where id_proyecto = 4);
delete from Proyectos.DEPENDENCIA_TAREA where id_tarea in (select id_tarea from Proyectos.TAREA where id_proyecto = 4);
delete from Proyectos.BITACORA where id_tarea in (select id_tarea from Proyectos.TAREA where id_proyecto = 4);

delete from Proyectos.TAREA where id_proyecto = 4;
delete from Proyectos.HITO where id_proyecto = 4;

-- 3º Finalmente eliminamos el registro maestro en PROYECTO de forma segura
delete from Proyectos.PROYECTO 
where id_proyecto = 4;

print 'Después del DELETE 2 - Presupuestos y Proyectos restantes:'
select id_proyecto, nombre, estado from Proyectos.PROYECTO;
go


-- ==========================================
-- 4. QUERIES DE CONTROL ORIGINALES
-- ==========================================

print '====================================================================='
print '                 SISTEMA DE GESTION DE PROYECTOS'

print '====================================================================='
print '1. CONSULTAS DE CONTROL Y ASIGNACIÓN DE RECURSOS'
print '====================================================================='
go

print 'A. Listar colaboradores con sus proyectos y roles actuales...'
select 
    c.nombre + ' ' + c.apellido as Colaborador,
    p.nombre as Proyecto,
    a.rol_en_proyecto as [Rol Asignado],
    a.horas_asignadas as [Horas Semanales] 
from Catalogos.COLABORADOR c
inner join Proyectos.ASIGNACION a on c.id_colaborador = a.id_colaborador
inner join Proyectos.PROYECTO p on a.id_proyecto = p.id_proyecto
where a.deleted_at is null;
go

print 'B. Carga de trabajo total por colaborador...'
select 
    c.nombre + ' ' + c.apellido as Colaborador,
    c.horas_max_semana as [Capacidad Max],
    sum(a.horas_asignadas) as [Total Horas Asignadas],
    case 
        when sum(a.horas_asignadas) > c.horas_max_semana then 'SOBRECARGADO'
        else 'Correcto'
    end as EstadoCarga
from Catalogos.COLABORADOR c
inner join Proyectos.ASIGNACION a on c.id_colaborador = a.id_colaborador
group by c.id_colaborador, c.nombre, c.apellido, c.horas_max_semana;
go

print '====================================================================='
print '2. CONSULTAS DE SEGUIMIENTO DE TAREAS Y AVANCE'
print '====================================================================='
go

print 'C. Estado actual de tareas y sus responsables principales...'
select 
    p.nombre as Proyecto,
    t.descripcion as Tarea,
    isnull(h.nombre_hito, 'Sin Hito Asociado') as Hito,
    t.estado as [Estado Tarea],
    c.nombre + ' ' + c.apellido as [Responsable Principal]
from Proyectos.TAREA t
inner join Proyectos.PROYECTO p on t.id_proyecto = p.id_proyecto
left join Proyectos.HITO h on t.id_hito = h.id_hito
inner join Proyectos.TAREA_RESPONSABLE tr on t.id_tarea = tr.id_tarea
inner join Catalogos.COLABORADOR c on tr.id_colaborador = c.id_colaborador
where tr.es_responsable_principal = 1;
go

print 'D. Reporte de horas invertidas (Bitácora) por Proyecto...'
select 
    p.nombre as Proyecto,
    count(distinct b.id_registro) as [Cantidad Registros],
    sum(b.horas_trabajadas) as [Total Horas Reales],
    avg(b.porcentaje_avance) as [Progreso Promedio Registrado]
from Proyectos.PROYECTO p
inner join Proyectos.TAREA t on p.id_proyecto = t.id_proyecto
inner join Proyectos.BITACORA b on t.id_tarea = b.id_tarea
group by p.id_proyecto, p.nombre;
go

print '====================================================================='
print '3. CONSULTAS FINANCIERAS Y DE PRESUPUESTO'
print '====================================================================='
go

print 'E. Estado financiero de los proyectos (Semáforo de Presupuesto)...'
select 
    p.nombre as Proyecto,
    pr.monto_aprobado as [Presupuesto Aprobado],
    pr.monto_ejecutado as [Total Gastado],
    pr.saldo_disponible as [Saldo Restante],
    cast((pr.monto_ejecutado / pr.monto_aprobado) * 100 as decimal(5,2)) as [Porcentaje Consumido]
from Proyectos.PROYECTO p
inner join Financiero.PRESUPUESTO pr on p.id_proyecto = pr.id_proyecto;
go

print 'F. Detalle de compras (Adquisiciones) por Proveedor...'
select 
    prov.nombre_empresa as Proveedor,
    p.nombre as Proyecto,
    a.insumo as [Insumo Adquirido],
    a.cantidad as Cantidad,
    a.costo_unitario as [Costo Unitario],
    (a.cantidad * a.costo_unitario) as [Costo Total Facturado],
    a.estado_compra as [Estado de Compra]
from Financiero.ADQUISICION a
inner join Catalogos.PROVEEDOR prov on a.id_proveedor = prov.id_proveedor
inner join Proyectos.PROYECTO p on a.id_proyecto = p.id_proyecto;
go

print '====================================================================='
print '4. GESTIÓN DE RIESGOS E INCIDENCIAS'
print '====================================================================='
go

print 'G. Incidencias críticas o altas activas y sus planes de mitigación...'
select 
    p.nombre as Proyecto,
    t.descripcion as Tarea,
    ti.nombre_tipo as [Tipo Incidencia],
    ti.prioridad as Prioridad,
    i.descripcion as [Problema Reportado],
    i.plan_mitigacion as [Plan de Acción],
    c.nombre + ' ' + c.apellido as [Reportado Por]
from Proyectos.INCIDENCIA i
inner join Catalogos.TIPO_INCIDENCIA ti on i.id_tipo_incidencia = ti.id_tipo_incidencia
inner join Proyectos.TAREA t on i.id_tarea = t.id_tarea
inner join Proyectos.PROYECTO p on t.id_proyecto = p.id_proyecto
inner join Catalogos.COLABORADOR c on i.id_colaborador = c.id_colaborador
where ti.prioridad in ('Alta', 'Critica');
go

print '====================================================================='
print '5. CONSULTAS DE PERFIL PROFESIONAL '
print '====================================================================='
go

print 'H. Buscar colaboradores con la habilidad "AWS Cloud Architecture"...'
select 
    c.nombre + ' ' + c.apellido as Colaborador,
    h.nombre_habilidad as Habilidad,
    ch.nivel as [Nivel de Experiencia],
    isnull(cast(ch.fecha_certificacion as varchar(10)), 'No Certificado') as [Fecha Certificación]
from Catalogos.COLABORADOR c
inner join Proyectos.COLABORADOR_HABILIDAD ch on c.id_colaborador = ch.id_colaborador
inner join Catalogos.HABILIDAD h on ch.id_habilidad = h.id_habilidad
where h.nombre_habilidad = 'AWS Cloud Architecture' and ch.nivel in ('Avanzado', 'Experto');
go
