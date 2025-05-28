<?php
// URL of the JSON data
$url = "http://104.37.190.154:61920/GetRooms";

// Path to the PSV file
$psvFile = "data.psv";

// Path to the output XML files
$lobbiesXmlFile = "lobbies.xml";
$popularXmlFile = "populartoday.xml";

// Image URL prefix
$imagePrefix = "http://scee-home.playstation.net/c.home/prod2/live2/Scenes/";

// Y-positions for each row
$yPositions = [40, 108, 176, 244, 312, 380, 448, 516, 584, 652];

// Function to format time difference (used only for lobbies.xml if needed elsewhere)
function formatTimeAgo($timestamp) {
    try {
        $time = new DateTime("@$timestamp", new DateTimeZone('UTC'));
        $now = new DateTime('now', new DateTimeZone('UTC'));
        $interval = $now->diff($time);

        $hours = $interval->h + ($interval->d * 24);
        $minutes = $interval->i;

        if ($hours > 0) {
            return sprintf("%dhr %dm", $hours, $minutes);
        } elseif ($minutes > 0) {
            return sprintf("%dm", $minutes);
        } else {
            return "0m";
        }
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
    header('Content-Type: application/xml');
    echo '<?xml version="1.0" encoding="UTF-8"?><ERROR>PSV file not found</ERROR>';
    exit;
}

// Fetch the JSON data
$json = file_get_contents($url);

// Check if data was fetched successfully
if ($json === false) {
    header('Content-Type: application/xml');
    echo '<?xml version="1.0" encoding="UTF-8"?><ERROR>Error fetching data</ERROR>';
    exit;
}

// Decode JSON into a PHP array
$data = json_decode($json, true);

// Check if decoding was successful
if (json_last_error() !== JSON_ERROR_NONE) {
    header('Content-Type: application/xml');
    echo '<?xml version="1.0" encoding="UTF-8"?><ERROR>Error decoding JSON</ERROR>';
    exit;
}

// Find the rooms under AppId 20374
$targetAppId = "20374";
$lobbies = [];
$popularLobbiesEligible = []; // Separate array for populartoday.xml eligible lobbies

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

                // Get CreationDate
                $creationDate = isset($session['CreationDate']) ? $session['CreationDate'] : '';

                // Look up PSV Name, LargeImage, and Actual Scene NAME
                $psvName = isset($psvData[$trimmedDecId]) ? $psvData[$trimmedDecId]['Name'] : 'Not found';
                $largeImage = isset($psvData[$trimmedDecId]) ? $psvData[$trimmedDecId]['LargeImage'] : 'Not found';
                $nameAkaID = isset($psvData[$trimmedDecId]) ? $psvData[$trimmedDecId]['ActualSceneName'] : $lobbyName;
                if (strlen($nameAkaID) > 40) {
                    $nameAkaID = substr($nameAkaID, 0, 38) . '..';
                }
                $imageUrl = $largeImage !== 'Not found' ? $imagePrefix . $largeImage : 'Not found';

                // Store the lobby info for lobbies.xml
                $lobbies[] = [
                    'TrimmedDecID' => $trimmedDecId,
                    'LobbyName' => $nameAkaID,
                    'AccessType' => $isPublic,
                    'ClientCount' => $clientCount,
                    'PsvName' => $psvName,
                    'ImageUrl' => $imageUrl,
                    'CreationDate' => $creationDate
                ];

                // Store in popularLobbiesEligible only if ID is not 82, not > 1999, and is Public
                if ($trimmedDecId !== '82' && (int)$trimmedDecId <= 1999 && $isPublic === 'Public') {
                    $popularLobbiesEligible[] = [
                        'TrimmedDecID' => $trimmedDecId,
                        'LobbyName' => $nameAkaID,
                        'AccessType' => $isPublic,
                        'ClientCount' => $clientCount,
                        'PsvName' => $psvName,
                        'ImageUrl' => $imageUrl,
                        'CreationDate' => $creationDate
                    ];
                }
            }
        }
    }
}

// Sort lobbies by ClientCount in descending order for lobbies.xml
usort($lobbies, function($a, $b) {
    return $b['ClientCount'] - $a['ClientCount'];
});

// Limit to top 10 lobbies for lobbies.xml
$lobbiesForXml = array_slice($lobbies, 0, 10);

