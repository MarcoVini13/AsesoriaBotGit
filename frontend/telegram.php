<?php
require dirname(__DIR__) . '/backend/app.php';
require dirname(__DIR__) . '/bot/comandos.php';
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    header('Allow: POST', true, 405);
    exit;
}
$secret = settings()['webhook_secret'] ?? '';
if ($secret === '' || !hash_equals($secret, $_SERVER['HTTP_X_TELEGRAM_BOT_API_SECRET_TOKEN'] ?? '')) {
    http_response_code(403);
    exit;
}
$update = json_decode(file_get_contents('php://input'), true);
if (!is_array($update) || !is_int($update['update_id'] ?? null)) {
    http_response_code(400);
    exit;
}
$message = $update['message'] ?? [];
$text = $message['text'] ?? null;
$id = $message['chat']['id'] ?? null;
if (!is_string($text) || !is_int($id) || ($reply = respuestaTelegram($text)) === null) {
    http_response_code(204);
    exit;
}
// Telegram ejecuta sendMessage como respuesta al webhook.
header('Content-Type: application/json; charset=utf-8');
echo json_encode(['method' => 'sendMessage', 'chat_id' => $id, 'text' => $reply], JSON_UNESCAPED_UNICODE);
