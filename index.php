<?php
function getGreeting() {
    return "Hello World!!";
}

$greeting = getGreeting();
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PHP Hello World</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        }
        .container {
            text-align: center;
            padding: 2rem;
            background: white;
            border-radius: 10px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
        }
        h1 {
            color: #333;
            margin: 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1><?php echo $greeting; ?></h1>
        <p>This is a simple dockerized PHP application</p>
    </div>
</body>
</html>