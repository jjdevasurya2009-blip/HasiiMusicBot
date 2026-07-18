from flask import Flask
import os

app = Flask(__name__)

@app.route('/')
def home():
    return "Bot is alive!"

if __name__ == '__main__':
    # Render assigns the port via the PORT environment variable
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port)
  
