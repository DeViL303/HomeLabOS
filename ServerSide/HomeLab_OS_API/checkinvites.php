<?php
// Set response header to plain text
header('Content-Type: text/plain');

// Initialize response message
$response = '';

// Function to sanitize input to prevent directory traversal and invalid characters
function sanitizeInput($input) {
    // Allow alphanumeric, underscores, hyphens, and @; remove other characters
    return preg_replace('/[^a-zA-Z0-9_@-]/', '', trim($input));
}

// Function to calculate time difference as a string (e.g., "5h 35m")
function getTimeDifference($timestamp) {
    try {
        // Parse timestamp in UTC
        $dateTime = new DateTime($timestamp, new DateTimeZone('UTC'));
        // Get current time in UTC
        $now = new DateTime('now', new DateTimeZone('UTC'));
        $interval = $now->diff($dateTime);
        
        // Calculate total minutes
        $totalMinutes = ($interval->days * 24 * 60) + ($interval->h * 60) + $interval->i;
        
        // Round to nearest minute
        $totalMinutes = round($totalMinutes);
        
        // Calculate hours and remaining minutes
        $hours = floor($totalMinutes / 60);
        $minutes = $totalMinutes % 60;
        
        // Return formatted string
        return $hours . 'h ' . $minutes . 'm';
    } catch (Exception $e) {
        // Return original timestamp if parsing fails
        return $timestamp;
    }
}

// Retrieve and sanitize query parameters
$sessionid = isset($_GET['sessionid']) ? sanitizeInput($_GET['sessionid']) : '';
$type = isset($_GET['type']) ? sanitizeInput($_GET['type']) : '';
$myname = isset($_GET['myname']) ? sanitizeInput($_GET['myname']) : '';
$name = isset($_GET['name']) ? sanitizeInput($_GET['name']) : '';
$instancecode = isset($_GET['instancecode']) ? trim($_GET['instancecode']) : '';
$delete = isset($_GET['delete']) && $_GET['delete'] === 'true';

// Check required parameters based on query type
$missingParams = [];
if ($delete) {
    // For delete queries, require sessionid, type, name, instancecode
    $requiredParams = ['sessionid', 'type', 'name', 'instancecode'];
    foreach ($requiredParams as $param) {
        if (empty($$param)) {
            $missingParams[] = $param;
        }
    }
} else {
    // For non-delete queries, require sessionid, myname, type
    $requiredParams = ['sessionid', 'myname', 'type'];
    foreach ($requiredParams as $param) {
        if (empty($$param)) {
            $missingParams[] = $param;
        }
    }
}

if (!empty($missingParams)) {
    http_response_code(400);
    $response = 'Error: Missing required parameters (' . implode(', ', $missingParams) . ')';
    echo $response;
    exit;
}

// Validate type parameter
if ($type !== 'sent' && $type !== 'received') {
    http_response_code(400);
    $response = 'Error: Invalid type parameter, must be "sent" or "received"';
    echo $response;
    exit;
}

// Define directory for invite files
$directory = __DIR__ . '/invites/';
if (!is_dir($directory)) {
    http_response_code(404);
    $response = 'Error: Invites directory does not exist';
    echo $response;
    exit;
}

// Hash the sessionid using SHA-256
$sessionidHash = hash('sha256', $sessionid);