// Generate lobbies.xml content
$lobbiesXmlContent = '<?xml version="1.0" encoding="UTF-8"?>' . "\n";
$lobbiesXmlContent .= <<<XML
<XML>
    <PAGE>
        <RECT X="0" Y="5" W="1300" H="35" col="#333333"/>
        <TEXT X="15" Y="8" col="#FFFF00" size="2">Thumbnail</TEXT>
        <TEXT X="180" Y="8" col="#FFFF00" size="2">ID</TEXT>
        <TEXT X="280" Y="8" col="#FFFF00" size="2">Currently Active Lobbies</TEXT>
        <TEXT X="980" Y="8" col="#FFFF00" size="2">Lobby Type</TEXT>
        <TEXT X="1180" Y="8" col="#FFFF00" size="2">Players</TEXT>
XML;

for ($index = 0; $index < 10; $index++) {
    $yPos = $yPositions[$index];
    $imgY = $yPos + 1;
    $textY = $yPos + 22;
    $rectColor = ($index % 2 === 0) ? '#222222' : '#2A2A2A';

    $lobbiesXmlContent .= <<<XML

        <RECT X="0" Y="$yPos" W="1300" H="68" col="$rectColor"/>
XML;

    if (isset($lobbiesForXml[$index])) {
        $lobby = $lobbiesForXml[$index];
        $xmlLobbyName = htmlspecialchars($lobby['PsvName'] . ' [' . $lobby['LobbyName'] . ']');
        
        $lobbiesXmlContent .= <<<XML
        <IMG X="10" Y="$imgY" W="121" H="66">{$lobby['ImageUrl']}</IMG>
        <TEXT X="180" Y="$textY" col="#FFFFFF" size="2">{$lobby['TrimmedDecID']}</TEXT>
        <TEXT X="280" Y="$textY" col="#FFFFFF" size="2">$xmlLobbyName</TEXT>
        <TEXT X="980" Y="$textY" col="#FFFFFF" size="2">{$lobby['AccessType']}</TEXT>
        <TEXT X="1180" Y="$textY" col="#FFFFFF" size="2">{$lobby['ClientCount']}</TEXT>
XML;
    }
}

$lobbiesXmlContent .= "\n    </PAGE>\n</XML>";

// Save lobbies.xml
if (file_put_contents($lobbiesXmlFile, $lobbiesXmlContent) === false) {
    header('Content-Type: application/xml');
    echo '<?xml version="1.0" encoding="UTF-8"?><ERROR>Error writing to lobbies XML file</ERROR>';
    exit;
}

// Manage populartoday.xml
$popularLobbies = [];

// Load existing populartoday.xml if it exists
if (file_exists($popularXmlFile)) {
    $xml = simplexml_load_file($popularXmlFile);
    if ($xml !== false) {
        foreach ($xml->PAGE->TEXT as $text) {
            $x = (string)$text['X'];
            $y = (string)$text['Y'];
            if ($x == '180' && $y != '8') { // ID field, exclude header
                $id = (string)$text;
                // Skip IDs 82 or greater than 1999
                if ($id == '82' || (int)$id > 1999) {
                    continue;
                }
                $lobbyName = '';
                $accessType = '';
                $imageUrl = '';
                $psvName = '';
                $addedTime = time(); // Default to current time

                // Find corresponding elements in the same row
                $textY = $y;
                foreach ($xml->PAGE->TEXT as $t) {
                    if ((string)$t['Y'] == $textY) {
                        if ((string)$t['X'] == '280') {
                            $lobbyName = (string)$t;
                            // Extract PsvName and LobbyName
                            if (preg_match('/^(.*?)\s*\[(.*?)\]$/', $lobbyName, $matches)) {
                                $psvName = $matches[1];
                                $lobbyName = $matches[2];
                            }
                        }
                        if ((string)$t['X'] == '950' || (string)$t['X'] == '980') { // Handle possible old X values
                            $accessType = (string)$t;
                        }
                    }
                }
                foreach ($xml->PAGE->IMG as $img) {
                    if ((string)$img['Y'] == (string)($y - 21)) { // IMG Y is textY - 21
                        $imageUrl = (string)$img;
                    }
                }

                // Only include if AccessType is Public
                if ($accessType === 'Public') {
                    $popularLobbies[] = [
                        'TrimmedDecID' => $id,
                        'LobbyName' => $lobbyName,
                        'AccessType' => $accessType,
                        'PsvName' => $psvName,
                        'ImageUrl' => $imageUrl,
                        'AddedTime' => $addedTime
                    ];
                }
            }
        }
    }
}

