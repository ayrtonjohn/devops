provider "docker" {
  host = "unix:///var/run/docker.sock"
}

resource "docker_network" "monitoring" {
  name = "monitoring"
}

resource "docker_container" "prometheus" {
  image = "prom/prometheus:v2.45.0"
  name  = "prometheus"
  volumes {
    host_path      = "./prometheus.yml"
    container_path = "/etc/prometheus/prometheus.yml"
  }
  ports {
    internal = 9090
    external = 9090
  }
  networks_advanced {
    name = docker_network.monitoring.name
  }
}

resource "docker_container" "grafana" {
  image = "grafana/grafana:9.6.3"
  name  = "grafana"
  environment = {
    GF_SECURITY_ADMIN_PASSWORD = "admin"
  }
  ports {
    internal = 3000
    external = 3000
  }
  depends_on = [docker_container.prometheus]
  volumes {
    host_path      = "./grafana/provisioning"
    container_path = "/etc/grafana/provisioning"
  }
  networks_advanced {
    name = docker_network.monitoring.name
  }
}

resource "docker_container" "node_exporter" {
  image = "prom/node-exporter:v1.6.1"
  name  = "node_exporter"
  ports {
    internal = 9100
    external = 9100
  }
  networks_advanced {
    name = docker_network.monitoring.name
  }
}
