#!/bin/bash
# scripts/start-local-db.sh

echo " Spinning up local PostgreSQL sandbox..."
docker run --name rds-blueprint-local \
  -e POSTGRES_DB=blueprint_db \
  -e POSTGRES_USER=db_operator \
  -e POSTGRES_PASSWORD=SuperSecurePassword123! \
  -p 5432:5432 \
  -d postgres:15-alpine

echo "✅ Database is booting up on localhost:5432"