<?php
// Получение ключа из CURL-запроса
$key = $_POST['key'];
// Подключение к базе данных MySQL
host=""
port=""
dbname=""
user=""
password=""
$conn = pg_connect("host=$host port=$port dbname=$dbname user=$user password=$password");


// Проверка соединения на ошибку
//if ($conn->connect_error) {
//    die("Connection failed: " . $conn->connect_error);
//}

// Запрос к базе данных для проверки наличия ключа
$sql = "SELECT * FROM keys WHERE key_value = '$key'";
$result = pg_query($conn,$sql);
// Проверка результата запроса
if (pg_num_rows($result) > 0) {
    // Если ключ найден, выдаем ответ "true"
    echo "true";
} else {
    // Если ключ не найден, выдаем ответ "false"
    echo "false";
}

// Закрытие соединения с базой данных
$conn->pg_close();
?>
