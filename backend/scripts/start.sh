#!/bin/bash
# Ce script reçoit le signal de Docker (SIGTERM) 
# 'exec' remplace le script par le processus Python (PID 1)
# Sans 'exec', Python ne recevrait jamais l'ordre de s'arrêter proprement.

echo "Démarrage de l'API Cloud..."
exec python3 /opt/cloud-api/app/app.py