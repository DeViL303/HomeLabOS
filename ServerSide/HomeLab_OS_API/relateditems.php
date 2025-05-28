<?php
header('Content-Type: text/plain');

// Enable error reporting for debugging (logs to error_log, not displayed)
ini_set('display_errors', 0);
error_reporting(E_ALL);

// Get UUID and page from URL
$uuid = isset($_GET['uuid']) ? trim(urldecode($_GET['uuid'])) : '';
$page = isset($_GET['page']) ? max(1, (int)$_GET['page']) : 1; // Default to page 1, ensure positive
error_log("Received UUID: '$uuid', Page: '$page'");

$psv_file = 'PsHomeDatabase.csv';
$items_per_page = 30;

// Check if UUID is provided
if (empty($uuid)) {
    error_log("Error: No UUID provided.");
    echo "Page 1 of 1   Total Items 0\n";
    exit;
}

// Check if PSV file exists
if (!file_exists($psv_file)) {
    error_log("Error: PSV file '$psv_file' not found.");
    echo "Page 1 of 1   Total Items 0\n";
    exit;
}

// Open file for streaming
$file = fopen($psv_file, 'r');
if ($file === false) {
    error_log("Error: Unable to open PSV file '$psv_file'.");
    echo "Page 1 of 1   Total Items 0\n";
    exit;
}

// Read header
$header_line = fgets($file);
if ($header_line === false) {
    error_log("Error: PSV file is empty.");
    echo "Page 1 of 1   Total Items 0\n";
    fclose($file);
    exit;
}
$header = str_getcsv(trim($header_line), '|');
error_log("Header columns: " . implode(', ', $header));

// Verify required columns
$required_columns = ['folderName', 'niceName', 'category', 'maker', 'PreferredThumbnail', 'uuids'];
$missing_columns = array_diff($required_columns, $header);
if (!empty($missing_columns)) {
    error_log("Error: Missing required columns: " . implode(', ', $missing_columns));
    echo "Page 1 of 1   Total Items 0\n";
    fclose($file);
    exit;
}

// Find the record for the UUID to get niceName, maker, and uuids
$niceName = '';
$maker = '';
$uuids = '';
$found_uuid = false;
$line_number = 1;
while (($line = fgets($file)) !== false) {
    $line = trim($line);
    $line_number++;
    if (empty($line)) {
        error_log("Line $line_number: Skipped empty line.");
        continue;
    }
    
    $row = str_getcsv($line, '|');
    if (count($row) < count($header)) {
        error_log("Line $line_number: Skipped malformed line (expected " . count($header) . " columns, got " . count($row) . "). Line: $line");
        continue;
    }
    
    $row = array_pad($row, count($header), '');
    $row_data = array_combine($header, $row);
    
    $folderName = trim($row_data['folderName']);
    if ($folderName === $uuid) {
        $found_uuid = true;
        $niceName = trim($row_data['niceName']);
        $maker = trim($row_data['maker']);
        $uuids = trim($row_data['uuids']);
        error_log("Line $line_number: Found UUID '$uuid' with niceName '$niceName', maker '$maker', uuids '$uuids'");
        break;
    }
}

// Check if UUID was found
if (!$found_uuid) {
    error_log("No match found for UUID '$uuid'");
    echo "Page 1 of 1   Total Items 0\n";
    fclose($file);
    exit;
}

// Parse uuids field
$uuidArray = array_filter(array_map('trim', explode(',', $uuids)));
error_log("Parsed uuids: " . implode(', ', $uuidArray));

// Calculate the start and end index for the current page
$start_index = ($page - 1) * $items_per_page;
$end_index = $start_index + $items_per_page - 1;

// Collect details for uuids
$items = [];
$total_items = 0;
$current_index = -1;

if (!empty($uuidArray)) {
    rewind($file);
    fgets($file); // Skip header
    $line_number = 1;
    
    while (($line = fgets($file)) !== false) {
        $line = trim($line);
        $line_number++;
        if (empty($line)) {
            error_log("Line $line_number: Skipped empty line.");
            continue;
        }
        
        $row = str_getcsv($line, '|');
        if (count($row) < count($header)) {
            error_log("Line $line_number: Skipped malformed line (expected " . count($header) . " columns, got " . count($row) . "). Line: $line");
            continue;
        }
        
        $row = array_pad($row, count($header), '');
        $row_data = array_combine($header, $row);
        
        $folderName = trim($row_data['folderName']);
        if (in_array($folderName, $uuidArray)) {
            $current_index++;
            $total_items++;
            
            if ($current_index >= $start_index && $current_index <= $end_index) {
                error_log("Line $line_number: Found uuid record for '$folderName' at index $current_index");
                $items[] = [
                    'folderName' => trim($row_data['folderName']) !== '' ? $row_data['folderName'] : 'None',
                    'niceName' => trim($row_data['niceName']) !== '' ? str_replace('|', '\|', $row_data['niceName']) : 'None',
                    'category' => trim($row_data['category']) !== '' ? str_replace('|', '\|', $row_data['category']) : 'None',
                    'PreferredThumbnail' => trim($row_data['PreferredThumbnail']) !== '' ? $row_data['PreferredThumbnail'] : 'P'
                ];
            }
        }
    }
}
error_log("Found $total_items uuid records");

