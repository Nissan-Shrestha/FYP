import os
from google import genai
from dotenv import load_dotenv

def check_quotas():
    load_dotenv()
    api_key = os.getenv("GEMINI_API_KEY")
    client = genai.Client(api_key=api_key, http_options={'api_version': 'v1'})
    
    models_to_test = [
        "gemini-2.5-flash",
        "gemini-2.5-flash-lite",
        "gemini-2.0-flash",
        "gemini-2.0-flash-lite",
    ]
    
    print("--- QUOTA AUDIT START ---")
    for model in models_to_test:
        print(f"\nTesting: {model}...")
        try:
            response = client.models.generate_content(
                model=model,
                contents="hi"
            )
            print(f"✅ SUCCESS: {model} is working!")
        except Exception as e:
            if "429" in str(e):
                print(f"❌ QUOTA EXHAUSTED: {model} exists but is blocked (429).")
            elif "404" in str(e):
                print(f"❌ NOT FOUND: {model} is not available for this key.")
            else:
                print(f"❓ UNKNOWN ERROR with {model}: {e}")

if __name__ == "__main__":
    check_quotas()
