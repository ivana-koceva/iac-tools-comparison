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