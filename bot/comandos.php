<?php
declare(strict_types=1);

function respuestaTelegram(string $texto): ?string
{
    $comando = strtolower(explode(' ', trim($texto), 2)[0]);
    [$comando, $destino] = array_pad(explode('@', $comando, 2), 2, '');
    if ($destino !== '' && $destino !== 'poliasesor_bot') {
        return null;
    }
    return match ($comando) {
        '/start' => "¡Bienvenido a PoliAsesor! Soy el bot de asesorías académicas de la UPSLP. Escribe /ayuda para consultar los comandos.",
        '/ayuda' => "Disponibles ahora:\n/start — Bienvenida\n/ayuda — Ver comandos\n\nEn desarrollo: /vincular, /materias, /horarios, /reservar, /miscitas y /cancelar.",
        default => 'Comando desconocido. Escribe /ayuda para ver las opciones.',
    };
}
