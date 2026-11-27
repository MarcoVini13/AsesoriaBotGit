<?php
declare(strict_types=1);

const ROLES = ['alumno' => 'Alumno', 'asesor' => 'Asesor', 'administrador' => 'Administrador'];

ini_set('display_errors', '0');
header('Cache-Control: no-store');
header('X-Content-Type-Options: nosniff');
header('X-Frame-Options: DENY');

function settings(): array
{
    static $config;
    if ($config === null) {
        $file = dirname(__DIR__) . '/config.php';
        if (!is_file($file)) {
            http_response_code(503);
            exit('Servicio pendiente de configuración.');
        }
        $config = require $file;
    }
    return $config;
}

function db(): PDO
{
    $c = settings();
    $dsn = sprintf('mysql:host=%s;port=%d;dbname=%s;charset=utf8mb4', $c['db_host'], $c['db_port'], $c['db_name']);
    return new PDO($dsn, $c['db_user'], $c['db_password'], [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ]);
}

function startSession(): void
{
    ini_set('session.use_strict_mode', '1');
    ini_set('session.use_only_cookies', '1');
    session_name('poliasesor_sid');
    session_set_cookie_params([
        'path' => '/', 'secure' => settings()['cookie_secure'] ?? true,
        'httponly' => true, 'samesite' => 'Lax',
    ]);
    session_start();
    if (isset($_SESSION['ultimo_acceso']) && time() - $_SESSION['ultimo_acceso'] >= 1800) {
        $_SESSION = [];
        session_regenerate_id(true);
    }
    $_SESSION['csrf'] ??= bin2hex(random_bytes(32));
}

function verifyForm(): void
{
    $token = $_POST['csrf'] ?? null;
    if (!is_string($token) || !hash_equals($_SESSION['csrf'], $token)) {
        http_response_code(403);
        exit('Formulario vencido. Vuelve a abrir la página.');
    }
}

function redirect(string $location): void
{
    header('Location: ' . $location, true, 303);
    exit;
}

function escape(string $value): string
{
    return htmlspecialchars($value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}

function endSession(): void
{
    $_SESSION = [];
    $cookie = session_get_cookie_params();
    unset($cookie['lifetime']);
    setcookie(session_name(), '', ['expires' => time() - 3600] + $cookie);
    session_destroy();
}

function renderTop(string $title): void
{
    ?><!doctype html>
<html lang="es-MX"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title><?= escape($title) ?> · PoliAsesor</title>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap">
<link rel="stylesheet" href="estilos.css"></head><body>
<header><strong>PoliAsesor</strong><span>Universidad Politécnica de San Luis Potosí</span></header><main><?php
}
