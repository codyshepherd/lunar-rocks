from flask import Flask

app = Flask(__name__, static_url_path='')

@app.route('/')
def index():
    return app.send_static_file('index.html')

@app.route('/main.js')
def main_js():
    #start_websockets()
    return app.send_static_file('main.js')
