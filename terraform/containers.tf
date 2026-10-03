# --- DATABASE ---
resource "docker_container" "db" {
  name    = "stock_db_tf"
  image   = docker_image.mysql.image_id
  restart = "unless-stopped"
  
  env = [
    "MYSQL_DATABASE=${var.db_name}",
    "MYSQL_USER=${var.db_user}",
    "MYSQL_PASSWORD=${var.db_password}",
    "MYSQL_ROOT_PASSWORD=${var.db_root_password}"
  ]

  ports {
    internal = 3306
    external = 3308
  }

  volumes {
    container_path = "/docker-entrypoint-initdb.d/init.sql"
    host_path      = abspath("${path.module}/../db/init.sql")
    read_only      = true
  }

  networks_advanced {
    name = docker_network.stocknet.name
  }
}

# --- REDIS CACHE ---
resource "docker_container" "redis" {
  name  = "stock_redis_tf"
  image = docker_image.redis.image_id
  
  networks_advanced {
    name = docker_network.stocknet.name
  }
}

# --- PHPMYADMIN ---
resource "docker_container" "phpmyadmin" {
  name    = "stock_pma_tf"
  image   = docker_image.phpmyadmin.image_id
  restart = "unless-stopped"

  env = [
    "PMA_HOST=stock_db_tf",
    "PMA_USER=root",
    "PMA_PASSWORD=${var.db_root_password}"
  ]

  ports {
    internal = 80
    external = 8083
  }

  networks_advanced {
    name = docker_network.stocknet.name
  }
}

# --- BACKEND APPLICATION (PHP/Node) ---
resource "docker_container" "app" {
  name  = "stock_app_tf"
  image = docker_image.app.image_id
  
  env = [
    "DB_HOST=stock_db_tf",
    "DB_NAME=${var.db_name}",
    "DB_USER=${var.db_user}",
    "DB_PASSWORD=${var.db_password}"
  ]

  networks_advanced {
    name    = docker_network.stocknet.name
    aliases = ["app"]
  }
}

# --- FRONTEND (NGINX PROXY) ---
resource "docker_container" "frontend" {
  name  = "stock_frontend_tf"
  image = docker_image.nginx.image_id
  
  ports {
    internal = 80
    external = 9091
  }

  volumes {
    container_path = "/etc/nginx/conf.d/default.conf"
    host_path      = abspath("${path.module}/../nginx/default.conf")
    read_only      = true
  }

  volumes {
    container_path = "/var/www/html"
    host_path      = abspath("${path.module}/../app/public")
    read_only      = true
  }

  networks_advanced {
    name = docker_network.stocknet.name
  }
}

# --- PROMETHEUS ---
resource "docker_container" "prometheus" {
  name    = "stock_prometheus_tf"
  image   = docker_image.prometheus.image_id
  restart = "unless-stopped"

  ports {
    internal = 9090
    external = 9090
  }

  volumes {
    container_path = "/etc/prometheus/prometheus.yml"
    host_path      = abspath("${path.module}/../prometheus/prometheus.yml")
    read_only      = true
  }

  networks_advanced {
    name = docker_network.stocknet.name
  }
}

# --- GRAFANA ---
resource "docker_container" "grafana" {
  name    = "stock_grafana_tf"
  image   = docker_image.grafana.image_id
  restart = "unless-stopped"

  ports {
    internal = 3000
    external = 3000
  }

  env = [
    "GF_SECURITY_ADMIN_PASSWORD=admin"
  ]

  volumes {
    container_path = "/etc/grafana/provisioning/datasources/datasource.yml"
    host_path      = abspath("${path.module}/../grafana/provisioning/datasources/datasource.yml")
    read_only      = true
  }

  volumes {
    container_path = "/etc/grafana/provisioning/dashboards/dashboard.yml"
    host_path      = abspath("${path.module}/../grafana/provisioning/dashboards/dashboard.yml")
    read_only      = true
  }

  volumes {
    container_path = "/etc/grafana/provisioning/dashboards/stock_dashboard.json"
    host_path      = abspath("${path.module}/../grafana/provisioning/dashboards/stock_dashboard.json")
    read_only      = true
  }

  networks_advanced {
    name = docker_network.stocknet.name
  }
}

# --- CADVISOR MONITORING ---
resource "docker_container" "cadvisor" {
  name    = "stock_cadvisor_tf"
  image   = docker_image.cadvisor.image_id
  restart = "unless-stopped"

  ports {
    internal = 8080
    external = 8081
  }

  volumes {
    container_path = "/rootfs"
    host_path      = "/"
    read_only      = true
  }

  volumes {
    container_path = "/var/run"
    host_path      = "/var/run"
    read_only      = false
  }

  volumes {
    container_path = "/sys"
    host_path      = "/sys"
    read_only      = true
  }

  volumes {
    container_path = "/var/lib/docker"
    host_path      = "/var/lib/docker"
    read_only      = true
  }

  networks_advanced {
    name = docker_network.stocknet.name
  }
}
