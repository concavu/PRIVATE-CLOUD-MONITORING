# Private Cloud Monitoring

Containerized private-cloud storage and observability platform built with Docker Compose.

## Architecture

- Nginx reverse proxy with TLS at the frontend edge (`172.20.10.0/24`)
- Nextcloud application with MariaDB and Redis on an isolated backend network (`172.20.20.0/24`)
- MinIO S3-compatible object storage on a dedicated storage network (`172.20.30.0/24`)
- Prometheus, Grafana, cAdvisor, and Node Exporter for monitoring

## Quick start

1. Copy `.env.example` to `.env`. The setup script generates unique random values for missing or placeholder service passwords and preserves any non-placeholder values already present.
2. Run `./setup.sh` on Linux/macOS, or `./setup.ps1` in PowerShell. OpenSSL must be installed and available on `PATH` to generate the local self-signed TLS certificate when needed. The generated passwords are stored in `.env`; keep that file private and back it up securely.
3. Start the core stack:

   ```bash
   docker compose up -d
   ```

4. Start monitoring:

   ```bash
   docker compose -f docker-compose.monitoring.yml up -d
   ```

5. Check the core stack with `docker compose ps`, and monitoring with `docker compose -f docker-compose.monitoring.yml ps`.

If you already have a `.env` from an earlier version, add a strong `GRAFANA_ADMIN_PASSWORD` value before starting the monitoring stack.

The development endpoints are `https://cloud.local`, Grafana at `http://localhost:3000`, and the MinIO console at `https://cloud.local/minio-console/`. Grafana is bound to localhost and is not exposed to other hosts. Add `cloud.local` to the host's hosts file if needed. The TLS certificate is self-signed for local development. MinIO's API and console ports are not published directly to the host.

Prometheus currently scrapes itself, cAdvisor, and Node Exporter. Grafana automatically provisions Prometheus as its data source and a starter dashboard for host CPU/memory, container CPU/memory, and scrape target health. Application-specific exporters and application dashboards for Nextcloud, MariaDB, Redis, MinIO, and Nginx are not included yet.

On Docker Desktop for Windows/macOS, host and container metrics describe Docker Desktop's Linux VM, not the underlying Windows/macOS host.

## Validate before starting

Run these commands from the project root. They validate Bash syntax and both Compose configurations without starting containers or changing stored data:

```bash
bash -n setup.sh scripts/backup.sh scripts/restore.sh scripts/optimize.sh
docker compose --env-file .env.example config --quiet
docker compose --env-file .env.example -f docker-compose.monitoring.yml config --quiet
```

On Windows, Git Bash can run the `bash -n` syntax check. Run operational shell scripts in Linux, macOS, or WSL2 with Docker Engine; Git Bash alone is not a supported environment for backup/restore operations. With Docker Desktop, Compose validation can also be run from PowerShell.

To smoke-test deployment, use an isolated machine or disposable clone, replace every placeholder secret, run the setup script, then start the stacks. Do not run restore or backup tests against data you need to keep.

## Security notes

- `.env` and private TLS keys are intentionally excluded from Git.
- Replace all example credentials before any shared or production deployment.
- Credentials included in earlier public revisions should be considered exposed. Rotate any value you actually used; changing `.env` alone does not reset an existing Grafana admin password.
- cAdvisor runs privileged and reads host/container resources. Deploy the monitoring stack only on a trusted host; Grafana is bound to localhost, and Prometheus/exporter ports are not published to the host.
- Review the exposed ports and mount permissions for the target host.

## Project documentation

The architecture summary from the original project brief is kept in `docs/project-summary.md`.

## Portfolio

See the personal portfolio and selected-project overview at [concavu.github.io/vu-tran-portfolio](https://concavu.github.io/vu-tran-portfolio/).
