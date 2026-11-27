<?php
require dirname(__DIR__) . '/backend/app.php';
startSession();
if (!isset($_SESSION['id'])) {
    redirect('index.php');
}
try {
    $query = db()->prepare('SELECT nombre_completo, rol, activo FROM usuarios WHERE id_usuario = ?');
    $query->execute([$_SESSION['id']]);
    $user = $query->fetch();
} catch (PDOException $e) {
    http_response_code(503);
    exit('No se pudo verificar la sesión. Intenta más tarde.');
}
if (!$user || !(int)$user['activo'] || !isset(ROLES[$user['rol']])) {
    endSession();
    redirect('index.php');
}
$role = $user['rol'];
if (($_GET['rol'] ?? $role) !== $role) {
    http_response_code(403);
    exit('Tu cuenta no tiene acceso a este panel.');
}
$_SESSION['ultimo_acceso'] = time();
$titles = ['alumno' => 'Portal del alumno', 'asesor' => 'Panel del asesor', 'administrador' => 'Panel de administración'];
renderTop($titles[$role]);
?>
<section class="card"><span class="status">Sesión activa</span><h1><?= $titles[$role] ?></h1>
<p>Bienvenido, <strong><?= escape($user['nombre_completo']) ?></strong>.</p>
<p>Rol de acceso: <?= ROLES[$role] ?></p>
<form method="post" action="salir.php"><input type="hidden" name="csrf" value="<?= escape($_SESSION['csrf']) ?>"><button>Cerrar sesión</button></form>
</section></main></body></html>
