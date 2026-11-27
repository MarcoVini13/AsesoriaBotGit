# PoliAsesor (AsesoríaBot UP)

Proyecto integrador de la Universidad Politécnica de San Luis Potosí. El objetivo es facilitar la organización de asesorías académicas mediante un portal web y un bot de Telegram.

## Primer avance — 27 de noviembre de 2026

En esta versión se cuenta con una base de datos con registros de prueba, inicio y cierre de sesión para los tres roles del sistema y un bot que responde a los comandos básicos. El prototipo está alojado en Alwaysdata.

## Demostración del prototipo

- **Portal web:** [poliasesor.alwaysdata.net](https://poliasesor.alwaysdata.net)
- **Bot de Telegram:** [@PoliAsesor_bot](https://t.me/PoliAsesor_bot)
- **Documentación y evidencias:** [carpeta docs](./docs/)

No es necesario instalar ningún programa para probar el portal. Basta con un navegador y conexión a Internet.

### Inicio de sesión

| Rol | Correo de prueba | Matrícula |
| --- | --- | --- |
| Administrador | admin@example.com | ADM001 |
| Asesor | asesor1@example.com | DOC101 |
| Alumno | alumno1@example.com | ALU001 |

Las contraseñas de demostración se proporcionan directamente por el equipo; no se publican en el repositorio. Las cuentas contienen datos ficticios.

1. Abrir el portal e ingresar el correo o matrícula y la contraseña correspondiente.
2. Comprobar que aparece el nombre del usuario y el panel de su rol.
3. Cerrar sesión y repetir con los demás roles.
4. Probar una contraseña incorrecta y verificar que se rechaza el acceso.

### Bot de Telegram

Abrir el chat privado con @PoliAsesor_bot y enviar:

| Comando | Respuesta esperada |
| --- | --- |
| `/start` | Mensaje de bienvenida a PoliAsesor. |
| `/ayuda` | Comandos disponibles y funciones en desarrollo. |
| `/prueba` | Aviso de comando desconocido. |

El bot recibe las solicitudes mediante un webhook HTTPS. No requiere que la computadora del equipo esté encendida.

## Tecnologías utilizadas

- HTML5 y CSS3 para las interfaces.
- PHP 8.4 para la autenticación, sesiones y lógica del bot.
- MariaDB y SQL para el almacenamiento de datos; PDO para la conexión desde PHP.
- Telegram Bot API para la comunicación con el bot.
- Alwaysdata para el alojamiento web y la base de datos.
- Figma para el diseño de interfaces y Git/GitHub para el control de versiones.

## Estructura del proyecto

```text
backend/            Funciones de conexión, seguridad y sesiones (app.php).
frontend/           Login, panel, cierre de sesión, estilos y endpoint de Telegram.
bot/                Respuestas a comandos y registro del webhook.
database/           Script SQL del modelo y datos de prueba.
docs/               Entregables E1 a E7 y evidencias.
config.example.php  Plantilla de configuración sin credenciales.
.gitignore          Exclusión de archivos privados.
README.md           Información e instrucciones del proyecto.
```

## Ejecución local (opcional)

Para revisar el código o ejecutar una copia independiente se requiere PHP 8.x de 64 bits con PDO MySQL, sesiones y una instalación de MariaDB. Se puede utilizar el PHP de XAMPP.

1. Clonar el repositorio:

   ```bash
   git clone https://github.com/MarcoVini13/AsesoriaBotGit.git
   cd AsesoriaBotGit
   ```

2. Preparar una base de datos de pruebas propia e importar el [script SQL](./database/Script.sql). Revisar que el nombre de la base de datos del script coincida con el entorno local y quitar las instrucciones de creación o selección de la base si no se tienen los permisos correspondientes. No importar sobre la base de datos del sitio publicado.
3. Copiar `config.example.php` como `config.php` en la raíz del proyecto y configurar los datos de la base local (`db_host`, `db_port`, `db_name`, `db_user` y `db_password`). Establecer `cookie_secure` en `false` únicamente para pruebas locales por HTTP. El token y el secreto del bot pueden permanecer vacíos si solo se prueba el portal.
4. Desde la raíz, iniciar el servidor local:

   ```bash
   php -S 127.0.0.1:8080 -t frontend
   ```

   En Windows, si PHP no está en el PATH y se cuenta con XAMPP, utilizar `C:\xampp\php\php.exe` en lugar de `php`.
5. Abrir [http://127.0.0.1:8080](http://127.0.0.1:8080). Para las cuentas locales, utilizar las credenciales de prueba definidas en el script importado. Estas son independientes de las del portal publicado.

Para una instalación independiente del bot se requiere un bot propio de BotFather, un endpoint HTTPS público, PHP con cURL y un secreto de webhook. Se debe adaptar la URL en `bot/webhook.php` antes de registrar el webhook de ese bot. No es necesario registrar otro webhook para probar el bot de la demostración.

## Seguridad y alcance

El login utiliza consultas preparadas, verificación de contraseñas mediante hash y validación del rol en el servidor. `config.php`, las contraseñas reales y el token de Telegram no deben subirse a GitHub. En el alojamiento web únicamente se publica la carpeta `frontend/`.

En este primer avance todavía no están implementadas la vinculación de cuentas, la consulta y publicación de horarios, las reservas, las cancelaciones, los reportes ni las notificaciones. Estas funciones forman parte del alcance de la entrega final.

## Integrantes

- Almendarez Briones Marco Vinicio
- Flores Gloria David Alejandro
- Vargas Moreno Jared Sebastian
- Sanchez Flores Oscar Paul
