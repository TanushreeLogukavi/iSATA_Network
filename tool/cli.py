import os
import sys
import subprocess
import shutil

def check_setup():
    print("🔍 Starting i-SATA Environment Check...\n")
    all_passed = True

    # 1. Check Python Dependencies
    print("--- 🐍 Python Environment ---")
    try:
        import click
        import matlab.engine
        print("✅ Python: 'click' and 'matlabengine' are installed.")
    except ImportError as e:
        print(f"❌ Python Error: Missing {e.name}. Run 'pip install click matlabengine'")
        all_passed = False

    # 2. Check Directory Structure (D: Drive)
    print("\n--- 📂 Directory Structure (Hardcoded Paths) ---")
    required_paths = [
        r"D:\Tanu_iSATA\lib\Final_Modularised_Code",
        r"D:\Tanu_iSATA\lib\Final_Modularised_Code\Utilities",
        r"D:\Tanu_iSATA\lib\Utilities\spm12",
        r"D:\Tanu_iSATA\lib\roast-4.0\roast-4.0",
        r"D:\Tanu_iSATA\lib\Utilities\fieldtrip"
    ]

    for path in required_paths:
        if os.path.exists(path):
            print(f"✅ Found: {path}")
        else:
            print(f"❌ Missing: {path}")
            all_passed = False

    # 3. Check WSL & ART (For AC-PC Phase)
    print("\n--- 🐧 WSL & ART (Phase 2) ---")
    wsl_check = shutil.which("wsl")
    if wsl_check:
        print("✅ WSL is installed on Windows.")
        # Check if ART binary exists within the expected WSL path
        art_path = r"D:\Tanu_iSATA\lib\Utilities\ART\bin\acpcdetect"
        if os.path.exists(art_path):
            print(f"✅ ART Binary found at: {art_path}")
        else:
            print(f"⚠️  Warning: ART binary 'acpcdetect' not found. Phase 2 will fail.")
            all_passed = False
    else:
        print("❌ WSL is NOT installed. Phase 2 (ACPC) requires WSL.")
        all_passed = False

    # 4. Final Verdict
    print("\n" + "="*40)
    if all_passed:
        print("🚀 ALL SYSTEMS GO! You are ready to run 'isata'.")
    else:
        print("🛑 SETUP INCOMPLETE. Please fix the errors above.")
    print("="*40)

if __name__ == "__main__":
    check_setup()
