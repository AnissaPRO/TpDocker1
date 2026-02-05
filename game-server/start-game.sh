#!/bin/bash

stop_handler() {
    echo "Signal SIGTERM reçu ! Sauvegarde en cours..."
    # 1. Ici, tu insères ta commande de sauvegarde
    # Exemple : curl -X POST http://cloud-api:5000/backup-notify
    
    # 2. On tue le processus Java proprement
    kill -SIGTERM "$JAVA_PID"
    wait "$JAVA_PID"
    echo "Serveur de jeu arrêté proprement."
    exit 0
}

trap 'stop_handler' SIGTERM

echo "Lancement de la simulation du serveur de jeu..."
# Au lieu de java, on simule un processus qui tourne
tail -f /dev/null & 
JAVA_PID=$!

# On attend la fin du processus
wait "$JAVA_PID"