// Add all eligible active lobbies, avoiding duplicates, and maintain 10 entries
$currentTime = time();

foreach ($popularLobbiesEligible as $lobby) {
    $isDuplicate = false;
    foreach ($popularLobbies as $existingLobby) {
        if ($existingLobby['TrimmedDecID'] === $lobby['TrimmedDecID'] &&
            $existingLobby['LobbyName'] === $lobby['LobbyName']) {
            $isDuplicate = true;
            break;
        }
    }

    if (!$isDuplicate) {
        $newLobby = [
            'TrimmedDecID' => $lobby['TrimmedDecID'],
            'LobbyName' => $lobby['LobbyName'],
            'AccessType' => $lobby['AccessType'],
            'PsvName' => $lobby['PsvName'],
            'ImageUrl' => $lobby['ImageUrl'],
            'AddedTime' => $currentTime
        ];

        $popularLobbies[] = $newLobby;
    }
}

// Sort popularLobbies by AddedTime (oldest first, longest duration at top)
usort($popularLobbies, function($a, $b) {
    return $a['AddedTime'] - $b['AddedTime'];
});

// Limit to exactly 10 entries, removing oldest if necessary
$popularLobbies = array_slice($popularLobbies, -10, 10);

// Generate populartoday.xml content
$popularXmlContent = '<?xml version="1.0" encoding="UTF-8"?>' . "\n";
$popularXmlContent .= <<<XML
<XML>
    <PAGE>
        <RECT X="0" Y="5" W="1300" H="35" col="#333333"/>
        <TEXT X="15" Y="8" col="#FFFF00" size="2">Thumbnail</TEXT>
        <TEXT X="180" Y="8" col="#FFFF00" size="2">ID</TEXT>
        <TEXT X="280" Y="8" col="#FFFF00" size="2">Popular on Home Laboratory</TEXT>
        <TEXT X="980" Y="8" col="#FFFF00" size="2">Lobby Type</TEXT>
        <TEXT X="1170" Y="8" col="#FFFF00" size="2">Last Active</TEXT>
XML;

for ($index = 0; $index < 10; $index++) {
    $yPos = $yPositions[$index];
    $imgY = $yPos + 1;
    $textY = $yPos + 22;
    $rectColor = ($index % 2 === 0) ? '#222222' : '#2A2A2A';

    $popularXmlContent .= <<<XML

        <RECT X="0" Y="$yPos" W="1300" H="68" col="$rectColor"/>
XML;

    if (isset($popularLobbies[$index])) {
        $lobby = $popularLobbies[$index];
        // Trim PsvName to 35 chars and add ... if longer
        $trimmedPsvName = $lobby['PsvName'];
        if (strlen($trimmedPsvName) > 45) {
            $trimmedPsvName = substr($trimmedPsvName, 0, 40) . '...';
        }
        $fullLobbyName = htmlspecialchars($trimmedPsvName . ' [' . $lobby['LobbyName'] . ']');
        
        $popularXmlContent .= <<<XML
        <IMG X="10" Y="$imgY" W="121" H="66">{$lobby['ImageUrl']}</IMG>
        <TEXT X="180" Y="$textY" col="#FFFFFF" size="2">{$lobby['TrimmedDecID']}</TEXT>
        <TEXT X="280" Y="$textY" col="#FFFFFF" size="2">$fullLobbyName</TEXT>
        <TEXT X="980" Y="$textY" col="#FFFFFF" size="2">{$lobby['AccessType']}</TEXT>
        <TEXT X="1180" Y="$textY" col="#FFFFFF" size="2">Today</TEXT>
XML;
    }
}

$popularXmlContent .= "\n    </PAGE>\n</XML>";

// Save populartoday.xml
if (file_put_contents($popularXmlFile, $popularXmlContent) === false) {
    header('Content-Type: application/xml');
    echo '<?xml version="1.0" encoding="UTF-8"?><ERROR>Error writing to populartoday XML file</ERROR>';
    exit;
}

// Output lobbies.xml
header('Content-Type: application/xml');
echo $lobbiesXmlContent;
exit;
?>