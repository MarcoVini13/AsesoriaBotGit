<?php
require dirname(__DIR__) . '/backend/app.php';
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    header('Allow: POST', true, 405);
    exit;
}
startSession();
verifyForm();
endSession();
redirect('index.php');
