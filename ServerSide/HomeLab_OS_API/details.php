<?php
header('Content-Type: text/plain');

// Enable error reporting for debugging (logs to error_log, not displayed)
ini_set('display_errors', 0);
error_reporting(E_ALL);

// Check for query parameters starting with 'about'
if (isset($_GET) && !empty($_GET)) {
    foreach ($_GET as $key => $value) {
        if (strpos($key, 'about') === 0) {
            $about_file = $key . '.txt';
            if (file_exists($about_file)) {
                $content = file_get_contents($about_file);
                if ($content === false) {
                    error_log("Error: Unable to read $about_file");
                    echo "Error: Unable to read $about_file\n";
                } else {
                    echo $content;
                }
            } else {
                error_log("Error: $about_file file not found");
                echo "Error: $about_file file not found\n";
            }
            exit;
        }
    }
}

// Get parameters from URL and trim whitespace
$uuid = isset($_GET['uuid']) ? trim(urldecode($_GET['uuid'])) : '';
$category = isset($_GET['category']) ? trim(urldecode($_GET['category'])) : '';
$bundle = isset($_GET['bundle']);
$sceneid = isset($_GET['sceneid']);
error_log("Received UUID: '$uuid', Category: '$category', Bundle: " . ($bundle ? 'yes' : 'no') . ", SceneID: " . ($sceneid ? 'yes' : 'no'));

// Handle sceneid query
if ($sceneid) {
    $csv_file = 'data/SceneIDs.csv';
    if (!file_exists($csv_file)) {
        error_log("Error: SceneIDs.csv file not found.");
        echo "Error: SceneIDs.csv file not found";
        exit;
    }
    
    $file = fopen($csv_file, 'r');
    if ($file === false) {
        error_log("Error: Unable to open SceneIDs.csv.");
        echo "Error: Unable to open SceneIDs.csv";
        exit;
    }
    
    $found = false;
    $line_number = 0;
    while (($line = fgets($file)) !== false) {
        $line = trim($line);
        $line_number++;
        if (empty($line)) {
            error_log("Line $line_number: Skipped empty line in SceneIDs.csv.");
            continue;
        }
        
        $row = str_getcsv($line, '|');
        if (count($row) < 2) {
            error_log("Line $line_number: Skipped malformed line in SceneIDs.csv (got " . count($row) . " columns).");
            continue;
        }
        
        $folderName = trim($row[0]);
        error_log("Line $line_number: Comparing folderName '$folderName' with UUID '$uuid'");
        
        if ($folderName === $uuid) {
            $found = true;
            error_log("Line $line_number: Match found for UUID '$uuid' in SceneIDs.csv");
            echo $line;
            break;
        }
    }
    fclose($file);
    
    if (!$found) {
        error_log("No match found for UUID '$uuid' in SceneIDs.csv");
        echo "No match found for UUID: $uuid";
    }
    exit;
}

// Validate category and UUID for non-sceneid queries
if (empty($category)) {
    error_log("Error: No category provided.");
    echo "Error: No category provided\n";
    exit;
}
if (empty($uuid)) {
    error_log("Error: No UUID provided.");
    echo "Error: No UUID provided\n";
    exit;
}

// Open PSV file
$psv_file = 'details/' . strtolower(str_replace(' ', '-', $category)) . '.csv';
if (!file_exists($psv_file)) {
    error_log("Error: PSV file '$psv_file' not found.");
    echo "Error: PSV file not found\n";
    exit;
}

$file = fopen($psv_file, 'r');
if ($file === false) {
    error_log("Error: Unable to open PSV file '$psv_file'.");
    echo "Error: Unable to open PSV file\n";
    exit;
}

// Read header
$header_line = fgets($file);
if ($header_line === false) {
    error_log("Error: PSV file is empty.");
    echo "Error: PSV file is empty\n";
    fclose($file);
    exit;
}
$header = str_getcsv(trim($header_line), '|');
error_log("Header columns: " . implode(', ', $header));

// Verify required columns
$required_columns = $bundle ? ['folderName', 'uuids'] : ['folderName', 'niceName', 'niceDesc', 'category', 'PremiumOrReward', 'hdkVersion', 'maker', 'Author'];
$missing_columns = array_diff($required_columns, $header);
if (!empty($missing_columns)) {
    error_log("Error: Missing required columns: " . implode(', ', $missing_columns));
    echo "Error: Missing required columns\n";
    fclose($file);
    exit;
}

