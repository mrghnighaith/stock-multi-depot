terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

# --- Network ---
resource "docker_network" "stocknet" {
  name = "stocknet_tf"
}

# --- Persistent volume for MySQL data ---
resource "docker_volume" "db_data" {
  name = "stock_db_data_tf"
}

# --- Images ---
resource "docker_image" "mysql" {
  name = "mysql:8.0"
}

resource "docker_image" "redis" {
  name = "redis:7-alpine"
}

resource "docker_image" "app" {
  name = "ghaith5/node-stock-app:1.0.0"
}

resource "docker_image" "frontend" {
  name = "ghaith5/node-stock-frontend:1.0.0"
}

resource "docker_image" "phpmyadmin" {
  name = "phpmyadmin:5.2"
}

# --- Containers ---
resource "docker_container" "db" {
  name  = "stock_db_tf"
  image = docker_image.mysql.image_id

  networks_advanced {
    name = docker_network.stocknet.name
  }

  env = [
    "MYSQL_DATABASE=${var.db_name}",
    "MYSQL_USER=${var.db_user}",
    "MYSQL_PASSWORD=${var.db_password}",
    "MYSQL_ROOT_PASSWORD=${var.db_root_password}",
  ]

  volumes {
    volume_name    = docker_volume.db_data.name
    container_path = "/var/lib/mysql"
  }

  ports {
    internal = 3306
    external = 3308 # different from the docker-compose stack (3307) to avoid clashing
  }
}

resource "docker_container" "redis" {
  name  = "stock_redis_tf"
  image = docker_image.redis.image_id

  networks_advanced {
    name = docker_network.stocknet.name
  }
}

resource "docker_container" "app" {
  name  = "stock_app_tf"
  image = docker_image.app.image_id

  networks_advanced {
    name = docker_network.stocknet.name
  }

  env = [
    "DB_HOST=stock_db_tf",
    "DB_NAME=${var.db_name}",
    "DB_USER=${var.db_user}",
    "DB_PASSWORD=${var.db_password}",
    "REDIS_HOST=stock_redis_tf",
    "REDIS_PORT=6379",
  ]

  depends_on = [docker_container.db, docker_container.redis]
}

resource "docker_container" "frontend" {
  name  = "stock_frontend_tf"
  image = docker_image.frontend.image_id

  networks_advanced {
    name = docker_network.stocknet.name
  }

  ports {
    internal = 80
    external = var.app_port
  }

  depends_on = [docker_container.app]
}

resource "docker_container" "phpmyadmin" {
  name  = "stock_pma_tf"
  image = docker_image.phpmyadmin.image_id

  networks_advanced {
    name = docker_network.stocknet.name
  }

  env = [
    "PMA_HOST=stock_db_tf",
    "PMA_USER=root",
    "PMA_PASSWORD=${var.db_root_password}",
  ]

  ports {
    internal = 80
    external = 8083 # different from docker-compose's 8082 to avoid clashing
  }

  depends_on = [docker_container.db]
}
