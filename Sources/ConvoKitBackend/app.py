from openai import OpenAI
from flask import Flask, request, Response

client = OpenAI()

app = Flask(__name__)

# Streams the message at a slower pace to reduce lag on the iOS side
def stream(messages):
    completion = client.chat.completions.create(model="gpt-3.5-turbo", messages=messages, stream=True, max_tokens=300, temperature=0.5)
    buffer = ""
    counter = 0
    for line in completion:
        counter += 1
        try:
            newBuffer = line.choices[0].delta.content
            if newBuffer != None:
                buffer += str(newBuffer)
        except:
            continue
        if counter % 2 == 0:
            yield buffer
            buffer = ""

@app.route('/speak')
def speak():
    textToSpeak = request.get("directResponse")
    # Returns fileID to start streaming from the app
    return speak(client=client, textToSpeak=textToSpeak)
        
@app.route('/chat', methods=['POST'])
def generate_chat():
    messages = request.json["messages"]
    messages = [
                {"role": "system", "content": "You are a helpful assistant"}
    ] + messages

   
    return Response(stream(messages), mimetype='text/event-stream')


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=8081)


