from flask import Flask, request, jsonify

app = Flask(__name__)

# Assure-toi que l'URL est exactement celle-ci
@app.route('/game-event', methods=['POST'])
def game_event():
    # Récupération du JSON envoyé par curl
    data = request.get_json()
    
    # Log dans la console du conteneur
    print(f"Événement reçu : {data}")
    
    return jsonify({
        "status": "success",
        "message": "Donnees recues par l'API"
    }), 200

if __name__ == "__main__":
    # debug=False est important pour la gestion des signaux
    app.run(host='0.0.0.0', port=5000, debug=False)