import os
import sys
from dotenv import load_dotenv
from google import genai

# Set up project path
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(project_root)

# Load secrets from .env
load_dotenv(os.path.join(project_root, '.env'))
api_key = os.getenv("GEMINI_API_KEY")

if not api_key:
    print("ERROR: GEMINI_API_KEY not found in e:\\fyp\\backend\\.env")
    sys.exit(1)

def audit_models():
    print(f"--- AUDITING MODELS FOR KEY: {api_key[:5]}...{api_key[-5:]} ---")
    
    try:
        # Initialize the Modern GenAI Client
        client = genai.Client(api_key=api_key, http_options={'api_version': 'v1'})
        
        print("\n--- AVAILABLE MODELS ---")
        found_any = False
        for m in client.models.list():
            print(f"- {m.name}")
            found_any = True
            
        if not found_any:
            print("No models found. This usually means the API key is not yet associated with any Generative AI models in your project.")

    except Exception as e:
        print(f"\n--- ERROR DURING AUDIT ---")
        print(f"Reason: {str(e)}")

if __name__ == "__main__":
    audit_models()
