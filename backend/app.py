import signal
import sys
import time
from flask import Flask

app = Flask(__name__)

# Gestionnaire de signal pour le SIGTERM
def graceful_exit(sig, frame):
    print("\n[SIGTERM reçu] Arrêt propre de l'API Cloud en cours...")
    # Ici on simulerait une fermeture de DB
    sys.exit(0)

signal.signal(signal.SIGTERM, graceful_exit)

@app.route('/')
def hello():
    return {"status": "success", "message": "Bienvenue sur l'API de votre Cloud Personnel"}

if __name__ == "__main__":
    print("API démarrée sur le port 5000...")
    app.run(host='0.0.0.0', port=5000)