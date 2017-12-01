'''
Lunar Rocks Http Server

Running this file ask a Flask app using `flask run` will start a web server that serves the static
files Clients will require when first connecting.

The need for this file is obviated by various cloud deployment tools (such as nginx).
'''

from flask import Flask

__author__ = "Cody Shepherd and Brian Ginsburg"
__copyright__ = "Copyright 2017, Cody Shepherd & Brian Ginsburg"
__credits__ = ["Cody Shepherd", "Brian Ginsburg"]
#__license__ =
__version__ = "1.0.0"
__maintainer__ = "Cody Shepherd"
__email__ = "cody.shepherd@gmail.com"
__status__ = "Alpha"

app = Flask(__name__, static_url_path='')

@app.route('/')
def index():
    return app.send_static_file('index.html')

@app.route('/main.js')
def main_js():
    return app.send_static_file('main.js')
