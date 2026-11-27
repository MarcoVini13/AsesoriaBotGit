-- Creacion de la base de datos
CREATE DATABASE IF NOT EXISTS asesoria_bot_up
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE asesoria_bot_up;

-- Guardado de las cuentas de alumnos, asesores y administradores.
CREATE TABLE usuarios (
    id_usuario INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    matricula VARCHAR(20) NULL UNIQUE,
    nombre_completo VARCHAR(120) NOT NULL,
    correo VARCHAR(120) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    rol ENUM('administrador', 'asesor', 'alumno') NOT NULL,
    telegram_chat_id BIGINT NULL UNIQUE,
    activo TINYINT(1) NOT NULL DEFAULT 1,
    fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_usuarios_activo CHECK (activo IN (0,1))
) ENGINE=InnoDB;

-- Códigos temporales de un solo uso para vincular Telegram.
CREATE TABLE codigos_vinculacion (
    id_codigo INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT UNSIGNED NOT NULL,
    codigo_hash CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL UNIQUE,
    expira_en DATETIME NOT NULL,
    usado_en DATETIME NULL,
    creado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_codigos_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuarios(id_usuario) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_codigo_expiracion CHECK (expira_en > creado_en),
    CONSTRAINT chk_codigo_uso CHECK (usado_en IS NULL OR
        (usado_en >= creado_en AND usado_en < expira_en))
) ENGINE=InnoDB;

-- Catálogo de materias disponibles.
CREATE TABLE materias (
    id_materia INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    clave VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(120) NOT NULL,
    activa TINYINT(1) NOT NULL DEFAULT 1,
    CONSTRAINT chk_materias_activa CHECK (activa IN (0,1))
) ENGINE=InnoDB;

-- Relacionamos a cada asesor con las materias que tiene asignadas.
CREATE TABLE asesor_materia (
    id_asignacion INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_asesor INT UNSIGNED NOT NULL,
    id_materia INT UNSIGNED NOT NULL,
    fecha_asignacion DATE NOT NULL DEFAULT (CURRENT_DATE),
    CONSTRAINT fk_am_asesor FOREIGN KEY (id_asesor)
        REFERENCES usuarios(id_usuario) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_am_materia FOREIGN KEY (id_materia)
        REFERENCES materias(id_materia) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT uq_asesor_materia UNIQUE (id_asesor, id_materia)
) ENGINE=InnoDB;

-- Horarios publicados por los asesores y su cupo máximo.
CREATE TABLE horarios (
    id_horario INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_asesor INT UNSIGNED NOT NULL,
    id_materia INT UNSIGNED NOT NULL,
    fecha DATE NOT NULL,
    hora_inicio TIME NOT NULL,
    hora_fin TIME NOT NULL,
    modalidad ENUM('presencial', 'en_linea') NOT NULL,
    lugar_o_enlace VARCHAR(200) NOT NULL,
    cupo_maximo INT UNSIGNED NOT NULL,
    estado ENUM('disponible', 'cancelado') NOT NULL DEFAULT 'disponible',
    creado_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_horario_asignacion FOREIGN KEY (id_asesor, id_materia)
        REFERENCES asesor_materia(id_asesor, id_materia)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_horarios_horas CHECK (hora_inicio >= '00:00:00'
        AND hora_fin <= '23:59:59' AND hora_fin > hora_inicio),
    CONSTRAINT chk_horarios_cupo_max CHECK (cupo_maximo > 0),
    INDEX idx_horarios_busqueda (id_materia, fecha, estado),
    INDEX idx_horarios_asesor_fecha (id_asesor, fecha, hora_inicio, hora_fin)
) ENGINE=InnoDB;

-- Reservas de los alumnos, estado y observaciones.
CREATE TABLE citas (
    id_cita INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_horario INT UNSIGNED NOT NULL,
    id_alumno INT UNSIGNED NOT NULL,
    tema VARCHAR(255) NOT NULL,
    estado ENUM('pendiente', 'cancelada_alumno', 'cancelada_asesor', 'atendida', 'no_asistio')
        NOT NULL DEFAULT 'pendiente',
    observaciones TEXT NULL,
    reservada_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    cancelada_en DATETIME NULL,
    CONSTRAINT fk_citas_horario FOREIGN KEY (id_horario)
        REFERENCES horarios(id_horario) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_citas_alumno FOREIGN KEY (id_alumno)
        REFERENCES usuarios(id_usuario) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_citas_cancelacion CHECK (
        (estado IN ('cancelada_alumno','cancelada_asesor') AND cancelada_en IS NOT NULL
            AND cancelada_en >= reservada_en)
        OR (estado NOT IN ('cancelada_alumno','cancelada_asesor') AND cancelada_en IS NULL)
    ),
    INDEX idx_citas_alumno_estado (id_alumno, estado),
    INDEX idx_citas_horario_estado (id_horario, estado)
) ENGINE=InnoDB;

