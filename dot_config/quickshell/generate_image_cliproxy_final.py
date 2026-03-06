import requests
import json
import base64
import sys

# Provider configuration from opencode.json
BASE_URL = "https://cli-proxy.homelab.frieserlabs.dev/v1"
API_KEY = "sk-AcQkmcdsMvmMNpK2RzQlIw"
MODEL = "gemini-3.1-flash-image" # Verified from /models list
PROMPT = "A sleek, minimal desktop shell wallpaper for a Linux Wayland compositor. Abstract geometric shapes with soft gradients in deep blues, teals, and subtle purple accents. Clean lines suggesting a modern tiling window manager aesthetic. Polar/arctic theme with crystalline structures and aurora borealis-like light streaks. Dark background with luminous accent elements. Ultra-clean, minimal, futuristic UI design inspiration. No text."

headers = {
    "Authorization": f"Bearer {API_KEY}",
    "Content-Type": "application/json"
}

data = {
    "model": MODEL,
    "prompt": PROMPT,
    "n": 1,
    "size": "1024x1024",
    "response_format": "b64_json"
}

print(f"Requesting image generation using model: {MODEL}...")
try:
    # Most OpenAI-compatible proxies use /images/generations for image tasks
    response = requests.post(f"{BASE_URL}/images/generations", headers=headers, json=data)
    
    if response.status_code != 200:
        print(f"Error: {response.status_code}")
        print(response.text)
        sys.exit(1)
        
    result = response.json()
    if 'data' in result and len(result['data']) > 0:
        img_b64 = result['data'][0]['b64_json']
        with open("shell-wallpaper.png", "wb") as f:
            f.write(base64.b64decode(img_b64))
        print("SUCCESS: shell-wallpaper.png generated using CLIAPIProxy (gemini-3.1-flash-image)")
    else:
        print("No image data found in response")
        print(json.dumps(result, indent=2))

except Exception as e:
    print(f"An error occurred: {e}")
    sys.exit(1)
