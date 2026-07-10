#!/usr/bin/env python3

from dotenv import load_dotenv
from pathlib import Path
from sys import argv

# Load .env so BUCKET_* vars are available to wa_agents.do_bucket_io
load_dotenv()
from wa_agents.do_bucket_io import ( b3_get_file,
                                     b3_list_objects )


def local_path_for_key( key        : str,
                        prefix     : str,
                        output_dir : Path ) -> Path :
    """
    Build the local destination path for a bucket key \\
    Args:
        key        : Object key returned by S3.
        prefix     : Prefix requested by the user.
        output_dir : Base local directory for downloaded files.
    Returns:
        Local path preserving the object path below `prefix`.
    """
    relative_key = key[ len(prefix) : ].lstrip("/")
    
    if not relative_key :
        relative_key = Path(key).name
    
    relative_path = Path(relative_key)
    
    if relative_path.is_absolute() or ".." in relative_path.parts :
        raise RuntimeError(f"Unsafe object key for local download: {key}")
    
    return output_dir / relative_path


if __name__ == "__main__" :
    
    fname = Path(__file__).name
    usage = f"Usage: {fname} <prefix> [ Optional: <output_dir> ]\n"
    
    if not len(argv) in ( 2, 3) :
        raise SystemExit(usage)
    
    prefix     = argv[1].strip()
    output_dir = Path(argv[2]) if len(argv) == 3 else Path("downloads") / prefix.strip("/")
    
    if not prefix :
        raise SystemExit("Prefix is required.")
    
    objects = b3_list_objects(prefix)
    
    if not objects :
        print(f"No objects found with prefix {prefix}")
        raise SystemExit(0)
    
    output_dir.mkdir( parents = True, exist_ok = True)
    
    print(f"Downloading {len(objects)} objects from prefix {prefix}")
    print(f"Destination: {output_dir}")
    
    downloaded = 0
    for obj in objects :
        
        key = str(obj["Key"])
        if key.endswith("/") :
            continue
        
        path = local_path_for_key( key, prefix, output_dir)
        path.parent.mkdir( parents = True, exist_ok = True)
        path.write_bytes(b3_get_file(key))
        
        downloaded += 1
        print(f"[>] {key} -> {path}")
    
    print(f"Downloaded {downloaded} files.")