// Process PSV lines
$found = false;
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
        error_log("Line $line_number: Skipped malformed line (expected " . count($header) . " columns, got " . count($row) . ").");
        continue;
    }
    
    $row = array_pad($row, count($header), '');
    $row_data = array_combine($header, $row);
    
    $folderName = trim($row_data['folderName']);
    error_log("Line $line_number: Comparing folderName '$folderName' with UUID '$uuid'");
    
    if ($folderName === $uuid) {
        $found = true;
        error_log("Line $line_number: Match found for UUID '$uuid'");
        
        if ($bundle) {
            // Bundle query: process uuids with category filtering
            $uuids = trim($row_data['uuids']);
            if ($uuids === '') {
                error_log("Line $line_number: UUIDs field is empty for UUID '$uuid'");
                echo "No UUIDs found\n";
                break;
            }
            
            // Determine CSV file based on category
            if ($category === 'Male-Bundle') {
                $csv_file = 'data/kMyMale.csv';
            } elseif ($category === 'Female-Bundle') {
                $csv_file = 'data/kMyFemale.csv';
            } else {
                $csv_file = '';
            }
            
            if ($csv_file === '') {
                error_log("Error: Invalid category '$category' for bundle query.");
                echo "Error: Invalid category for bundle query\n";
                break;
            }
            
            if (!file_exists($csv_file)) {
                error_log("Error: CSV file '$csv_file' not found.");
                echo "Error: CSV file not found\n";
                break;
            }
            
            $csv_handle = fopen($csv_file, 'r');
            if ($csv_handle === false) {
                error_log("Error: Unable to open CSV file '$csv_file'.");
                echo "Error: Unable to open CSV file\n";
                break;
            }
            
            // Read CSV header
            $csv_header_line = fgets($csv_handle);
            if ($csv_header_line === false) {
                error_log("Error: CSV file '$csv_file' is empty.");
                echo "Error: CSV file is empty\n";
                fclose($csv_handle);
                break;
            }
            $csv_header = str_getcsv(trim($csv_header_line), '|');
            if (!in_array('id', $csv_header) || !in_array('category', $csv_header)) {
                error_log("Error: Missing 'id' or 'category' column in CSV file '$csv_file'.");
                echo "Error: Missing required columns in CSV file\n";
                fclose($csv_handle);
                break;
            }
            
            // Split UUIDs and prepare to filter
            $uuid_array = array_map('trim', explode(',', $uuids));
            $uuid_categories = [];
            $filtered_uuids = [];
            
            // Read CSV lines
            $csv_line_number = 1;
            while (($csv_line = fgets($csv_handle)) !== false) {
                $csv_line = trim($csv_line);
                $csv_line_number++;
                if (empty($csv_line)) {
                    error_log("CSV Line $csv_line_number: Skipped empty line in '$csv_file'.");
                    continue;
                }
                
                $csv_row = str_getcsv($csv_line, '|');
                if (count($csv_row) < count($csv_header)) {
                    error_log("CSV Line $csv_line_number: Skipped malformed line in '$csv_file' (expected " . count($csv_header) . " columns, got " . count($csv_row) . ").");
                    continue;
                }
                
                $csv_row = array_pad($csv_row, count($csv_header), '');
                $csv_row_data = array_combine($csv_header, $csv_row);
                $csv_id = trim($csv_row_data['id']);
                
                if (in_array($csv_id, $uuid_array)) {
                    $item_category = trim($csv_row_data['category']);
                    error_log("CSV Line $csv_line_number: Found UUID '$csv_id' with category '$item_category' in '$csv_file'");
                    $uuid_categories[$csv_id] = $item_category;
                }
            }
            fclose($csv_handle);
            
            // Filter UUIDs to keep only the first occurrence of each category
            $seen_categories = [];
            foreach ($uuid_array as $uuid_item) {
                if (!isset($uuid_categories[$uuid_item])) {
                    error_log("Warning: UUID '$uuid_item' not found in '$csv_file'. Skipping.");
                    continue;
                }
                $item_category = $uuid_categories[$uuid_item];
                if (!isset($seen_categories[$item_category])) {
                    $seen_categories[$item_category] = true;
                    $filtered_uuids[] = $uuid_item;
                    error_log("Keeping UUID '$uuid_item' for category '$item_category'");
                } else {
                    error_log("Skipping UUID '$uuid_item' due to duplicate category '$item_category'");
                }
            }
            
            // Output filtered UUIDs
            if (empty($filtered_uuids)) {
                error_log("No valid UUIDs after filtering for UUID '$uuid'");
                echo "No UUIDs found\n";
            } else {
                echo implode('|', $filtered_uuids) . "\n";
            }
        } else {
            // Original query: return standard fields
            $output = [
                trim($row_data['folderName']) !== '' ? $row_data['folderName'] : 'None',
                trim($row_data['niceName']) !== '' ? str_replace('|', '\|', $row_data['niceName']) : 'None',
                trim($row_data['niceDesc']) !== '' ? str_replace('|', '\|', substr(trim($row_data['niceDesc']), 0, 180)) : 'None',
                trim($row_data['category']) !== '' ? str_replace('|', '\|', $row_data['category']) : 'None',
                trim($row_data['PremiumOrReward']) !== '' ? $row_data['PremiumOrReward'] : 'None',
                trim($row_data['hdkVersion']) !== '' ? $row_data['hdkVersion'] : 'None',
                trim($row_data['maker']) !== '' ? str_replace('|', '\|', $row_data['maker']) : 'None',
                trim($row_data['Author']) !== '' ? str_replace('|', '\|', $row_data['Author']) : 'None'
            ];
            echo implode('|', $output) . "\n";
        }
        break;
    }
}
fclose($file);

// Handle no match
if (!$found) {
    error_log("Error: No match found for UUID '$uuid' in file '$psv_file'");
    echo "No match found for UUID: $uuid\n";
}
?>