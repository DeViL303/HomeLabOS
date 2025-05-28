<?php
// Check for ?players query parameter
if (isset($_GET['players'])) {
    // URL of the JSON data
    $url = "http://104.37.190.154:61920/GetRooms";
    
    // Path to the PSV file
    $psvFile = "data.psv";

    // Load PSV data into an associative array
    $psvData = [];
    if (file_exists($psvFile)) {
        $lines = file($psvFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
        foreach ($lines as $line) {
            $fields = explode('|', $line);
            if (count($fields) >= 4) {
                $psvData[$fields[0]] = [
                    'ActualSceneName' => $fields[1],
                    'LargeImage' => $fields[2],
                    'Name' => $fields[3]
                ];
            }
        }
    } else {
        echo "ERROR: PSV file not found\n";
        exit;
    }
    
    // Fetch the JSON data
    $json = file_get_contents($url);
    
    // Check if data was fetched successfully
    if ($json === false) {
        echo "ERROR: Error fetching data\n";
        exit;
    }
    
    // Decode JSON into a PHP array
    $data = json_decode($json, true);
    
    // Check if decoding was successful
    if (json_last_error() !== JSON_ERROR_NONE) {
        echo "ERROR: Error decoding JSON\n";
        exit;
    }
    
    // Output usernames with their lobby name or InPrivateSpace, one per line
    header('Content-Type: text/plain');
    if (isset($data['usernames']) && is_array($data['usernames'])) {
        // Find AppId 20374 to scan for player names
        $lobbyNames = [];
        foreach ($data['rooms'] as $room) {
            if ($room['AppId'] === '20374') {
                foreach ($room['Worlds'] as $world) {
                    foreach ($world['GameSessions'] as $session) {
                        $nameParts = explode('|', $session['Name']);
                        $decId = $nameParts[2]; // e.g., 00130
                        // Trim leading zeros from DecID for PSV lookup
                        $trimmedDecId = ltrim($decId, '0');
                        // Look up ActualSceneName from PSV data, default to InPrivateSpace if not found
                        $lobbyName = isset($psvData[$trimmedDecId]) ? $psvData[$trimmedDecId]['ActualSceneName'] : 'InPrivateSpace';
                        foreach ($session['Clients'] as $client) {
                            $clientName = $client['Name'];
                            // Strip <Secure> tags if present
                            if (strpos($clientName, '<Secure') !== false) {
                                preg_match('/<Secure[^>]*>(.*?)<\\/Secure>/', $clientName, $matches);
                                $clientName = $matches[1] ?? $clientName;
                            }
                            $lobbyNames[$clientName] = $lobbyName;
                        }
                    }
                }
                break;
            }
        }
        
        // Output each username with corresponding lobby name or InPrivateSpace
        foreach ($data['usernames'] as $user) {
            $username = $user['Key'];
            $lobby = isset($lobbyNames[$username]) ? $lobbyNames[$username] : 'InPrivateSpace';
            echo $username . '|' . $lobby . "\n";
        }
    }
    exit;
}

// Check for ?popular query parameter
if (isset($_GET['popular'])) {
    $csvFile = "populartoday.csv";
    
    // Check if the CSV file exists
    if (file_exists($csvFile)) {
        header('Content-Type: text/plain');
        // Read and output the CSV file contents
        $lines = file($csvFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
        foreach ($lines as $line) {
            echo $line . "\n";
        }
        exit;
    } else {
        echo "ERROR: populartoday.csv file not found\n";
        exit;
    }
}

// Check for ?picks query parameter
if (isset($_GET['picks'])) {
    $csvFile = "ourpicks.csv";
    
    // Check if the CSV file exists
    if (file_exists($csvFile)) {
        header('Content-Type: text/plain');
        // Read and output the CSV file contents
        $lines = file($csvFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
        foreach ($lines as $line) {
            echo $line . "\n";
        }
        exit;
    } else {
        echo "ERROR: ourpicks.csv file not found\n";
        exit;
    }
}

// URL of the JSON data
$url = "http://104.37.190.154:61920/GetRooms";

// Path to the PSV file
$psvFile = "data.psv";

// Load PSV data into an associative array
$psvData = [];
if (file_exists($psvFile)) {
    $lines = file($psvFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        $fields = explode('|', $line);
        if (count($fields) >= 4) {
            $psvData[$fields[0]] = [
                'ActualSceneName' => $fields[1],
                'LargeImage' => $fields[2],
                'Name' => $fields[3]
            ];
        }
    }
} else {
    echo "ERROR: PSV file not found\n";
    exit;
}

// Fetch the JSON data
$json = file_get_contents($url);

// Check if data was fetched successfully
if ($json === false) {
    echo "ERROR: Error fetching data\n";
    exit;
}

// Decode JSON into a PHP array
$data = json_decode($json, true);

// Check if decoding was successful
if (json_last_error() !== JSON_ERROR_NONE) {
    echo "ERROR: Error decoding JSON\n";
    exit;
}

// Find the rooms under AppId 20374
$targetAppId = "20374";
$lobbies = [];

foreach ($data['rooms'] as $room) {
    if ($room['AppId'] === $targetAppId) {
        foreach ($room['Worlds'] as $world) {
            foreach ($world['GameSessions'] as $session) {
                // Extract the Name field and parse it
                $name = $session['Name'];
                $nameParts = explode('|', $name);
                $accessType = $nameParts[0]; // AP or PS
                $decId = $nameParts[2]; // e.g., 00082
                $lobbyName = $nameParts[5]; // e.g., BasicApartment

                // Trim leading zeros from DecID for PSV lookup
                $trimmedDecId = ltrim($decId, '0');

                // Determine if public or private
                $isPublic = $accessType === 'PS' ? 'Public' : 'Private';

                // Count clients
                $clientCount = count($session['Clients']);

                // Calculate uptime from CreationDate
                $creationDate = new DateTime($session['CreationDate']);
                $currentTime = new DateTime();
                $interval = $currentTime->diff($creationDate);
                $uptime = sprintf("%dh %dm", $interval->h + ($interval->d * 24), $interval->i);

                // Look up PSV Name, LargeImage, and Actual Scene NAME
                $psvName = isset($psvData[$trimmedDecId]) ? $psvData[$trimmedDecId]['Name'] : $lobbyName;
                $largeImage = isset($psvData[$trimmedDecId]) ? $psvData[$trimmedDecId]['LargeImage'] : 'PackagedScenes/large_T003.png';
                $nameAkaID = isset($psvData[$trimmedDecId]) ? $psvData[$trimmedDecId]['ActualSceneName'] : $lobbyName;
                if (strlen($nameAkaID) > 40) {
                    $nameAkaID = substr($nameAkaID, 0, 38) . '..';
                }

                // Store the lobby info
                $lobbies[] = [
                    'TrimmedDecID' => $trimmedDecId,
                    'LobbyName' => $nameAkaID,
                    'AccessType' => $isPublic,
                    'ClientCount' => $clientCount,
                    'PsvName' => $psvName,
                    'ImageUrl' => $largeImage,
                    'Uptime' => $uptime
                ];
            }
        }
    }
}

// Sort lobbies by ClientCount in descending order
usort($lobbies, function($a, $b) {
    return $b['ClientCount'] - $a['ClientCount'];
});

// Limit to top 10 lobbies
$lobbiesForOutput = array_slice($lobbies, 0, 10);

// Output as pipe-separated values without header
header('Content-Type: text/plain');
foreach ($lobbiesForOutput as $lobby) {
    // Escape pipe characters in fields to prevent delimiter issues
    $fields = [
        $lobby['TrimmedDecID'],
        str_replace('|', '\|', $lobby['PsvName']),
        str_replace('|', '\|', $lobby['LobbyName']),
        $lobby['AccessType'],
        $lobby['ClientCount'],
        str_replace('|', '\|', $lobby['ImageUrl']),
        $lobby['Uptime']
    ];
    echo implode('|', $fields) . "\n";
}
exit;
?>