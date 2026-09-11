from flask import Flask, jsonify

app = Flask(__name__)


@app.get("/inventory")
def inventory():
    return jsonify([])
