#!/bin/bash
## -- you could write any backend service here! -- 
apt-get update
apt-get install -y python3 python3-pip

cat > /home/${USER}/app.py <<'EOF'
from flask import Flask, jsonify
app = Flask(__name__)

@app.route('/')
def home():
    return jsonify({
        "message": "Hello from backend API",
        "status": "success"
    })

app.run(host='0.0.0.0', port=5000)
EOF

pip3 install flask

nohup python3 /home/${USER}/app.py > /var/log/backend.log 2>&1 &