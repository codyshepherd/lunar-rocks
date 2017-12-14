"""
Lunar Rocks Testing HTTP Server

Running this module as a flask app with `flask run` will start a local web server which will
serve the static files required by the Lunar Rocks client.

Need for this file is obviated by various deployment tools, e.g. nginx.
"""

from flask import Flask

__author__ = "Cody Shepherd & Brian Ginsburg"
__copyright__ = "Copyright 2017, Cody Shepherd & Brian Ginsburg"
__credits__ = ["Cody Shepherd", "Brian Ginsburg"]
#__license__ =
__version__ = "1.0"
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
