<?php
// URL of the JSON data
$url = "http://104.37.190.154:61920/GetRooms";

// Path to the PSV file
$psvFile = "data.psv";

// Image URL prefix
$imagePrefix = "http://scee-home.playstation.net/c.home/prod2/live2/Scenes/";

// Function to format uptime
function formatUptime($creationDate) {
    try {
        $time = new DateTime($creationDate, new DateTimeZone('UTC'));
        $now = new DateTime('now', new DateTimeZone('UTC'));
        $interval = $now->diff($time);

        // Calculate total minutes
        $totalMinutes = round(($interval->days * 24 * 60) + ($interval->h * 60) + $interval->i + ($interval->s / 60));

        $hours = floor($totalMinutes / 60);
        $minutes = $totalMinutes % 60;

        return sprintf("%dhr %dm", $hours, $minutes);
    } catch (Exception $e) {
        return "Unknown";
    }
}

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
    header('Content-Type: text/plain');
    echo "ERROR: PSV file not found";
    exit;
}

// Fetch the JSON data
$json = file_get_contents($url);

// Check if data was fetched successfully
if ($json === false) {
    header('Content-Type: text/plain');
    echo "ERROR: Error fetching data";
    exit;
}

// Decode JSON into a PHP array
$data = json_decode($json, true);

// Check if decoding was successful
if (json_last_error() !== JSON_ERROR_NONE) {
    header('Content-Type: text/plain');
    echo "ERROR: Error decoding JSON";
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

                // Get CreationDate and calculate uptime
                $creationDate = isset($session['CreationDate']) ? $session['CreationDate'] : 'Unknown';
                $uptime = $creationDate !== 'Unknown' ? formatUptime($creationDate) : 'Unknown';

                // Look up PSV Name, LargeImage, and Actual Scene Name
                $psvName = isset($psvData[$trimmedDecId]) ? $psvData[$trimmedDecId]['Name'] : 'Not found';
                $largeImage = isset($psvData[$trimmedDecId]) ? $psvData[$trimmedDecId]['LargeImage'] : 'Not found';
                $nameAkaID = isset($psvData[$trimmedDecId]) ? $psvData[$trimmedDecId]['ActualSceneName'] : $lobbyName;
                if (strlen($nameAkaID) > 40) {
                    $nameAkaID = substr($nameAkaID, 0, 38) . '..';
                }
                $imageUrl = $largeImage !== 'Not found' ? $imagePrefix . $largeImage : 'Not found';

                // Store the lobby info
                $lobbies[] = [
                    'TrimmedDecID' => $trimmedDecId,
                    'LobbyName' => $nameAkaID,
                    'PsvName' => $psvName,
                    'AccessType' => $isPublic,
                    'ClientCount' => $clientCount,
                    'ImageUrl' => $imageUrl,
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
$lobbies = array_slice($lobbies, 0, 10);

// Check for query parameters: ?gjs, ?popular, ?picks, or ?favorites
$isSpecialQuery = isset($_GET['gjs']) || isset($_GET['popular']) || isset($_GET['picks']) || isset($_GET['favorites']);

// If any special query is set, duplicate lobbies to ensure exactly 10 items
if ($isSpecialQuery) {
    $outputLobbies = [];
    $lobbyCount = count($lobbies);
    if ($lobbyCount > 0) {
        for ($i = 0; $i < 10; $i++) {
            $outputLobbies[] = $lobbies[$i % $lobbyCount];
        }
    }
    $lobbies = $outputLobbies;
}

// Output as pipe-separated values
header('Content-Type: text/plain');
foreach ($lobbies as $lobby) {
    // Escape pipe characters in LobbyName and PsvName to prevent issues
    $lobbyName = str_replace('|', '\|', $lobby['LobbyName']);
    $psvName = str_replace('|', '\|', $lobby['PsvName']);
    echo implode('|', [
        $lobbyName,
        $psvName,
        $lobby['ImageUrl'],
        $lobby['TrimmedDecID'],
        $lobby['AccessType'],
        $lobby['ClientCount'],
        $lobby['Uptime']
    ]) . "\n";
}
exit;
?>