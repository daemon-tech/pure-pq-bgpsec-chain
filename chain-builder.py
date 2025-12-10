#!/usr/bin/env python3
"""
Chain Builder - Wrapper script to build the complete post-quantum BGPsec chain

This script calls the build-pq-bgpsec-chain.sh script and organizes output
for the clean repository structure.

Author: Sam Moes
Date: December 2024
"""

import subprocess
import sys
import os
from pathlib import Path

def main():
    """Build the certificate chain."""
    script_dir = Path(__file__).parent
    build_script = script_dir.parent / "oqs-provider-bgpsec" / "build-pq-bgpsec-chain.sh"
    
    if not build_script.exists():
        print(f"ERROR: Build script not found: {build_script}")
        print("Make sure oqs-provider-bgpsec is in the parent directory")
        sys.exit(1)
    
    print("Building post-quantum BGPsec certificate chain...")
    print(f"Using script: {build_script}")
    print()
    
    # Change to oqs-provider-bgpsec directory
    os.chdir(build_script.parent)
    
    # Run the build script
    try:
        subprocess.run(["bash", str(build_script)], check=True)
    except subprocess.CalledProcessError as e:
        print(f"ERROR: Build failed with exit code {e.returncode}")
        sys.exit(1)
    except FileNotFoundError:
        print("ERROR: bash not found. Please run the script manually:")
        print(f"  bash {build_script}")
        sys.exit(1)
    
    # Copy certificates to clean repo structure
    print()
    print("Organizing certificates for clean repo...")
    
    repo_dir = script_dir
    ca_source = Path("pq-bgpsec-ca")
    router_source = Path("pq-bgpsec-routers")
    
    # Create directories
    ca_dir = repo_dir / "ca" / "certs"
    ca_key_dir = repo_dir / "ca" / "private"
    router_dir = repo_dir / "routers"
    
    ca_dir.mkdir(parents=True, exist_ok=True)
    ca_key_dir.mkdir(parents=True, exist_ok=True)
    router_dir.mkdir(parents=True, exist_ok=True)
    
    # Copy CA certificate and key
    import shutil
    if (ca_source / "certs" / "ca-falcon.crt").exists():
        shutil.copy2(ca_source / "certs" / "ca-falcon.crt", ca_dir / "ca-falcon.crt")
        print(f"  Copied: ca/certs/ca-falcon.crt")
    
    if (ca_source / "private" / "ca-falcon.key").exists():
        shutil.copy2(ca_source / "private" / "ca-falcon.key", ca_key_dir / "ca-falcon.key")
        print(f"  Copied: ca/private/ca-falcon.key")
    
    # Copy router certificates and keys
    router_files = list(router_source.glob("router*.crt")) + list(router_source.glob("router*.key"))
    for src_file in router_files:
        dst_file = router_dir / src_file.name
        shutil.copy2(src_file, dst_file)
        print(f"  Copied: routers/{src_file.name}")
    
    print()
    print("SUCCESS: Certificate chain built and organized")
    print(f"Certificates are in: {repo_dir}")
    print()
    print("Next: Generate ROA with generate-roa-openssl.sh")

if __name__ == '__main__':
    main()

