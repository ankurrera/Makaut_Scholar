import os
from pathlib import Path

BASE_DIR = Path("/Users/ankurbag/Documents/GitHub/Makaut_Scholar/PYQ questions/Departments")
DEPARTMENTS = ["IT", "ECE", "EE", "ME", "CE"]

def standardize():
    for dept in DEPARTMENTS:
        dept_path = BASE_DIR / dept
        if not dept_path.exists():
            continue
        
        print(f"Standardizing {dept}...")
        for item in dept_path.iterdir():
            if item.is_dir() and item.name.startswith("sem_"):
                new_name = item.name.replace("sem_", "SEM")
                new_path = dept_path / new_name
                print(f"  Renaming {item.name} to {new_name}")
                
                if new_path.exists():
                    # Merge contents if SEMx already exists
                    print(f"    Target {new_name} already exists, merging...")
                    for subitem in item.iterdir():
                        target_subitem = new_path / subitem.name
                        if target_subitem.exists():
                             # If its a subject folder, merge internal files
                             if subitem.is_dir():
                                 for file in subitem.iterdir():
                                     dest_file = target_subitem / file.name
                                     if not dest_file.exists():
                                         file.rename(dest_file)
                                     else:
                                         print(f"      File {file.name} already exists in target, skipping.")
                        else:
                            subitem.rename(target_subitem)
                    item.rmdir()
                else:
                    item.rename(new_path)

if __name__ == "__main__":
    standardize()
