# Enterprise Private Cloud and Monitoring

This project implements a private-cloud storage platform and monitoring layer using a defense-in-depth, microservices-oriented architecture.

## Network segmentation

- Frontend DMZ `172.20.10.0/24`: Nginx edge reverse proxy and TLS termination.
- Internal backend `172.20.20.0/24`: Nextcloud, MariaDB, and Redis. The backend network is internal-only.
- Storage network `172.20.30.0/24`: Nextcloud to MinIO S3-compatible object storage.

## Technology stack

Docker Compose, Nginx, Nextcloud, MariaDB, Redis, MinIO S3, Prometheus, Grafana, cAdvisor, and Node Exporter.

## Observability

Prometheus scrapes host/container metrics, MariaDB and Redis exporters, Nginx status, MinIO cluster metrics, and black-box HTTP checks for Nextcloud and MinIO. Grafana provisions the Prometheus data source plus host/container and service dashboards. Alert rules cover target availability, HTTP probes, host capacity, container memory, and OOM events. External email/chat notification routing is not configured.
