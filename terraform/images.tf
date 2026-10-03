resource "docker_image" "mysql" {
  name         = "mysql:8.0"
  keep_locally = true
}

resource "docker_image" "redis" {
  name         = "redis:alpine"
  keep_locally = true
}

resource "docker_image" "phpmyadmin" {
  name         = "phpmyadmin:5.2"
  keep_locally = true
}

resource "docker_image" "app" {
  name = "node-stock-app:1.0.0"
  build {
    context = "../app"
  }
}

resource "docker_image" "nginx" {
  name         = "nginx:1.27-alpine"
  keep_locally = true
}

resource "docker_image" "prometheus" {
  name         = "prom/prometheus:latest"
  keep_locally = true
}

resource "docker_image" "grafana" {
  name         = "grafana/grafana:latest"
  keep_locally = true
}

resource "docker_image" "cadvisor" {
  name         = "gcr.io/cadvisor/cadvisor:latest"
  keep_locally = true
}
