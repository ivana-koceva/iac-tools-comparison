# configmap with db env
resource "kubernetes_config_map" "blog-config" {
  metadata {
    name = "blog-config"
    namespace = "blogs"
  }

  data = {
    POSTGRES_HOST = "blogdb"
    POSTGRES_PORT = "5432"
    POSTGRES_DB = "blogs"
  }
}

# secrets for db login
resource "kubernetes_secret" "blog-secrets" {
  metadata {
    name = "blog-secrets"
    namespace = "blogs"
  }

  type = "Opaque"

  data = {
    POSTGRES_USER = "postgres"
    POSTGRES_PASSWORD = "admin"
  }
}

# blog deployment
resource "kubernetes_deployment" "blog-deployment" {
  metadata {
    name = "blog-deployment"
    namespace = "blogs"
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "blog"
      }
    }

    template {
      metadata {
        labels = {
          app = "blog"
        }
      }

      spec {
        container {
          image = "ivanakoceva/blog-app:latest"
          name  = "blog-app"

          port {
            container_port = 8080
          }

            env {
            name = "POSTGRES_HOST"
            value_from { 
                config_map_key_ref {
                    name = "blog-config"
                    key  = "POSTGRES_HOST"
                    } 
                }
            }

            env {
            name = "POSTGRES_PORT"
            value_from { 
                config_map_key_ref {
                    name = "blog-config"
                    key  = "POSTGRES_PORT" 
                    }
                }
            }

            env {
            name = "POSTGRES_DB"
            value_from { 
                config_map_key_ref {
                    name = "blog-config"
                    key  = "POSTGRES_DB" 
                    }
                }
            }

            env {
            name = "POSTGRES_USER"
            value_from { 
                secret_key_ref {
                    name = "blog-secrets"
                    key  = "POSTGRES_USER" 
                    }
                }
            }

            env {
            name = "POSTGRES_PASSWORD"
            value_from { 
                secret_key_ref {
                    name = "blog-secrets"
                    key  = "POSTGRES_PASSWORD" 
                    }
                }
            }
          
        }
      }
    }
  }
}


resource "kubernetes_stateful_set" "blogdb" {
  metadata {
    name      = "blogdb"
    namespace = "blogs"
  }

  spec {
    service_name = "blogdb"
    replicas     = 1

    selector {
      match_labels = {
        app = "blogdb"
      }
    }

    template {
      metadata {
        labels = {
          app = "blogdb"
        }
      }

      spec {
        container {
          name  = "postgres"
          image = "postgres:latest"

          port {
            container_port = 5432
          }

          env {
            name = "POSTGRES_USER"
            value_from {
              secret_key_ref {
                name = "blog-secrets"
                key  = "POSTGRES_USER"
              }
            }
          }

          env {
            name = "POSTGRES_PASSWORD"
            value_from {
              secret_key_ref {
                name = "blog-secrets"
                key  = "POSTGRES_PASSWORD"
              }
            }
          }

          env {
            name = "POSTGRES_DB"
            value_from {
              config_map_key_ref {
                name = "blog-config"
                key  = "POSTGRES_DB"
              }
            }
          }

          env {
            name  = "PGDATA"
            value = "/var/lib/postgresql/pgdata"
          }

          volume_mount {
            name       = "blogdb-data"
            mount_path = "/var/lib/postgresql"
          }
        }
        # created local volume for container to mount
        volume {
          name = "blogdb-data"

          persistent_volume_claim {
            claim_name = "blogdb-data"
          }
        }
      }
    }
  }
}



# create services for app and db
resource "kubernetes_service" "blog-service" {
    metadata {
        name = "blog-service"
        namespace = "blogs"
    }

    spec {
        selector = { 
            app = "blog"
        }

        port {
            protocol = "TCP"
            port = 80
            target_port = 8080
        }
        type = "ClusterIP"
    }
}

resource "kubernetes_service" "blogdb" {
    metadata {
        name = "blogdb"
        namespace = "blogs"
    }

    spec {
        cluster_ip = "None"
        selector = { 
            app = "blogdb"
        }

        port {
            protocol = "TCP"
            port = 5432
            target_port = 5432
        }
    }
}

# create ingress
resource "kubernetes_ingress_v1" "blog-ingress" {
    metadata {
        name = "blog-ingress"
        namespace = "blogs"
    }

    spec {
    ingress_class_name = "nginx"

    rule {
      host = "blog.local"

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "blog-service"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}