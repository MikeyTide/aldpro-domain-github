<?php
$key = $_POST['key'];
host=""
port=""
dbname=""
user=""
password=""
$conn = pg_connect("host=$host port=$port dbname=$dbname user=$user password=$password");
$sql = "DELETE FROM keys WHERE key_value = '$key'";
pg_query($conn,$sql);
?>