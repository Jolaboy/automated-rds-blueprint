# Automated Relational Data Store Blueprint

An infrastructure-level repository for automated schema creation, transactional seeding, and performance tuning for RDS PostgreSQL. Uses Flyway for versioned migrations and GitHub Actions for validation.

---

## Repository Layout

```text
automated-rds-blueprint/
├── migrations/
│   ├── V1__01_schema.sql
│   ├── V1__02_seeding.sql
│   └── V1__03_tuning.sql
└── scripts/
        └── start-local-db.sh
```

Notes:
- The `migrations/` files are Flyway-style versioned SQL scripts. Keep them immutable once published to avoid branch conflicts.
- CI workflow (if present) validates these migrations on each PR against a transient Postgres container.

---

## Tech Stack

- **Database:** PostgreSQL (RDS recommended, v15+)
- **Migrations:** Flyway (CLI or GitHub Action)
- **CI/CD:** GitHub Actions (transient-db validation)
- **Local sandbox:** Docker (see `scripts/start-local-db.sh`)

---

## Quickstart — Local Development

1. Make the script executable and start the local DB container:

```bash
chmod +x scripts/start-local-db.sh
./scripts/start-local-db.sh
```

2. (Optional) Run Flyway migrations against the local container using either the Flyway CLI or Docker:

Using Flyway CLI (example):

```bash
flyway -url=jdbc:postgresql://localhost:5432/blueprint_db \
             -user=db_operator \
             -password=SuperSecurePassword123! \
             -locations=filesystem:migrations \
             migrate
```

Using Flyway Docker image:

```bash
docker run --rm --network host \
    -v $(pwd)/migrations:/flyway/sql \
    flyway/flyway:9.16.1 \
    -url=jdbc:postgresql://host.docker.internal:5432/blueprint_db \
    -user=db_operator -password=$DB_PASSWORD migrate
```

Replace credentials and host networking flags as appropriate for your OS and Docker setup.

---

## Design Principles

- Use `UUIDv4` primary keys for distributed-safe inserts.
- Prefer `CREATE INDEX CONCURRENTLY` for large tables in production migrations to avoid table locks.
- Use partial and composite indexes to optimize hot-path queries and timeseries access patterns.
- Store sensitive values in a secrets manager; never commit credentials.

---

## CI/CD Validation

Typical CI validation (GitHub Actions) does:

1. Start a transient `postgres:15` container.
2. Wait for readiness.
3. Run Flyway (GitHub Action or container) to apply all migrations.
4. Fail the build if any migration or assertion fails.

---

## Architecture Topology

The diagram below summarizes the intended deployment and integration topology for this blueprint. It covers local development, CI validation, and production AWS RDS deployment with common services.

```mermaid
graph TD
    Developer[Developer]
    Repo[GitHub Repo]
    CI[GitHub Actions CI]
    Flyway[Flyway Migration Runner]
    LocalDB[Local Postgres (Docker)]
    AWS[AWS Account]
    VPC[VPC]
    PublicSubnet[Public Subnet]
    PrivateSubnet[Private Subnet]
    Bastion[Bastion / Jump Host]
    RDS[RDS PostgreSQL (Multi-AZ)]
    RDSProxy[RDS Proxy]
    Secrets[AWS Secrets Manager]

    Developer -->|push/pr| Repo
    Repo --> CI
    CI --> Flyway
    Flyway --> LocalDB

    Developer -->|optional local test| LocalDB

    Repo -->|deploy| AWS
    AWS --> VPC
    VPC --> PublicSubnet
    VPC --> PrivateSubnet
    PublicSubnet --> Bastion
    PrivateSubnet --> RDS
    RDS --> RDSProxy
    AWS --> Secrets
    Secrets --> RDSProxy

    style RDS fill:#fffbcc,stroke:#f2c14e
    style Secrets fill:#e6f7ff,stroke:#66b3ff
```

Short notes:
- CI uses a transient Postgres instance to validate migrations — this prevents breaking schema changes from merging.
- Production should deploy RDS inside private subnets, fronted by an RDS Proxy and with secrets stored in AWS Secrets Manager or Parameter Store.
- For high availability enable Multi-AZ and automated backups; for read-scaling consider Read Replicas.

---

## Next Steps

- Keep migration files small and focused: one logical change per versioned file.
- Add integration tests that assert expected DDL and critical constraints.
- If you'd like, I can add a `flyway.conf` example or a GitHub Actions validation workflow.

