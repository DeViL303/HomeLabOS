import os
import re

def remove_lua_comments(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            lines = file.readlines()
        
        # Process lines to remove comments and print statements
        cleaned_lines = []
        for i, line in enumerate(lines):
            # Preserve comments in first 11 lines (0-based index 0-10)
            if i < 11:
                cleaned_line = line.rstrip()
            else:
                # Remove comments starting with --, but preserve --extract
                # Use negative lookahead to avoid matching --extract
                cleaned_line = re.sub(r'--(?!extract).*?$', '', line.rstrip())
            
            # Remove print statements entirely
            if not cleaned_line.strip().startswith('print'):
                cleaned_lines.append(cleaned_line.rstrip())
        
        # Overwrite the original file with the cleaned content
        with open(file_path, 'w', encoding='utf-8') as file:
            file.write('\n'.join(cleaned_lines))
        print(f"Comments processed and print statements removed from {file_path}")
    
    except FileNotFoundError:
        print(f"Error: File '{file_path}' not found.")
    except Exception as e:
        print(f"An error occurred while processing {file_path}: {str(e)}")

if __name__ == "__main__":
    # Get the directory where the script is located
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Process all .LUA files in the script's directory
    for filename in os.listdir(script_dir):
        if filename.endswith('.LUA'):
            file_path = os.path.join(script_dir, filename)
            remove_lua_comments(file_path)
    print("Processing complete.")