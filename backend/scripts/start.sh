#!/bin/bash
echo "Démarrage de l'API Cloud (Gunicorn)..."
# exec permet à gunicorn de devenir le PID 1 et de recevoir le SIGTERM
exec gunicorn -w 2 -b 0.0.0.0:5000 app.app:app