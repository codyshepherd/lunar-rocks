# Music

Cody Shepherd
Brian Ginsburg

## Build

Compile the client from the `elm` directory.
```
elm-make src/Main.elm --output=../python/static/main.js
```

From the `python` directory, setup up a python virtual environment using Python 3.4.

```
virtualenv -p /path/to/python3.4 venv
```

Activate the environment and install the required packages.
```
source .env
pip install -r requirements.txt
```


## Run

Activate the virtual environment from the `python` directory, and start flask.

```
source .env
flask run
```

In a separate terminal window, activate the virtual environment, and start the websocket server.
```
source .env
python server.py
```