-- Historial de avisos enviados o fallidos de Telegram.
CREATE TABLE bitacora_notificaciones (
    id_notificacion INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT UNSIGNED NOT NULL,
    id_cita INT UNSIGNED NOT NULL,
    tipo ENUM('confirmacion', 'cancelacion_alumno', 'cancelacion_asesor', 'recordatorio') NOT NULL,
    mensaje_resumen VARCHAR(255) NOT NULL,
    estado_envio ENUM('enviado', 'fallido') NOT NULL,
    enviada_en DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_notif_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuarios(id_usuario) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_notif_cita FOREIGN KEY (id_cita)
        REFERENCES citas(id_cita) ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_notif_cita_tipo (id_cita, id_usuario, tipo, estado_envio)
) ENGINE=InnoDB;

-- Calculamos los lugares disponibles sin guardar el cupo dos veces.
CREATE VIEW v_horarios_disponibilidad AS
SELECT h.id_horario, h.id_asesor, h.id_materia, h.fecha, h.hora_inicio,
       h.hora_fin, h.modalidad, h.lugar_o_enlace, h.cupo_maximo,
       CASE WHEN h.estado = 'cancelado' THEN 0
            ELSE GREATEST(CAST(h.cupo_maximo AS SIGNED) - CAST(COALESCE(c.ocupados, 0) AS SIGNED), 0)
       END AS cupo_disponible,
       CASE WHEN h.estado = 'cancelado' THEN 'cancelado'
            WHEN COALESCE(c.ocupados, 0) >= h.cupo_maximo THEN 'lleno'
            ELSE 'disponible' END AS estado,
       h.creado_en
FROM horarios h
LEFT JOIN (
    SELECT id_horario, COUNT(*) AS ocupados
    FROM citas WHERE estado IN ('pendiente','atendida','no_asistio')
    GROUP BY id_horario
) c ON c.id_horario = h.id_horario;

-- Agregamos datos ficticios para probar el sistema.
-- Contraseña de prueba: Asesoria2026*.
START TRANSACTION;
SET @hash = '$2y$12$jYzXavDorL5r2FcbxkMiauAAuxgGumSfQDIn9FtxLmLb4wxm7b0E6';
-- Cuentas de prueba para los tres roles.
INSERT INTO usuarios (matricula,nombre_completo,correo,password_hash,rol) VALUES
('ADM001','Administrador Demo','admin@example.com',@hash,'administrador'),
('DOC101','Asesor Demo 1','asesor1@example.com',@hash,'asesor'),
('DOC102','Asesor Demo 2','asesor2@example.com',@hash,'asesor'),
('ALU001','Alumno Demo 1','alumno1@example.com',@hash,'alumno'),
('ALU002','Alumno Demo 2','alumno2@example.com',@hash,'alumno'),
('ALU003','Alumno Demo 3','alumno3@example.com',@hash,'alumno');

-- Código de prueba DEMO-VINC-2026, válido durante 15 minutos.
INSERT INTO codigos_vinculacion (id_usuario,codigo_hash,expira_en) VALUES
(5,SHA2('DEMO-VINC-2026',256),DATE_ADD(NOW(),INTERVAL 15 MINUTE));

-- Materias de ejemplo.
INSERT INTO materias (clave,nombre) VALUES
('ITI-0401','Análisis y Diseño de Software'),
('ITI-0402','Bases de Datos Relacionales'),
('ITI-0403','Programación Orientada a Objetos'),
('ITI-0404','Redes de Computadoras');

-- Asignamos las materias a los asesores de prueba.
INSERT INTO asesor_materia (id_asesor,id_materia) VALUES (2,1),(2,3),(3,2),(3,4);

-- Horarios de ejemplo para los próximos días.
INSERT INTO horarios (id_asesor,id_materia,fecha,hora_inicio,hora_fin,modalidad,lugar_o_enlace,cupo_maximo) VALUES
(2,1,DATE_ADD(CURRENT_DATE,INTERVAL 5 DAY),'10:00:00','11:00:00','presencial','Cubículo de prueba 12',1),
(2,1,DATE_ADD(CURRENT_DATE,INTERVAL 5 DAY),'12:00:00','13:00:00','en_linea','https://example.com/asesoria-ads',3),
(3,2,DATE_ADD(CURRENT_DATE,INTERVAL 6 DAY),'11:00:00','12:00:00','presencial','Laboratorio de prueba 2',2),
(3,4,DATE_ADD(CURRENT_DATE,INTERVAL 7 DAY),'14:00:00','15:00:00','en_linea','https://example.com/redes',2);

-- Reservas de ejemplo.
INSERT INTO citas (id_horario,id_alumno,tema) VALUES
(1,4,'Normalización 3FN y llaves foráneas'),
(3,6,'Consultas JOIN y transacciones en MySQL');

-- Avisos simulados, no se envían mensajes reales.
INSERT INTO bitacora_notificaciones (id_usuario,id_cita,tipo,mensaje_resumen,estado_envio) VALUES
(2,1,'confirmacion','[SIMULACIÓN] Cita reservada por Alumno Demo 1.','enviado'),
(4,1,'confirmacion','[SIMULACIÓN] Tu asesoría quedó confirmada.','enviado');
COMMIT;

-- Revisamos que los cupos disponibles sean 0, 3, 1 y 2.
SELECT id_horario, cupo_maximo, cupo_disponible, estado
FROM v_horarios_disponibilidad ORDER BY id_horario;

-
