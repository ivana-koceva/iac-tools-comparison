# create namespace
resource "kubernetes_namespace" "blogs" {
  metadata {
    name = "blogs"
  }
}

# configmap with db env
resource "kubernetes_config_map" "blog-config" {
  metadata {
    name = "blog-config"
    namespace = kubernetes_namespace.blogs.metadata.0.name
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
    namespace = kubernetes_namespace.blogs.metadata.0.name
  }

  type = "Opaque"

  data = {
    POSTGRES_USER = "cG9zdGdyZXM="
    POSTGRES_PASSWORD = "YWRtaW4="
  }
}

# blog deployment
resource "kubernetes_deployment" "blog-deployment" {
  metadata {
    name = "blog-deployment"
    namespace = kubernetes_namespace.blogs.metadata.0.name
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
    namespace = kubernetes_namespace.blogs.metadata.0.name
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
        }
      }
    }
  }
}



# create services for app and db
resource "kubernetes_service" "blog-service" {
    metadata {
        name = "blog-service"
        namespace = kubernetes_namespace.blogs.metadata.0.name
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
        namespace = kubernetes_namespace.blogs.metadata.0.name
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
        namespace = kubernetes_namespace.blogs.metadata.0.name
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