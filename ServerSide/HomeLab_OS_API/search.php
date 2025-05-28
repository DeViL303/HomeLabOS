<?php
header('Content-Type: text/plain');

try {
    // Check query string length
    if (strlen($_SERVER['QUERY_STRING']) > 100) {
        http_response_code(400);
        echo "Error: Query string too long\n";
        exit;
    }

    // Get query parameters
    $category_query = isset($_GET['c']) ? trim(urldecode($_GET['c'])) : '';
    $search_query = isset($_GET['q']) ? trim(urldecode($_GET['q'])) : '';
    $session_id = isset($_GET['session']) ? trim(urldecode($_GET['session'])) : '';
    $page = isset($_GET['page']) ? max(1, (int)$_GET['page']) : 1;
    $uuid = isset($_GET['uuid']) ? trim(urldecode($_GET['uuid'])) : '';
    $is_add = isset($_GET['add']);
    $is_remove = isset($_GET['remove']);
    $search_words = array_filter(array_map('strtolower', explode('+', str_replace(' ', '+', $search_query))));

    // Handle add or remove item request
    if (!empty($uuid) && ($is_add || $is_remove)) {
        // Validate session_id
        if (empty($session_id)) {
            http_response_code(400);
            echo "Error: Missing session ID\n";
            exit;
        }

        // Validate UUID format (8-8-8-8, hex characters only)
        if (!preg_match('/^[0-9A-F]{8}-[0-9A-F]{8}-[0-9A-F]{8}-[0-9A-F]{8}$/i', $uuid)) {
            http_response_code(400);
            echo "Error: Invalid UUID format\n";
            exit;
        }

        // Ensure exactly one of add or remove is specified
        if ($is_add && $is_remove) {
            http_response_code(400);
            echo "Error: Cannot specify both add and remove\n";
            exit;
        }

        // Determine endpoint
        $endpoint = $is_add ? 'http://104.37.190.154:8080/WebService/AddMiniItem/' : 'http://104.37.190.154:8080/WebService/RemoveMiniItem/';

        // Send CURL request
        $ch = curl_init($endpoint);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            "sessionid: $session_id",
            "uuid: $uuid",
            "env: cprod",
            "invtype: 1",
            "Content-Type: application/json",
            "Accept: application/json"
        ]);
        curl_setopt($ch, CURLOPT_TIMEOUT, 5);
        $response = curl_exec($ch);
        $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        // Handle response
        if ($response === false || $http_code !== 200) {
            http_response_code(500);
            echo "Error: Failed to " . ($is_add ? "add" : "remove") . " item\n";
            exit;
        }

        // Output success
        echo "Success: Item " . ($is_add ? "added" : "removed") . " for UUID $uuid\n";
        exit;
    }

    // Original logic below (unchanged)
    // Category filter mappings
    $category_filters = [
        'kMyPortable' => ['csv' => 'data/kMyPortable.csv', 'prefix' => 'portable'],
        'kMyFurniture' => ['csv' => 'data/kMyFurniture.csv', 'prefix' => 'furniture'],
        'kMyMale' => ['csv' => 'data/kMyMale.csv', 'prefix' => 'male'],
        'kMyFemale' => ['csv' => 'data/kMyFemale.csv', 'prefix' => 'female'],
        'kMyApartments' => ['csv' => 'data/kMyApartments.csv', 'prefix' => 'scene'],
        'kLoadAll' => ['csv' => 'data/kLoadAll.csv', 'prefix' => '']
    ];

    // Determine request type
    $is_inventory_request = !empty($session_id) || 
                           str_starts_with($search_query, 'kMy') || 
                           $search_query === 'kLoadAll' || 
                           str_starts_with($category_query, 'kMy') || 
                           $category_query === 'kLoadAll';
    $is_category_search = !empty($category_query) && !$is_inventory_request;

    // Set PSV file and prefix
    $psv_file = 'data/kLoadAll.csv';
    $category_prefix = '';
    if ($is_inventory_request) {
        $query_value = $search_query ?: $category_query;
        foreach ($category_filters as $query_param => $filter) {
            if ($query_value === $query_param || isset($_GET[$query_param])) {
                $psv_file = $filter['csv'];
                $category_prefix = $filter['prefix'];
                break;
            }
        }
    } elseif ($is_category_search) {
        $psv_file = 'data/' . $category_query . (str_ends_with($category_query, '.csv') ? '' : '.csv');
    }

    // Excluded categories
    $excluded_categories = ['Placeholder1', 'Placeholder2', 'Placeholder3'];

    // Initialize
    $items = [];
    $items_per_page = 30;
    $total_items = 0;

    $file = fopen($psv_file, 'r');
