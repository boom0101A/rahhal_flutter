import os

def export_project_to_md():
    output_filename = "rahhal_full_codebase.md"
    project_dir = os.path.dirname(os.path.abspath(__file__))
    
    # Files/directories to include
    include_dirs = ["lib"]
    include_files = ["pubspec.yaml", "server.js", "README.md"]
    
    # Extensions to include inside include_dirs
    valid_extensions = {".dart", ".yaml", ".json", ".js"}
    
    # Dirs to ignore
    ignore_dirs = {".git", ".dart_tool", "build", "android", "ios", "windows", "web", "rahhal_codebase_md"}
    
    md_content = []
    md_content.append("# Rahhal AI Complete Codebase Export\n")
    md_content.append(f"Generated on: {os.popen('date /t').read().strip()} {os.popen('time /t').read().strip()}\n")
    md_content.append("This file contains the complete source code for the Rahhal Flutter application backend and frontend.\n\n---\n\n")
    
    # 1. Export top-level files
    for filename in include_files:
        filepath = os.path.join(project_dir, filename)
        if os.path.exists(filepath) and os.path.isfile(filepath):
            print(f"Exporting top-level file: {filename}")
            md_content.append(f"## File: `{filename}`\n")
            
            # Determine language syntax highlighting
            ext = os.path.splitext(filename)[1]
            lang = "yaml" if ext == ".yaml" else "javascript" if ext == ".js" else "markdown" if ext == ".md" else "text"
            
            md_content.append(f"```{lang}\n")
            try:
                with open(filepath, "r", encoding="utf-8") as f:
                    md_content.append(f.read())
            except Exception as e:
                md_content.append(f"// Error reading file: {e}")
            md_content.append("\n```\n\n---\n\n")

    # 2. Export directories
    for folder in include_dirs:
        folder_path = os.path.join(project_dir, folder)
        if not os.path.exists(folder_path):
            continue
            
        for root, dirs, files in os.walk(folder_path):
            # Prune ignored directories
            dirs[:] = [d for d in dirs if d not in ignore_dirs]
            
            for file in files:
                ext = os.path.splitext(file)[1]
                if ext not in valid_extensions:
                    continue
                    
                filepath = os.path.join(root, file)
                rel_path = os.path.relpath(filepath, project_dir)
                
                print(f"Exporting: {rel_path}")
                md_content.append(f"## File: `{rel_path.replace(os.sep, '/')}`\n")
                
                lang = "dart" if ext == ".dart" else "yaml" if ext == ".yaml" else "json" if ext == ".json" else "javascript" if ext == ".js" else "text"
                
                md_content.append(f"```{lang}\n")
                try:
                    with open(filepath, "r", encoding="utf-8") as f:
                        md_content.append(f.read())
                except Exception as e:
                    md_content.append(f"// Error reading file: {e}")
                md_content.append("\n```\n\n---\n\n")
                
    # Write to final markdown file
    output_path = os.path.join(project_dir, output_filename)
    with open(output_path, "w", encoding="utf-8") as f:
        f.writelines(md_content)
        
    print(f"\nSuccessfully generated codebase markdown export at: {output_path}")

if __name__ == "__main__":
    export_project_to_md()
