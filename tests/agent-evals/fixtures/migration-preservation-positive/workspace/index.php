<?php

$users = $pdo->query('SELECT id, email FROM users')->fetchAll();
foreach ($users as $user) {
    mail($user['email'], 'Update', 'Hello');
}
