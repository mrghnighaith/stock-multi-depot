# 🚀 Stock Multi-Depot Infrastructure

A modular, production-grade stock management and deployment architecture built with **Terraform**, **Docker**, **Kubernetes**, and an automated **Prometheus & Grafana** observability stack.

---

## 🏗️ Architecture & Tech Stack

* **Infrastructure as Code (IaC):** Modularized **Terraform** managing networks, volumes, image builds, and container lifecycles.
* **Containerization:** **Docker** for local orchestration and multi-service management.
* **Orchestration & CI/CD:** **Kubernetes** deployments and automated pipelines via **GitHub Actions** using self-hosted runners.
* **Application Stack:**
  * **Frontend Proxy:** Nginx (Port `9091`)
  * **Backend Application:** PHP / Node.js
  * **Database:** MySQL 8.0 with automated `init.sql` schema initialization (Port `3308`)
  * **Caching:** Redis
  * **Database Manager:** phpMyAdmin (Port `8083`)
* **Observability & Monitoring:**
  * **Prometheus:** Metrics collection and scraping (Port `9090`)
  * **cAdvisor:** Container resource monitoring
  * **Grafana:** Auto-provisioned dashboards with live CPU/memory telemetry (Port `3000`)

---

## 📂 Project Directory Structure

```text
stock-multi-depot/
├── .github/
│   └── workflows/          # CI/CD deployment pipelines (GitHub Actions)
├── app/                    # Backend application source code & Dockerfile
├── db/
│   └── init.sql            # Automated database schema & initial data loading
├── grafana/
│   └── provisioning/       # Auto-provisioned datasources and dashboards
├── nginx/
│   └── default.conf        # Nginx reverse proxy configuration
├── prometheus/
│   └── prometheus.yml      # Prometheus scrape targets configuration
├── terraform/              # Modular Terraform configuration files
│   ├── providers.tf        # Provider version constraints and setup
│   ├── variables.tf        # Configurable environment parameters
│   ├── networks.tf         # Docker network definitions
│   ├── images.tf           # Remote images and local build configurations
│   ├── containers.tf       # Service container definitions and volumes
│   └── outputs.tf          # Deployed endpoints and access URLs
└── .gitignore              # Ignored files (Terraform state, local caches)
```

---

## 🚦 Getting Started & Local Deployment

### Prerequisites
* [Docker](https://www.docker.com/) installed and running.
* [Terraform](https://www.terraform.io/) (v1.0+) installed.

### 1. Initialize Terraform
Navigate to the Terraform directory and initialize providers:
```bash
cd terraform
terraform init
```

### 2. Provision the Infrastructure
Review and apply the Terraform configuration:
```bash
terraform apply
```
*(Type `yes` when prompted).*

### 3. Verify Active Endpoints
You can display all access URLs automatically via Terraform outputs:
```bash
terraform output
```

---

## 🌐 Access Endpoints

| Service | Local URL / Port | Default Credentials / Info |
| :--- | :--- | :--- |
| **Stock Frontend** | `http://localhost:9091` | Application User Login |
| **Grafana Dashboards** | `http://localhost:3000` | `admin` / `admin` (Auto-provisioned) |
| **Prometheus UI** | `http://localhost:9090` | Container & system metrics |
| **phpMyAdmin** | `http://localhost:8083` | `root` / `root_pass` |
| **MySQL Database** | `localhost:3308` | `stock_user` / `stock_pass` |

---

## 📊 Monitoring & Observability
Prometheus scrapes live container performance metrics using **cAdvisor**. Grafana automatically loads pre-configured dashboards detailing real-time CPU usage, memory consumption, and container status upon startup.

---

## 🛠️ Maintenance & Cleanup
* **Check container status:**
  ```bash
  docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
  ```
* **Tear down the Terraform stack:**
  ```bash
  cd terraform
  terraform destroy