from openai import OpenAI
from pathlib import Path
import uuid
from flask import jsonify

# Returns a fileID and starts streaming the audio to that file
def speak(client: OpenAI, textToSpeak: str) -> str:
    a = uuid.uuid1()
    id = str(a)
    speech_file_path = Path(__file__).parent / "audio" / (id + ".mp3")
    response = client.audio.speech.create(
    model="tts-1",
    voice="alloy",
    input=textToSpeak,
)
    
    response.stream_to_file(speech_file_path)
    return jsonify({"fileID": id})