if ($file === false) {
    http_response_code(500);
    echo "page 1 of 1 total 0\n";
    exit;
}
    // Read header
    $header = str_getcsv(fgets($file), '|');

    // Process inventory request
    $uuids = [];
    if ($is_inventory_request && !empty($session_id)) {
        $ch = curl_init("http://104.37.190.154:8080/WebService/GetMini/");
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            "sessionid: $session_id",
            "env: cprod",
            "Content-Type: application/json",
            "Accept: application/json"
        ]);
        curl_setopt($ch, CURLOPT_TIMEOUT, 5);
        $response = curl_exec($ch);
        $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if ($response === false || $http_code !== 200) {
            http_response_code(500);
            echo "Page 1 of 1   Total Items 0\n";
            fclose($file);
            exit;
        }

        $inventory_data = json_decode($response, true);
        if (!$inventory_data) {
            http_response_code(500);
            echo "Page 1 of 1   Total Items 0\n";
            fclose($file);
            exit;
        }

        foreach ($inventory_data as $item) {
            if (is_array($item)) {
                foreach ($item as $uuid => $value) {
                    if ($value === 1) {
                        $uuids[] = strtoupper($uuid);
                    }
                }
            }
        }
    }

    // First pass: Count items
    $current_index = -1;
    while (($line = fgets($file)) !== false) {
        $line = trim($line);
        if (empty($line)) continue;
        
        $row = str_getcsv($line, '|');
        if (count($row) < count($header)) continue;
        
        $row_data = array_combine($header, $row);
        if (in_array($row_data['category'], $excluded_categories)) continue;
        
        $matches = false;
        if ($is_category_search) {
            $matches = true;
        } elseif (!$is_inventory_request) {
            $line_text = strtolower(implode(' ', $row));
            $matches_all = true;
            foreach ($search_words as $word) {
                if (str_starts_with($word, 'male-') && strpos($line_text, 'female-') !== false && strpos($line_text, $word) !== false) {
                    $pattern = '/\b' . preg_quote($word, '/') . '\b/';
                    if (!preg_match($pattern, $line_text)) {
                        $matches_all = false;
                        break;
                    }
                } elseif (strpos($line_text, $word) === false) {
                    $matches_all = false;
                    break;
                }
            }
            $matches = $matches_all;
        } else {
            $id_match = empty($session_id) || in_array(strtoupper($row_data['id']), $uuids);
            if ($id_match && (empty($category_prefix) || stripos($row_data['category'], $category_prefix) === 0)) {
                $matches = true;
            }
        }
        
        if ($matches) {
            $current_index++;
            $total_items++;
        }
    }
    rewind($file);
    fgets($file);

    // Calculate pages
    $total_pages = max(1, ceil($total_items / $items_per_page));
    $page = min($page, $total_pages);
    $start_index = ($page - 1) * $items_per_page;
    $end_index = $start_index + $items_per_page - 1;

    // Second pass: Collect items
    $current_index = -1;
    while (($line = fgets($file)) !== false) {
        $line = trim($line);
        if (empty($line)) continue;
        
        $row = str_getcsv($line, '|');
        if (count($row) < count($header)) continue;
        
        $row_data = array_combine($header, $row);
        if (in_array($row_data['category'], $excluded_categories)) continue;
        
        $matches = false;
        if ($is_category_search) {
            $matches = true;
        } elseif (!$is_inventory_request) {
            $line_text = strtolower(implode(' ', $row));
            $matches_all = true;
            foreach ($search_words as $word) {
                if (str_starts_with($word, 'male-') && strpos($line_text, 'female-') !== false && strpos($line_text, $word) !== false) {
                    $pattern = '/\b' . preg_quote($word, '/') . '\b/';
                    if (!preg_match($pattern, $line_text)) {
                        $matches_all = false;
                        break;
                    }
                } elseif (strpos($line_text, $word) === false) {
                    $matches_all = false;
                    break;
                }
            }
            $matches = $matches_all;
        } else {
            $id_match = empty($session_id) || in_array(strtoupper($row_data['id']), $uuids);
            if ($id_match && (empty($category_prefix) || stripos($row_data['category'], $category_prefix) === 0)) {
                $matches = true;
            }
        }
        
        if ($matches) {
            $current_index++;
            if ($current_index >= $start_index && $current_index <= $end_index) {
                $thumbnail_type = in_array($row_data['thumbnail'], ['L', 'S']) ? $row_data['thumbnail'] : 'P';
                $name = str_replace('|', '\|', substr($row_data['name'], 0, 36));
                $category = str_replace('|', '\|', $row_data['category']);
                
                $items[] = [
                    'id' => $row_data['id'],
                    'name' => $name,
                    'thumbnail_type' => $thumbnail_type,
                    'category' => $category
                ];
            }
        }
    }
    fclose($file);

    // Output
    echo "$page|$total_pages|$total_items\n";
    foreach ($items as $item) {
        echo "{$item['id']}|{$item['name']}|{$item['thumbnail_type']}|{$item['category']}\n";
    }
} catch (Exception $e) {
    http_response_code(500);
    echo "Internal Server Error\n";
}
?>