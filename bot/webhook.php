<?php
declare(strict_types=1);

if (PHP_SAPI !== 'cli') {
    http_response_code(404);
    exit;
}
$accion = $argv[1] ?? '';
if (!in_array($accion, ['registrar', 'estado'], true)) {
    exit("Uso: php bot/webhook.php registrar|estado\n");
}
$file = dirname(__DIR__) . '/config.php';
$config = is_file($file) ? require $file : [];
$token = $config['telegram_token'] ?? '';
if (!preg_match('/^[0-9]+:[A-Za-z0-9_-]+$/D', $token) || !extension_loaded('curl')) {
    fwrite(STDERR, "Configura el token y habilita cURL en PHP CLI.\n");
    exit(1);
}
$registrar = $accion === 'registrar';
$params = [];
if ($registrar) {
    $secret = $config['webhook_secret'] ?? '';
    if (!preg_match('/^[A-Za-z0-9_-]{1,256}$/D', $secret)) {
        fwrite(STDERR, "Configura un secreto de webhook válido.\n");
        exit(1);
    }
    $params = ['url' => 'https://poliasesor.alwaysdata.net/telegram.php', 'secret_token' => $secret, 'allowed_updates' => ['message']];
}
$api = curl_init('https://api.telegram.org/bot' . $token . '/' . ($registrar ? 'setWebhook' : 'getWebhookInfo'));
curl_setopt_array($api, [CURLOPT_POST => true, CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
    CURLOPT_POSTFIELDS => json_encode((object)$params), CURLOPT_RETURNTRANSFER => true, CURLOPT_TIMEOUT => 15]);
$data = json_decode((string)curl_exec($api), true);
if (!($data['ok'] ?? false)) {
    fwrite(STDERR, "Telegram no confirmó la operación. Revisa el token, la conexión y el certificado TLS.\n");
    exit(1);
}
if ($registrar) {
    echo "Webhook registrado. Prueba /start en Telegram.\n";
} else {
    $info = $data['result'];
    echo 'URL: ' . $info['url'] . PHP_EOL . 'Pendientes: ' . $info['pending_update_count'] . PHP_EOL;
    echo 'Último error: ' . ($info['last_error_message'] ?? 'ninguno') . PHP_EOL;
}
