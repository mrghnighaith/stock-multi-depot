# NODE — Gestion de Stock Multi-Depots

Systeme de gestion de stock reparti sur plusieurs depots (Bizerte, Tunis, Sfax), avec transferts inter-depots et suivi en temps reel. Stack conteneurisee avec Docker Compose, avec des manifestes Kubernetes equivalents pour un deploiement en cluster.

## Stack

- **Frontend**: HTML5 / CSS3 / JS vanilla
- **Backend**: PHP 8.2-FPM + PDO (routing module/action dans `api.php`)
- **Cache**: Redis 7 (cache la reponse de `stocks/overview` 10s, invalide sur transfert)
- **Base de donnees**: MySQL 8.0
- **Reverse proxy**: Nginx
- **Admin DB**: phpMyAdmin

## Structure

```
stock-multi-depot/
├── docker-compose.yml
├── Jenkinsfile
├── .github/workflows/ci-cd.yml
├── .env.example
├── nginx/
│   └── default.conf
├── app/
│   ├── Dockerfile
│   └── public/
│       ├── index.html
│       ├── style.css
│       ├── app.js
│       └── api.php
├── db/
│   └── init.sql
├── scripts/
│   └── lint.sh
└── k8s/
    ├── 00-namespace.yaml
    ├── 01-secret.yaml
    ├── 02-mysql-storage.yaml
    ├── 03-mysql-deployment.yaml
    ├── 04-redis-deployment.yaml
    ├── 05-app-deployment.yaml
    └── 06-nginx-deployment.yaml
```

## Lancement (Docker Compose)

```bash
cp .env.example .env
docker compose up -d --build
```

## Acceder a l'app : VM vs Windows

Le projet tourne dans une VM Ubuntu (VMware). `localhost` designe toujours la machine sur laquelle la commande est executee — ce n'est PAS la meme chose selon que vous etes dans un terminal de la VM ou dans un navigateur Windows.

### Depuis un terminal/navigateur a l'interieur de la VM

http://localhost:9090

Fonctionne directement — Docker Compose tourne sur cette meme machine.

### Depuis le navigateur Windows (l'hote)
`localhost:9090` sur Windows pointe vers Windows lui-meme, pas vers la VM. Il faut utiliser l'IP reseau de la VM a la place.

**1. Trouver l'IP de la VM** (dans un terminal de la VM) :
```bash
ip addr show | grep "inet "
```
Chercher la ligne avec l'interface reseau principale (`ens33` typiquement, pas `lo`, `docker0`, ou `br-...`), par exemple :

inet 192.168.211.140/24 ... ens33


**2. Utiliser cette IP depuis Windows** :

http://192.168.211.140:9090


Cette IP peut changer si la VM redemarre (adressage DHCP par defaut) — la revérifier avec `ip addr show` si l'app devient injoignable apres un redemarrage.

### Depuis le navigateur Windows, pour le cluster Kubernetes (minikube)

Minikube ajoute encore une couche reseau. Toujours executer cette commande **dans la VM** pour obtenir l'URL correcte :
```bash
minikube service nginx -n stock-multi-depot --url
```
Cela retourne une IP interne a minikube (ex. `http://192.168.49.2:30090`), generalement seulement accessible depuis la VM elle-meme, pas depuis Windows. Pour tester depuis la VM :
```bash
curl $(minikube service nginx -n stock-multi-depot --url)
```

Also find further down:

markdown
L'app est accessible sur `http://<IP-du-node>:30090`.

and change it to:

markdown
L'app est accessible sur `http://<IP-du-node>:30090` (voir la section "Acceder a l'app : VM vs Windows" plus haut — depuis la VM, `minikube service nginx -n stock-multi-depot --url` donne l'URL exacte a utiliser).

## Reseau Docker et cache

Tous les services partagent un reseau bridge personnalise (`stocknet`), ce qui leur permet de se joindre par nom de service (`db`, `redis`, etc.) plutot que par IP. Redis met en cache la reponse de `stocks/overview` et bascule silencieusement sur MySQL direct s'il est indisponible.

