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
     external = var.postgres_port
  }
  
  env = [
     "POSTGRES_DB=${var.postgres_db}",
     "POSTGRES_USER=${var.postgres_user}",
     "POSTGRES_PASSWORD=${var.postgres_password}"
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
     external = var.app_port
  }
 
  env = [
      "POSTGRES_HOST=db_service",
      "POSTGRES_USER=${var.postgres_user}",
      "POSTGRES_PASSWORD=${var.postgres_password}",
      "POSTGRES_PORT=${var.postgres_port}",
      "POSTGRES_DB=${var.postgres_db}"
  ]

  # start after db container
  depends_on = [docker_container.db_service]
}


