terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.6.2"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# pull the images
resource "docker_image" "blog_app" {
  name = "ivanakoceva/blog-app:latest"
}

resource "docker_image" "blog_db" {
  name = "postgres:latest"
}

# create network
resource "docker_network" "blog_network" {
  name = "blog_network"
}

# create containers
resource "docker_container" "db_service" {
  image = docker_image.blog_db.image_id
  name = "db_service"
  
  networks_advanced {
     name = docker_network.blog_network.name
  }
  
  ports {
     internal = 5432
     external = 5432
  }
  
  env = [
     "POSTGRES_DB=blogs",
     "POSTGRES_USER=postgres",
     "POSTGRES_PASSWORD=admin"
  ]
}

resource "docker_container" "blog_service" {
  image = docker_image.blog_app.image_id
  name  = "blog_service"
  
  networks_advanced {
     name = docker_network.blog_network.name
  }

  ports {
     internal = 8080
     external = 8080
  }
 
  env = [
      "POSTGRES_HOST=db_service",
      "POSTGRES_USER=postgres",
      "POSTGRES_PASSWORD=admin",
      "POSTGRES_PORT=5432",
      "POSTGRES_DB=blogs"
  ]
}


