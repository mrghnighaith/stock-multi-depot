# Stock Multi-Depot Application

A containerized, microservices-based stock and inventory management system designed for multi-depot operations, orchestrated via Kubernetes and automated using a GitOps workflow.

---

## 🏗️ Architecture Overview

The application follows a robust multi-tier architecture deployed inside a Kubernetes cluster:

```
[ Client / Browser ] 
       │
       ▼ (NodePort: 30090)
[ Nginx Frontend ] ──(Reverse Proxy / proxy_pass)──► [ Apache / PHP Backend ] ──► [ MySQL / Redis ]
```

*   **Frontend Web Server:** **Nginx** (serving static assets and routing API requests).
*   **Backend Application Server:** **Apache & PHP 8.2** (handling core business logic, API endpoints, and authentication routes like `api.php`).
*   **Database & State Management:** **MySQL** (persistent inventory/user data) and **Redis** (caching and sessions).

---

## 🚀 Tech Stack & Tools

*   **Application:** HTML5, CSS3, JavaScript, PHP 8.2, Apache, Nginx.
*   **Containerization:** Docker, Docker Desktop.
*   **Orchestration & GitOps:** Kubernetes (`kubectl`), ArgoCD.
*   **CI/CD Automation:** GitHub Actions with Self-Hosted Windows Runners.
*   **Environment & Virtualization:** Ubuntu Linux on VMware Workstation Pro / WSL 2.
*   **Version Control:** Git & GitHub.

---

## 📂 Project Structure

```text
stock-multi-depot/
├── nginx/
│   ├── Dockerfile          # Custom Nginx image build file
│   └── default.conf        # Nginx configuration (routing static & proxying PHP)
├── app/
│   └── public/             # Frontend assets (index.html, style.css, app.js)
├── monitoring/             # Monitoring and observability manifests (Grafana/Prometheus)
└── README.md
```

---

## ⚙️ Configuration & Routing Highlights

The Nginx reverse-proxy configuration ensures seamless communication between the frontend client interface and the Apache backend by catching PHP requests and forwarding them correctly:

```nginx
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html index.php;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # Proxy PHP requests to the backend Apache/PHP service
    location ~ \.php$ {
        proxy_pass http://app;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

---

## 🛠️ Deployment & GitOps Workflow

1.  **Source Control:** Code changes and configuration updates (such as Nginx routing adjustments) are committed and pushed to the main repository.
2.  **GitOps Synchronization:** **ArgoCD** continuously monitors the Git repository and automatically applies synchronization updates to the Kubernetes cluster namespace (`stock-multi-depot`).
3.  **CI/CD Pipeline:** **GitHub Actions** handles automated build verification and runner execution.

---

## 🌐 Accessing the Application

Once deployed and running in your Kubernetes cluster, access the application via your configured NodePort service:
