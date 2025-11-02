import * as pulumi from "@pulumi/pulumi";
import * as docker from "@pulumi/docker";

// stack specific config vars
const config = new pulumi.Config("blogs");
const POSTGRES_DB = config.require("POSTGRES_DB");
const POSTGRES_HOST = config.require("POSTGRES_HOST");
const POSTGRES_PORT = config.requireNumber("POSTGRES_PORT");
const APPLICATION_PORT = config.requireNumber("APPLICATION_PORT");
const POSTGRES_USER = config.requireSecret("POSTGRES_USER");
const POSTGRES_PASSWORD = config.requireSecret("POSTGRES_PASSWORD");

const stack = pulumi.getStack();

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
        internal: POSTGRES_PORT,
        external: POSTGRES_PORT,
    }],
    envs: [
        `POSTGRES_DB=${POSTGRES_DB}`,
        pulumi.interpolate`POSTGRES_USER=${POSTGRES_USER}`,
        pulumi.interpolate`POSTGRES_PASSWORD=${POSTGRES_PASSWORD}`
    ],
    volumes: [{
        containerPath: "/var/lib/postgresql/data",
        volumeName: blogdb_data.name,
    }],
});

const blog_service = new docker.Container("blog_service", {
    image: blog_app.imageId,
    name: "blog_service",
    networksAdvanced: [{
        name: blog_network.name,
    }],
    ports: [{
        internal: APPLICATION_PORT,
        external: APPLICATION_PORT,
    }],
    envs: [
        `POSTGRES_HOST=${POSTGRES_HOST}`,
        `POSTGRES_DB=${POSTGRES_DB}`,
        pulumi.interpolate`POSTGRES_USER=${POSTGRES_USER}`,
        pulumi.interpolate`POSTGRES_PASSWORD=${POSTGRES_PASSWORD}`,
        `POSTGRES_PORT=${POSTGRES_PORT}`,
    ],
    volumes: [{
        containerPath: "/var/lib/postgresql/data",
        volumeName: blogdb_data.name,
    }],
}, {dependsOn: [db_service]});