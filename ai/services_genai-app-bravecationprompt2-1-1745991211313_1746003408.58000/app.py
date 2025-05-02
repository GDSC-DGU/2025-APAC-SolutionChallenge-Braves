import os
import base64
from google import genai
from google.genai import types
from flask import Flask, request, jsonify

# Initialize GenAI client
client = genai.Client(
    vertexai=True,
    project="bravecation",
    location="us-central1",
)

def generate_mission(
    latitude,
    longitude,
    traveler_information,
    current_time,
    trip_information
):
    """Generate mission content based on parameters."""
    
    prompt_text = f"""{latitude}{longitude}{traveler_information}{current_time}{trip_information}

You are a variety show Producer Director. Create ONE simple and fun mission for travelers based on these features:
1. their current location described with {longitude} and {latitude}
2. traveler details inferenced by {traveler_information} (written in json context)
3. time of day: {current_time}
4. trip details: {trip_information}

Your mission recommendation must:
- Be realistic and easy to execute
- Use nearby locations or local culture 
- Be appropriate for the time of day
- Be either game-based (competition/cooperation) OR experience-based (cultural/social interaction)
- Be safe and legal

Present your ONE mission recommendation in this format:
1. MISSION NAME: [Catchy title]
2. TYPE: [Game OR Experience]
3. DURATION: [Time needed]
4. ITEMS NEEDED: [Simple items travelers likely have]
5. HOW TO PLAY: [Brief, bullet-point instructions]
6. PD'S TIP: [Short enthusiastic comment]

Keep explanations direct and concise. Respond in English only."""

    model = "gemini-2.0-flash-001"
    contents = [
        types.Content(
            role="user",
            parts=[types.Part.from_text(text=prompt_text)]
        ),
    ]

    tools = [types.Tool(google_search=types.GoogleSearch())]
    generate_content_config = types.GenerateContentConfig(
        temperature=1,
        top_p=0.95,
        max_output_tokens=8192,
        response_modalities=["TEXT"],
        safety_settings=[
            types.SafetySetting(category="HARM_CATEGORY_HATE_SPEECH", threshold="OFF"),
            types.SafetySetting(category="HARM_CATEGORY_DANGEROUS_CONTENT", threshold="OFF"),
            types.SafetySetting(category="HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold="OFF"),
            types.SafetySetting(category="HARM_CATEGORY_HARASSMENT", threshold="OFF")
        ],
        tools=tools,
    )

    response = client.models.generate_content(
        model=model,
        contents=contents,
        config=generate_content_config,
    )
    
    return response.text

# Create Flask app
app = Flask(__name__)

@app.route('/api/mission', methods=['POST'])
def mission_api():
    data = request.json
    try:
        latitude = data.get('latitude', '')
        longitude = data.get('longitude', '')
        traveler_information = data.get('traveler_information', '')
        current_time = data.get('current_time', '')
        trip_information = data.get('trip_information', '')
        
        mission_text = generate_mission(
            latitude=latitude,
            longitude=longitude,
            traveler_information=traveler_information,
            current_time=current_time,
            trip_information=trip_information
        )
        return jsonify({"status": "success", "mission": mission_text})
    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

if __name__ == '__main__':
    port = int(os.environ.get("PORT", 8080))
    app.run(host='0.0.0.0', port=port)