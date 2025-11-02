import * as pulumi from "@pulumi/pulumi";
import * as kubernetes from "@pulumi/kubernetes";

// stack config
const config = new pulumi.Config("blogs");
const POSTGRES_DB = config.require("POSTGRES_DB");
const POSTGRES_HOST = config.require("POSTGRES_HOST");
const POSTGRES_PORT = config.requireNumber("POSTGRES_PORT");
const POSTGRES_USER = config.requireSecret("POSTGRES_USER");
const POSTGRES_PASSWORD = config.requireSecret("POSTGRES_PASSWORD");

// labels
const appLabels = { app: "blog" };
const dbLabels = { app: "blogdb" };

// namespace
const ns = new kubernetes.core.v1.Namespace("blogs", {
    metadata: { name: "blogs" },
});

// configmap
const blogConfig = new kubernetes.core.v1.ConfigMap("blog-config", {
    metadata: { name: "blog-config", namespace: ns.metadata.name },
    data: {
        POSTGRES_DB,
        POSTGRES_HOST,
        POSTGRES_PORT: pulumi.interpolate`${POSTGRES_PORT}`,
    },
});

// secrets
const blogSecrets = new kubernetes.core.v1.Secret("blog-secrets", {
    metadata: { name: "blog-secrets", namespace: ns.metadata.name },
    type: "Opaque",
    stringData: {
        POSTGRES_USER: POSTGRES_USER,
        POSTGRES_PASSWORD: POSTGRES_PASSWORD,
    },
});

// PVC
const dbPvc = new kubernetes.core.v1.PersistentVolumeClaim("blogdb-data", {
    metadata: { name: "blogdb-data", namespace: ns.metadata.name },
    spec: {
        accessModes: ["ReadWriteOnce"],
        resources: { requests: { storage: "1Gi" } },
    },
});

// Postgres StatefulSet
const db = new kubernetes.apps.v1.StatefulSet("blogdb", {
    metadata: { name: "blogdb", namespace: ns.metadata.name },
    spec: {
        serviceName: "blogdb-service",
        replicas: 1,
        selector: { matchLabels: dbLabels },
        template: {
            metadata: { labels: dbLabels },
            spec: {
                containers: [{
                    name: "postgres",
                    image: "postgres:17-alpine",
                    env: [
                        { name: "POSTGRES_USER", valueFrom: { secretKeyRef: { name: "blog-secrets", key: "POSTGRES_USER" } } },
                        { name: "POSTGRES_PASSWORD", valueFrom: { secretKeyRef: { name: "blog-secrets", key: "POSTGRES_PASSWORD" } } },
                        { name: "POSTGRES_DB", valueFrom: { configMapKeyRef: { name: "blog-config", key: "POSTGRES_DB" } } },
                        { name: "PGDATA", value: "/var/lib/postgresql/data/pgdata" },
                    ],
                    volumeMounts: [
                        { name: "blogdb-data", mountPath: "/var/lib/postgresql/data" },
                    ],
                    ports: [{ containerPort: 5432 }],
                }],
            },
        },
        volumeClaimTemplates: [
            {
                metadata: { name: "blogdb-data" },
                spec: {
                    accessModes: ["ReadWriteOnce"],
                    resources: { requests: { storage: "1Gi" } },
                },
            },
        ],
    },
});

// Blog app Deployment
const app = new kubernetes.apps.v1.Deployment("blog-deployment", {
    metadata: { name: "blog-deployment", namespace: ns.metadata.name },
    spec: {
        replicas: 2,
        selector: { matchLabels: appLabels },
        template: {
            metadata: { labels: appLabels },
            spec: {
                containers: [{
                    name: "blog-app",
                    image: "ivanakoceva/blog-app:latest",
                    ports: [{ containerPort: 8080 }],
                    env: [
                        { name: "POSTGRES_HOST", valueFrom: { configMapKeyRef: { name: "blog-config", key: "POSTGRES_HOST" } } },
                        { name: "POSTGRES_PORT", valueFrom: { configMapKeyRef: { name: "blog-config", key: "POSTGRES_PORT" } } },
                        { name: "POSTGRES_DB", valueFrom: { configMapKeyRef: { name: "blog-config", key: "POSTGRES_DB" } } },
                        { name: "POSTGRES_USER", valueFrom: { secretKeyRef: { name: "blog-secrets", key: "POSTGRES_USER" } } },
                        { name: "POSTGRES_PASSWORD", valueFrom: { secretKeyRef: { name: "blog-secrets", key: "POSTGRES_PASSWORD" } } },
                    ],
                }],
            },
        },
    },
});

// Services
const appService = new kubernetes.core.v1.Service("blog-service", {
    metadata: { name: "blog-service", namespace: ns.metadata.name },
    spec: {
        selector: appLabels,
        ports: [{ port: 80, targetPort: 8080 }],
        type: "ClusterIP",
    },
});

const dbService = new kubernetes.core.v1.Service("blogdb", {
    metadata: { name: "blogdb", namespace: ns.metadata.name },
    spec: {
        selector: dbLabels,
        clusterIP: "None", // headless
        ports: [{ port: 5432, targetPort: 5432 }],
    },
});

// Ingress
const ingress = new kubernetes.networking.v1.Ingress("blog-ingress", {
    metadata: { name: "blog-ingress", namespace: ns.metadata.name },
    spec: {
        ingressClassName: "nginx",
        rules: [
            {
                host: "blog.local",
                http: {
                    paths: [
                        {
                            path: "/",
                            pathType: "Prefix",
                            backend: {
                                service: {
                                    name: "blog-service",
                                    port: { number: 80 },
                                },
                            },
                        },
                    ],
                },
            },
        ],
    },
});