// Clean niceName (mimic JavaScript regex)
$cleanedName = strtolower($niceName);
$cleanedName = preg_replace(
    "/bundle|the |and |for |lmo|ultimate|mega|complete|adult|baby|mini|'|suit |at|with|package|guy|boy|girl|ndream|tabby|b |female|male|player|men|ladies|left|right|earring|both|boot|pants|torso|vibrant|dress|skirt|hat|pack|mag |&|active|object|pair|arcade|avatar|body|lmo |a |is |two|three|four|five|six|silver|golden|gold|platinum|obsidian|crimson|azure|jade|steel|oxide|red|home|green|blue|yellow|white|black|purple|burgandy|orange|pink|brown|piece|bonus|companion|locomotion|animation|color|colour|collection|release|costume|squid|of |set |volume|from/i",
    ' ',
    $cleanedName
);
$cleanedName = preg_replace("/\(\d+\)/", '', $cleanedName); // Remove (123)
$cleanedName = preg_replace("/[-:,]/", ' ', $cleanedName); // Remove punctuation
$cleanedName = preg_replace("/\b\d{1,5}\b/", '', $cleanedName); // Remove 1-5 digit numbers
$cleanedName = preg_replace("/[()]/", '', $cleanedName); // Remove parentheses
$cleanedName = preg_replace("/'s\b/", '', $cleanedName); // Remove 's
$cleanedName = preg_replace("/s\b/", '', $cleanedName); // Remove plural s
$cleanedName = preg_replace("/'\b/", '', $cleanedName); // Remove apostrophes
$cleanedName = preg_replace("/\b(\w+)\d\b/", '$1', $cleanedName); // Remove trailing digits
$cleanedName = trim(preg_replace("/\s+/", ' ', $cleanedName)); // Normalize spaces

// Split into words and limit to first two, plus gender words
$words = explode(' ', $cleanedName);
$genderWords = ['male', 'female', 'men', 'women', 'man', 'woman', 'lady', 'guy'];
$limitedWords = array_slice($words, 0, 2);
$genderPresent = array_intersect($words, $genderWords);
$limitedWords = array_merge($limitedWords, $genderPresent);
$limitedWords = array_unique($limitedWords);
$limitedName = implode(' ', $limitedWords);

// Clean maker
$cleanedMaker = preg_replace("/[-:,]/", ' ', $maker);
$cleanedMaker = trim(preg_replace("/\s+/", ' ', $cleanedMaker));

// Prepare search keywords
$searchKeywords = $limitedName;
$excludedMakers = ['unknown', 'MakerXX'];
if (!in_array(strtolower($cleanedMaker), array_map('strtolower', $excludedMakers))) {
    $searchKeywords .= ' ' . $cleanedMaker;
}
$keywords = array_filter(explode(' ', $searchKeywords));
$lowerCaseKeywords = array_map('strtolower', $keywords);
error_log("Search keywords: " . implode(', ', $lowerCaseKeywords));

// Search for matching records
rewind($file);
fgets($file); // Skip header
$excludedCategories = ['minigame', 'private', 'public', 'nosdat', 'bundle', 'other-', 'nofilesatall', 'system-'];
$line_number = 1;

while (($line = fgets($file)) !== false) {
    $line = trim($line);
    $line_number++;
    if (empty($line)) {
        error_log("Line $line_number: Skipped empty line.");
        continue;
    }
    
    $row = str_getcsv($line, '|');
    if (count($row) < count($header)) {
        error_log("Line $line_number: Skipped malformed line (expected " . count($header) . " columns, got " . count($row) . "). Line: $line");
        continue;
    }
    
    $row = array_pad($row, count($header), '');
    $row_data = array_combine($header, $row);
    
    $folderName = trim($row_data['folderName']);
    
    // Skip if it's the input UUID or in uuidArray
    if ($folderName === $uuid || in_array($folderName, $uuidArray)) {
        error_log("Line $line_number: Skipped input UUID or related UUID '$folderName'");
        continue;
    }
    
    // Check category exclusions
    $category = trim(strtolower($row_data['category']));
    $skip = false;
    foreach ($excludedCategories as $exCat) {
        if (strpos($category, $exCat) !== false) {
            $skip = true;
            break;
        }
    }
    if ($skip) {
        error_log("Line $line_number: Skipped due to excluded category '$category'");
        continue;
    }
    
    // Concatenate all string fields for search
    $searchText = '';
    foreach ($row_data as $key => $value) {
        if (is_string($value) && trim($value) !== '' && $key !== 'uuids') {
            $searchText .= ' ' . strtolower(trim($value));
        }
    }
    
    // Check if all keywords are present
    $allMatch = true;
    foreach ($lowerCaseKeywords as $keyword) {
        if (strpos($searchText, $keyword) === false) {
            $allMatch = false;
            break;
        }
    }
    
    if ($allMatch) {
        $current_index++;
        $total_items++;
        
        if ($current_index >= $start_index && $current_index <= $end_index) {
            error_log("Line $line_number: Match found for folderName '$folderName' at index $current_index");
            $items[] = [
                'folderName' => trim($row_data['folderName']) !== '' ? $row_data['folderName'] : 'None',
                'niceName' => trim($row_data['niceName']) !== '' ? str_replace('|', '\|', $row_data['niceName']) : 'None',
                'category' => trim($row_data['category']) !== '' ? str_replace('|', '\|', $row_data['category']) : 'None',
                'PreferredThumbnail' => trim($row_data['PreferredThumbnail']) !== '' ? $row_data['PreferredThumbnail'] : 'P'
            ];
        }
    }
}
fclose($file);

// Calculate total pages and cap requested page
$total_pages = max(1, ceil($total_items / $items_per_page));
$page = min($page, $total_pages); // Ensure page doesn't exceed total pages

// Output page information
echo "$page|$total_pages|$total_items\n";

// Output results
foreach ($items as $item) {
    echo implode('|', [
        $item['folderName'],
        $item['niceName'],
        $item['PreferredThumbnail'],
        $item['category']
    ]) . "\n";
}
?>