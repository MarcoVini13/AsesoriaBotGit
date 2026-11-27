<?php
require dirname(__DIR__) . '/backend/app.php';
startSession();
$error = '';
$identifier = '';
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    verifyForm();
    $identifier = is_string($_POST['identificador'] ?? null) ? trim($_POST['identificador']) : '';
    $password = $_POST['password'] ?? null;
    $error = 'No se pudo iniciar sesión. Revisa tus datos de acceso.';
    if ($identifier !== '' && strlen($identifier) <= 480 && is_string($password) && $password !== '' && strlen($password) <= 1024 && !str_contains($password, "\0")) {
        try {
            $query = db()->prepare('SELECT id_usuario, password_hash, rol, activo FROM usuarios WHERE correo = ? OR matricula = ? LIMIT 2');
            $query->execute([$identifier, $identifier]);
            $rows = $query->fetchAll();
            $user = count($rows) === 1 ? $rows[0] : null;
            // Un hash de relleno mantiene la verificación incluso para cuentas inexistentes.
            $valid = password_verify($password, $user['password_hash'] ?? '$2y$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2uheWG/igi.');
            if ($valid && $user && (int)$user['activo'] === 1 && isset(ROLES[$user['rol']])) {
                session_regenerate_id(true);
                $_SESSION = ['id' => (int)$user['id_usuario'], 'ultimo_acceso' => time(), 'csrf' => bin2hex(random_bytes(32))];
                redirect('panel.php?rol=' . $user['rol']);
            }
        } catch (PDOException $e) {
            http_response_code(503);
            $error = 'El acceso está temporalmente fuera de servicio. Intenta más tarde.';
        }
    }
}
renderTop('Iniciar sesión');
?>
<section class="card"><h1>Iniciar sesión</h1><p>Accede al portal de asesorías con tu cuenta institucional.</p>
<?php if ($error): ?><p role="alert"><?= escape($error) ?></p><?php endif; ?>
<form method="post"><input type="hidden" name="csrf" value="<?= escape($_SESSION['csrf']) ?>">
<label for="id">Correo o matrícula</label><input id="id" name="identificador" autocomplete="username" maxlength="120" required value="<?= escape($identifier) ?>">
<label for="pw">Contraseña</label><input id="pw" name="password" type="password" autocomplete="current-password" required>
<button>Iniciar sesión</button></form></section></main></body></html>
