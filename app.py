# app.py
from flask import Flask, render_template, jsonify, request
from amboss_automation import create_amboss_account # Import your function

app = Flask(__name__)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/create_account', methods=['POST'])
def handle_create_account():
    # This will run the Selenium script. It will take time.
    # For a real app, you'd use a task queue (Celery) here.
    result = create_amboss_account()
    return jsonify(result)

if __name__ == '__main__':
    # This is for local development. Render will use a Gunicorn server.
    app.run(host='0.0.0.0', port=8080, debug=True)
