# Lunar Rocks

Lunar Rocks is a collaborative music application for the web.

## Setup

From the `python` directory, setup up a python virtual environment using Python 3.6.

```
virtualenv -p /path/to/python3.6 venv
```

Activate the environment and install the required packages.
```
source .env
pip install -r requirements.txt
```

Install [Elm](https://guide.elm-lang.org/install.html) and [Create-Elm-App](https://github.com/halfzebra/create-elm-app).

## Run 

Activate the virtual environment and start the websocket server.
```
source .env
python server.py
```

Start the elm app from the `client` directory.

```
elm-app start
```


## Build

Create a production build of the client.

```
elm-app build
```

This will embed the app into `index.html`, minify, and prepare the app for production.
