<?php
$users = $db->query('SELECT id, email FROM users');
foreach ($users as $user) {
    echo $user['email'];
}
