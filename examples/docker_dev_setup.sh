#!/bin/bash

# Development setup script for HushOpenbao using Docker
#
# This script sets up a local OpenBao development server using Docker
# and configures example secrets for testing.
#
# Usage: ./examples/docker_dev_setup.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🐳 Setting up OpenBao development environment with Docker...${NC}"

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is required but not found. Please install Docker first.${NC}"
    exit 1
fi

# Stop and remove any existing OpenBao containers
echo -e "${BLUE}🧹 Cleaning up existing OpenBao containers...${NC}"
docker stop openbao-dev 2>/dev/null || true
docker rm openbao-dev 2>/dev/null || true

# Start OpenBao in development mode
echo -e "${BLUE}🚀 Starting OpenBao development server...${NC}"
docker run -d \
  --name openbao-dev \
  --cap-add=IPC_LOCK \
  -p 8200:8200 \
  -e 'VAULT_DEV_ROOT_TOKEN_ID=dev-root-token' \
  -e 'VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200' \
  openbao/openbao:latest \
  server -dev

# Wait for OpenBao to start
echo -e "${YELLOW}⏳ Waiting for OpenBao to start...${NC}"
sleep 5

# Check if OpenBao is running
if ! docker ps | grep -q openbao-dev; then
    echo -e "${RED}❌ Failed to start OpenBao container${NC}"
    exit 1
fi

# Set environment variables for vault CLI
export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN="dev-root-token"

echo -e "${GREEN}✅ OpenBao development server is running!${NC}"
echo -e "${GREEN}   Server URL: http://localhost:8200${NC}"
echo -e "${GREEN}   Root Token: dev-root-token${NC}"

# Set up example secrets
echo -e "${BLUE}🔐 Setting up example secrets...${NC}"

# Use vault CLI from Docker
VAULT_CMD="docker run --rm --network host -e VAULT_ADDR -e VAULT_TOKEN openbao/openbao:latest vault"

# Create example secrets
echo -e "${BLUE}📝 Creating database secrets...${NC}"
$VAULT_CMD kv put secret/myapp/database/password value="dev_db_password_123"
$VAULT_CMD kv put secret/myapp/database/host value="localhost"
$VAULT_CMD kv put secret/myapp/database/port value="5432"
$VAULT_CMD kv put secret/myapp/database/username value="dev_user"

echo -e "${BLUE}🔑 Creating API secrets...${NC}"
$VAULT_CMD kv put secret/myapp/api/key value="sk_dev_abcdef123456789"
$VAULT_CMD kv put secret/myapp/api/url value="https://api.dev.example.com"

echo -e "${BLUE}📊 Creating Redis configuration...${NC}"
$VAULT_CMD kv put secret/myapp/redis \
  host="localhost" \
  port="6379" \
  password="dev_redis_password" \
  ssl="false"

echo -e "${GREEN}🎉 Development environment setup complete!${NC}"

# Display useful information
echo -e "\n${BLUE}🔍 Environment Information:${NC}"
echo -e "${YELLOW}   OpenBao URL:${NC} http://localhost:8200"
echo -e "${YELLOW}   Root Token:${NC} dev-root-token"
echo -e "${YELLOW}   Web UI:${NC} http://localhost:8200/ui"

echo -e "\n${BLUE}📚 Environment variables for development:${NC}"
echo -e "export OPENBAO_ADDR=\"http://localhost:8200\""
echo -e "export OPENBAO_TOKEN=\"dev-root-token\""

echo -e "\n${BLUE}🚀 Quick test commands:${NC}"
echo -e "${YELLOW}   # Test HushOpenbao:${NC}"
echo -e "   OPENBAO_ADDR=http://localhost:8200 OPENBAO_TOKEN=dev-root-token elixir examples/basic_usage.exs"
echo -e "${YELLOW}   # Run tests:${NC}"
echo -e "   mix test"
echo -e "${YELLOW}   # Access OpenBao UI:${NC}"
echo -e "   open http://localhost:8200/ui (token: dev-root-token)"

echo -e "\n${BLUE}🛑 To stop the development server:${NC}"
echo -e "   docker stop openbao-dev && docker rm openbao-dev"

echo -e "\n${GREEN}✨ Happy coding with HushOpenbao!${NC}"