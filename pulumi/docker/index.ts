import * as pulumi from "@pulumi/pulumi";
import * as docker from "@pulumi/docker";

// create images
const blog_app = new docker.RemoteImage("blog_app", {name: "ivanakoceva/blog-app:latest"});
const blog_db = new docker.RemoteImage("blog_db", {name: "postgres:17-alpine"});

// create network
const blog_network = new docker.Network("blog_network", {name: "blog_network"});

// create volume
const blogdb_data = new docker.Volume("blogdb_data", {name: "blogdb_data"});

// create containers
const db_service = new docker.Container("db_service", {
    image: blog_db.imageId,
    name: "db_service",
    networksAdvanced: [{
        name: blog_network.name,
    }],
    ports: [{
        internal: 5432,
        external: 5432,
    }],
    envs: [
        "POSTGRES_DB=blogs",
        "POSTGRES_USER=postgres",
        "POSTGRES_PASSWORD=admin"
    ],
    volumes: [{
        containerPath: "/var/lib/postgresql/data",
        volumeName: blogdb_data.name,
    }],
});