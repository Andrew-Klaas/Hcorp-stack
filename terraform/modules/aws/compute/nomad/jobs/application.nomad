job "app" {
  datacenters = ["dc1"]
  type = "service"

  update {
    stagger = "5s"
    max_parallel = 1
  }

  group "app" {
    count = 3

    task "app" {
      driver = "exec"
      config {
        command = "app"
      }

      env {
        VAULT_ADDR = "http://vault.service.consul:8200"
        APP_DB_HOST = "10.103.0.5:3306"
      }

      vault {
        policies = ["nomad-server"]
      }

      artifact {
        source = "https://s3.amazonaws.com/ak-bucket-1/app"
      }

      resources {
        cpu = 500
        memory = 64
        network {
          mbits = 1
          port "http" {}
        }
      }

      service {
        name = "app"
        tags = ["urlprefix-app.com/"]
        port = "http"
        check {
          type = "http"
          name = "healthz"
          interval = "15s"
          timeout = "5s"
          path = "/healthz"
        }
      }
    }
  }
}
