<?php
// Set response header to plain text for compatibility with Lua client
header('Content-Type: text/plain');

// Initialize response message
$response = '';

// Function to sanitize input to prevent directory traversal and invalid characters
function sanitizeInput($input) {
    // Allow alphanumeric, underscores, hyphens, and @; remove other characters
    return preg_replace('/[^a-zA-Z0-9_@-]/', '', trim($input));
}

// Function to validate SHA-256 hash format (64-character hexadecimal)
function isValidSHA256($hash) {
    return preg_match('/^[0-9a-f]{64}$/i', $hash);
}

// Check if required parameters are provided
$requiredParams = ['sessionid', 'nameiclicked', 'myname', 'spaceiamin', 'instancecode'];
$missingParams = [];
foreach ($requiredParams as $param) {
    if (!isset($_GET[$param])) {
        $missingParams[] = $param;
    }
}
if (!empty($missingParams)) {
    http_response_code(400);
    $response = 'Error: Missing required parameters (' . implode(', ', $missingParams) . ')';
    echo $response;
    exit;
}

// Retrieve and sanitize query parameters
$sessionid = sanitizeInput($_GET['sessionid']);
$nameiclicked = sanitizeInput($_GET['nameiclicked']);
$myname = sanitizeInput($_GET['myname']);
$spaceiamin = sanitizeInput($_GET['spaceiamin']);
$instancecode = sanitizeInput($_GET['instancecode']);

// Validate inputs
if (empty($sessionid) || empty($nameiclicked) || empty($myname) || empty($spaceiamin) || empty($instancecode)) {
    http_response_code(400);
    $response = 'Error: Invalid or empty parameters';
    echo $response;
    exit;
}

// Define directory for storing invite list files
$directory = __DIR__ . '/invites/';
if (!is_dir($directory)) {
    // Create directory if it doesn't exist, with 0755 permissions
    if (!mkdir($directory, 0755, true)) {
        http_response_code(500);
        $response = 'Error: Failed to create directory';
        echo $response;
        exit;
    }
}

// Hash the sessionid using SHA-256
$sessionidHash = hash('sha256', $sessionid);

// Construct filenames
$mainFilename = $directory . $sessionidHash . '_' . $myname . '.txt';
$mynameFilename = $directory . $myname . '.txt';
$invitedDefaultFilename = $directory . $nameiclicked . '.txt';

// Check for a file with SHA256hash_nameiclicked.txt
$invitedPattern = $directory . '*_' . $nameiclicked . '.txt';
$invitedTargetFile = $invitedDefaultFilename;
$matchingFiles = glob($invitedPattern);
foreach ($matchingFiles as $file) {
    $filename = basename($file, '.txt');
    $hash = substr($filename, 0, strlen($filename) - strlen($nameiclicked) - 1);
    if (isValidSHA256($hash)) {
        $invitedTargetFile = $file;
        break; // Use the first valid SHA-256 prefixed file
    }
}

// Get current UTC timestamp
$timestamp = gmdate('Y-m-d H:i:s');

// Write invite info to the main file and the invited user's file
try {
    // Check if myname.txt exists and rename it to sessionidHash_myname.txt if it does
    if (file_exists($mynameFilename) && !file_exists($mainFilename)) {
        if (!rename($mynameFilename, $mainFilename)) {
            throw new Exception('Failed to rename myname.txt to sessionidHash_myname.txt');
        }
    }

    // Open main file in append mode ('a' creates file if it doesn't exist)
    $mainFile = fopen($mainFilename, 'a');
    if ($mainFile === false) {
        throw new Exception('Failed to open or create main file');
    }

    // Write the invite info to the main file
    $line = $nameiclicked . '|' . $myname . '|' . $spaceiamin . '|' . $instancecode . '|' . $timestamp . "\n";
    if (fwrite($mainFile, $line) === false) {
        throw new Exception('Failed to write to main file');
    }

    // Close the main file
    fclose($mainFile);

    // Open invited user's file in append mode ('a' creates file if it doesn't exist)
    $invitedFile = fopen($invitedTargetFile, 'a');
    if ($invitedFile === false) {
        throw new Exception('Failed to open or create invited user file');
    }

    // Write the same invite info to the invited user's file
    if (fwrite($invitedFile, $line) === false) {
        throw new Exception('Failed to write to invited user file');
    }

    // Close the invited user's file
    fclose($invitedFile);

    // Set success response
    $response = 'Success: You have invited ' . $nameiclicked . ' to ' . $spaceiamin;
} catch (Exception $e) {
    http_response_code(500);
    $response = 'Error: ' . $e->getMessage();
}

// Output response
echo $response;
?>