## CI/CD — deux pipelines

### GitHub Actions (`.github/workflows/ci-cd.yml`)
- **build-and-test** : lint PHP + build des images Docker, sur chaque push/PR
- **deploy** : s'execute sur un runner self-hosted installe sur le VM (evite d'exposer le VM publiquement) — `docker compose down && up -d --build`

### Jenkins (`Jenkinsfile`)
- Meme sequence : Checkout → Lint PHP → Build Images → Deploy
- Necessite que `jenkins` (utilisateur systeme) soit dans le groupe `docker` :
  `sudo usermod -aG docker jenkins && sudo systemctl restart jenkins`
- Le stage Deploy utilise `env.GIT_BRANCH` (pas `when { branch }`, qui necessite un job Multibranch Pipeline)

## Kubernetes (`k8s/`)

Manifestes equivalents au `docker-compose.yml`, pour deployer sur un cluster reel (via `kubeadm`, ou plus simplement `minikube` pour tester en local) :

| Fichier | Objet(s) K8s | Role |
|---|---|---|
| `00-namespace.yaml` | Namespace | Isole toutes les ressources du projet |
| `01-secret.yaml` | Secret | Identifiants DB (equivalent du `.env`) |
| `02-mysql-storage.yaml` | PersistentVolume + PersistentVolumeClaim | Les donnees MySQL survivent a la suppression du Pod |
| `03-mysql-deployment.yaml` | Deployment + Service (ClusterIP) | MySQL, accessible uniquement en interne |
| `04-redis-deployment.yaml` | Deployment + Service (ClusterIP) | Cache Redis |
| `05-app-deployment.yaml` | Deployment (2 replicas) + Service (ClusterIP) | Backend PHP, 2 copies pour la haute disponibilite — impossible avec docker-compose seul |
| `06-nginx-deployment.yaml` | ConfigMap + Deployment + Service (NodePort) | Point d'entree externe, port 30090 |

### Deploiement

```bash
cd k8s
kubectl apply -f 00-namespace.yaml
kubectl apply -f 01-secret.yaml
kubectl apply -f 02-mysql-storage.yaml
kubectl apply -f 03-mysql-deployment.yaml
kubectl apply -f 04-redis-deployment.yaml
kubectl apply -f 05-app-deployment.yaml
kubectl apply -f 06-nginx-deployment.yaml
```

Ou en une seule commande : `kubectl apply -f k8s/`

L'image `node-stock-app:1.0.0` doit etre construite et disponible pour le cluster (soit importee dans un registre comme Docker Hub, soit chargee directement si vous utilisez minikube : `minikube image load node-stock-app:1.0.0`).

### Verifier le deploiement

```bash
kubectl get pods -n stock-multi-depot
kubectl get svc -n stock-multi-depot
```

L'app est accessible sur `http://<IP-du-node>:30090`.

### Concepts illustres

- **Deployment vs ReplicaSet** : `app` tourne avec `replicas: 2` — si un Pod meurt, Kubernetes en recree un automatiquement pour maintenir ce nombre.
- **PV/PVC** : resout le probleme souligne en cours (perte de donnees si le conteneur MySQL est supprime) en separant le stockage du cycle de vie du Pod.
- **Service ClusterIP vs NodePort** : `db` et `redis` restent internes (ClusterIP) ; seul `nginx` est expose a l'exterieur (NodePort, port 30090, dans la plage standard 30000-32767).
- **ConfigMap** : la configuration Nginx est injectee sans etre codee en dur dans l'image.

## Points a etendre (pour un PFA)

- Authentification (session PHP)
- Alertes automatiques quand `quantite <= seuil_alerte`
- Historique des annulations de transfert
- Export CSV/PDF de l'inventaire
- Ingress Controller pour router plusieurs services via un seul point d'entree HTTP
