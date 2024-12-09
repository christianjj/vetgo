<?php
header('Content-Type: application/json'); // Make sure the response is in JSON format

$servername = "localhost";
$username = "root";
$password = "";
$dbname = "vetgo";

// Create Connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check Connection
if ($conn->connect_error) {
    // Return a JSON response with the error
    echo json_encode(['error' => 'Connection failed: ' . $conn->connect_error]);
    exit();
}

// Use GET method or both GET/POST
if ($_SERVER['REQUEST_METHOD'] == 'GET') {
    // SQL Query to fetch data
    $sql = "SELECT * FROM USER"; // Replace "USER" with your actual table name if needed
    $result = $conn->query($sql);

    // Check if there are results
    if ($result->num_rows > 0) {
        $rows = array();
        while ($row = $result->fetch_assoc()) {
            $rows[] = $row;
        }
        // Return JSON data
        echo json_encode($rows);
    } else {
        // No data found case
        echo json_encode([]);
    }
} else {
    // If the request method is not GET or POST
    echo json_encode(['error' => 'Invalid request method']);
}

$conn->close();