// Handle delete=true case
if ($delete) {
    // Find files containing the sessionid hash
    $files = glob($directory . '*' . $sessionidHash . '*.txt');
    $modified = false;
    $linesToDelete = [];

    // First pass: Find matching lines in sessionid hash files
    foreach ($files as $file) {
        try {
            // Read file content
            $lines = file($file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
            if ($lines === false) {
                continue;
            }

            $newLines = [];
            $fileModified = false;

            // Process each line
            foreach ($lines as $line) {
                // Skip already deleted lines
                if (strpos($line, '#DELETED') === 0) {
                    $newLines[] = $line;
                    continue;
                }

                // Check if line starts with name and contains instancecode
                if (strpos($line, $name . '|') === 0 && strpos($line, $instancecode) !== false) {
                    // Store the exact line for deletion
                    $linesToDelete[] = $line;
                    $newLines[] = '#DELETED ' . $line;
                    $fileModified = true;
                } else {
                    $newLines[] = $line;
                }
            }

            // Write back to file if modified
            if ($fileModified) {
                $result = file_put_contents($file, implode("\n", $newLines) . "\n");
                if ($result !== false) {
                    $modified = true;
                }
            }
        } catch (Exception $e) {
            // Log error but continue processing other files
            error_log('Error processing file ' . $file . ': ' . $e->getMessage());
        }
    }

    // Second pass: Check all txt files for identical lines
    if (!empty($linesToDelete)) {
        $allFiles = glob($directory . '*.txt');
        foreach ($allFiles as $file) {
            // Skip files already processed (those with sessionid hash)
            if (strpos($file, $sessionidHash) !== false) {
                continue;
            }

            try {
                // Read file content
                $lines = file($file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
                if ($lines === false) {
                    continue;
                }

                $newLines = [];
                $fileModified = false;

                // Process each line
                foreach ($lines as $line) {
                    // Skip already deleted lines
                    if (strpos($line, '#DELETED') === 0) {
                        $newLines[] = $line;
                        continue;
                    }

                    // Check for exact match with any line to delete
                    if (in_array($line, $linesToDelete, true)) {
                        $newLines[] = '#DELETED ' . $line;
                        $fileModified = true;
                        $modified = true;
                    } else {
                        $newLines[] = $line;
                    }
                }

                // Write back to file if modified
                if ($fileModified) {
                    $result = file_put_contents($file, implode("\n", $newLines) . "\n");
                    if ($result === false) {
                        error_log('Error writing to file ' . $file);
                    }
                }
            } catch (Exception $e) {
                // Log error but continue processing other files
                error_log('Error processing file ' . $file . ': ' . $e->getMessage());
            }
        }
    }

    // Set response based on whether any files were modified
    $response = $modified ? 'Success: Matching invite(s) deleted' : 'No matching invites found to delete';
    echo $response;
    exit;
}

// Construct file path for non-delete case
$filename = $directory . $sessionidHash . '_' . $myname . '.txt';

// Check if file exists
if (!file_exists($filename)) {
    http_response_code(404);
    $response = 'Error: File not found';
    echo $response;
    exit;
}

// Read and process the file
try {
    $lines = [];
    $file = fopen($filename, 'r');
    if ($file === false) {
        throw new Exception('Failed to open file');
    }

    // Read all lines, skipping deleted ones
    while (!feof($file)) {
        $line = fgets($file);
        if ($line !== false && trim($line) !== '') {
            $trimmedLine = trim($line);
            // Skip lines starting with #DELETED
            if (strpos($trimmedLine, '#DELETED') !== 0) {
                $lines[] = $trimmedLine;
            }
        }
    }
    fclose($file);

    // Filter lines based on type
    $filteredLines = [];
    if ($type === 'sent') {
        // Include lines that do NOT start with myname
        foreach ($lines as $line) {
            if (strpos($line, $myname . '|') !== 0) {
                $filteredLines[] = $line;
            }
        }
    } else {
        // Include lines that DO start with myname
        foreach ($lines as $line) {
            if (strpos($line, $myname . '|') === 0) {
                $filteredLines[] = $line;
            }
        }
    }

    // Process lines to replace timestamp with time difference and swap names for received invites
    $processedLines = [];
    foreach ($filteredLines as $line) {
        $parts = explode('|', $line);
        if (count($parts) >= 5) {
            // Replace timestamp with time difference
            $parts[4] = getTimeDifference($parts[4]);
            // Swap names for received invites
            if ($type === 'received') {
                $temp = $parts[0];
                $parts[0] = $parts[1];
                $parts[1] = $temp;
            }
            $processedLines[] = implode('|', $parts);
        } else {
            // If line format is unexpected, include as is
            $processedLines[] = $line;
        }
    }

    // Get the last 7 lines (or fewer if less than 7)
    $lastSeven = array_slice($processedLines, -7);

    // If no matching lines found
    if (empty($lastSeven)) {
        $response = '0';
    } else {
        // Set response to the matching lines
        $response = implode("\n", $lastSeven);
    }
} catch (Exception $e) {
    http_response_code(500);
    $response = 'Error: ' . $e->getMessage();
}

// Output response
echo $response;
?>