# Cloud Game Infrastructure

Architecture micro-services conteneurisée pour le déploiement d'un serveur de jeu piloté par une API cloud.

## 🏗 Structure du Projet

L'infrastructure est segmentée en trois services isolés communiquant sur un réseau privé Docker.


### 1. Game Server (Ubuntu 22.04)** : 

Instance dédiée à l'exécution du moteur de jeu. Intègre Java 17, `htop` pour le monitoring et `curl` pour la communication inter-conteneurs. C'est ici que toute la logique du jeu a lieu.

* **Choix de l'OS (Ubuntu)** : Sélectionné pour sa gestion native et stable des environnements Java. C'est la distribution de référence pour la compatibilité des binaires de serveurs de jeux.

* **openjdk-17-jre-headless** : 
    * *JRE (Java Runtime Environment)* : Suffisant pour exécuter le code sans s'encombrer des outils de compilation du JDK.
    * *Headless* : Version optimisée pour les serveurs sans interface graphique. Cela réduit l'empreinte disque de l'image (environ 150 Mo de gagnés) et limite la surface d'attaque en supprimant les librairies X11.

* **curl** : Installé spécifiquement pour permettre la communication sortante. C'est l'outil qui permet au serveur de jeu de notifier l'API Cloud de son état (Startup / Shutdown).

* **htop & net-tools** : Outils de diagnostic bas niveau pour surveiller l'utilisation des ressources et l'ouverture des ports réseau lors du debugging interactif.


### 2. Back-end API (Debian 12 Slim)** :

Point d'entrée pour la persistance des données et la centralisation des logs. Utilise Python/Flask avec Gunicorn pour la stabilité.

* **Choix de l'OS (Debian Slim)** : Version minimaliste de Debian. Elle est privilégiée en production pour sa sécurité et son poids réduit par rapport à une image Ubuntu standard. Elle permets de réduire les temps de déploiement et la surface d'attaque (moins de failles de sécurité).

* **gunicorn** : Le serveur de développement inclus dans Flask n'est pas "multi-threadé". Nous utilisons Gunicorn pour gérer plusieurs requêtes simultanées, garantissant que l'API reste disponible même en cas de fort trafic venant des serveurs de jeux.

* **--break-system-packages** : Nécessaire sous Debian 12 pour autoriser l'installation de librairies Python via `pip` en dehors d'un environnement virtuel, ce qui est la norme au sein d'un conteneur Docker dédié. Sur Debian 12, pip refuse normalement d'installer des paquets globalement pour ne pas casser le système. Comme on est dans un conteneur isolé, on force l'installation. 

* **rm -rf /var/lib/apt/lists/** : On supprime les fichiers temporaires du gestionnaire de paquets juste après l'installation pour économiser quelques Mo.

* **ENV DATA_PATH** : En définissant des variables d'environnement, on permets à Python de savoir où lire/écrire des données sans "coder en dur" le chemin. C'est flexible : on pourrait changer le dossier de données sans modifier le code.


### 3. Web Interface (Alpine Linux)** 

Proxy Nginx léger servant l'interface d'administration. On y retrouve le dashboard avec les données telle que le monitoring, le nombre de joueurs connectés en temps réel.

* **Choix de l'OS (Alpine)** : Distribution ultra-légère (environ 5 Mo). Elle permet de réduire drastiquement le temps de pull et de déploiement.

* **nginx** : Choisi pour sa performance en tant que serveur de fichiers statiques et sa faible consommation en mémoire vive (RAM).



## 🛠 Spécificités Techniques

### Sécurité & Optimisation

* **Privilèges réduits** : L'API est exécutée par un utilisateur dédié (`apiuser`), limitant les risques de hacking via root(l'appélation super-admin par défaut de Docker).Même si l'API est compromise, le hacker est enfermé dans un utilisateur aux droits limités.

* **Service Discovery** : Les échanges entre services utilisent le DNS interne de Docker (ex: `http://cloud-api:5000`), rendant la configuration indépendante des adresses IP.

* **Images Slim** : Utilisation de distributions minimalistes pour réduire l'empreinte disque et accélérer les déploiements. J'ai un ordinateur portable très limité en ressource mémoire (RAM) et mon processeur n'est plus tout jeune d'où ce choix. 


## ⚙️ Orchestration et Arguments

* **Arguments attendus (ARG/ENV)** : 
    * `DEBIAN_FRONTEND=noninteractive` : Force l'installateur à utiliser les valeurs par défaut pour éviter tout blocage du build (pas de demande de fuseau horaire ou de configuration clavier).

    * `API_VERSION` & `DATA_PATH` : Variables d'environnement injectées via le `docker-compose.yml` pour permettre une configuration dynamique sans modifier le code source.

* **Gestion du SIGTERM** : 

L'utilisation de scripts `ENTRYPOINT` avec l'instruction `trap` assure que le signal d'arrêt envoyé par Docker est transmis au processus Java/Python pour une fermeture propre des bases de données et des fichiers de logs. Le serveur de jeu peut déclencher une procédure de sauvegarde automatique avant l'arrêt du conteneur.

* **Exemple** : 

    ENTRYPOINT ["/opt/cloud-api/scripts/start.sh"] : 
    
Au lieu de lancer Python directement, on lance un script.

Le SIGTERM : Quand on tape docker stop, Docker envoie un signal (SIGTERM) au conteneur pour lui dire : "Éteins-toi proprement".

Si on lances Python en direct, il peut s'arrêter brutalement. Le script start.sh sert de "réceptionniste" : il intercepte le signal, permet à l'API de finir d'enregistrer ses données, puis coupe tout proprement.


* **Limitation des ressources** : Les quotas CPU (0.5) et RAM (512M) définis dans le compose empêchent un "emballement" d'un processus de saturer l'hôte physique. J'ai accordé plus de ressource au service du jeu car il est le plus gourmand, un peu moins pour la persistance des données notre cloud et pas grand chose pour mon service front car il n'affiche qu'un hello pour le moment et ne devrait pas nécessiter un besoin plus important. 




## 🚀 Déploiement

1.  **Lancement global** :
    ```bash
    docker-compose up --build
    ```

2.  **Test de communication inter-services** :
    Exécuter depuis l'hôte pour simuler un événement venant du jeu vers l'API :

    ```powershell
   docker exec -it cloud-game-engine curl -X POST http://cloud-api:5000/game-event -H "Content-Type: application/json" -d '{\"type\":\"test\",\"message\":\"Liaison_OK\"}'
    ```

