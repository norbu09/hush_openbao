#!/bin/bash

# Script to set up example secrets in OpenBao for testing HushOpenbao
# 
# This script creates sample secrets that can be used with the basic_usage.exs example
#
# Prerequisites:
# 1. OpenBao CLI installed (or use docker)
# 2. OpenBao server running 
# 3. Environment variables set:
#    export VAULT_ADDR="http://localhost:8200"
#    export VAULT_TOKEN="your-dev-root-token"
#
# Usage: ./examples/setup_secrets.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 Setting up example secrets in OpenBao...${NC}"

# Check if vault CLI is available
if ! command -v vault &> /dev/null; then
    echo -e "${YELLOW}⚠️  vault CLI not found. Using docker instead...${NC}"
    VAULT_CMD="docker run --rm --network host -e VAULT_ADDR -e VAULT_TOKEN openbao/openbao:latest vault"
else
    VAULT_CMD="vault"
fi

# Check connection to OpenBao
echo -e "${BLUE}📡 Testing connection to OpenBao...${NC}"
if ! $VAULT_CMD status > /dev/null 2>&1; then
    echo -e "${RED}❌ Could not connect to OpenBao. Make sure:${NC}"
    echo -e "${RED}   1. OpenBao server is running${NC}"
    echo -e "${RED}   2. VAULT_ADDR is set (e.g., http://localhost:8200)${NC}"
    echo -e "${RED}   3. VAULT_TOKEN is set with valid token${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Connected to OpenBao successfully!${NC}"

# Enable KV v2 secrets engine if not already enabled
echo -e "${BLUE}🔧 Ensuring KV v2 secrets engine is enabled...${NC}"
if ! $VAULT_CMD secrets list | grep -q "^secret/"; then
    echo -e "${YELLOW}📦 Enabling KV v2 secrets engine at 'secret/'...${NC}"
    $VAULT_CMD secrets enable -path=secret kv-v2
else
    echo -e "${GREEN}✅ KV v2 secrets engine already enabled${NC}"
fi

# Create example database secrets
echo -e "${BLUE}🗄️  Creating database secrets...${NC}"
$VAULT_CMD kv put secret/myapp/database/password value="super_secret_db_password_123"
$VAULT_CMD kv put secret/myapp/database/host value="db.prod.example.com"
$VAULT_CMD kv put secret/myapp/database/port value="5432"
$VAULT_CMD kv put secret/myapp/database/username value="myapp_user"

# Create example API secrets
echo -e "${BLUE}🔑 Creating API secrets...${NC}"
$VAULT_CMD kv put secret/myapp/api/key value="sk_live_1234567890abcdef"
$VAULT_CMD kv put secret/myapp/api/url value="https://api.prod.example.com"

# Create multi-value secret example
echo -e "${BLUE}📝 Creating multi-value secret example...${NC}"
$VAULT_CMD kv put secret/myapp/redis \
  host="redis.prod.example.com" \
  port="6379" \
  password="redis_secret_password" \
  ssl="true"

# Create SSL certificate example (mock data)
echo -e "${BLUE}🔒 Creating SSL certificate secrets...${NC}"
$VAULT_CMD kv put secret/myapp/ssl/certificate value="-----BEGIN CERTIFICATE-----
MIICljCCAX4CCQDKWHHWVrYyNjANBgkqhkiG9w0BAQsFADAtMQswCQYDVQQGEwJV
UzELMAkGA1UECAwCQ0ExETAPBgNVBAoMCEV4YW1wbGUgQ28wHhcNMjMwMTAxMDAw
MDAwWhcNMjQwMTAxMDAwMDAwWjAtMQswCQYDVQQGEwJVUzELMAkGA1UECAwCQ0Ex
...
-----END CERTIFICATE-----"

$VAULT_CMD kv put secret/myapp/ssl/private_key value="-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDKWHHWVrYyNj...
-----END PRIVATE KEY-----"

# List created secrets
echo -e "${BLUE}📋 Listing created secrets:${NC}"
$VAULT_CMD kv list secret/myapp/

echo -e "${GREEN}🎉 Example secrets created successfully!${NC}"
echo -e "${GREEN}   You can now run: elixir examples/basic_usage.exs${NC}"

# Provide helpful commands
echo -e "\n${BLUE}🔍 Useful commands:${NC}"
echo -e "${YELLOW}   # List all secrets:${NC}"
echo -e "   $VAULT_CMD kv list secret/myapp/"
echo -e "${YELLOW}   # Read a specific secret:${NC}"
echo -e "   $VAULT_CMD kv get secret/myapp/database/password"
echo -e "${YELLOW}   # Read multi-value secret:${NC}"
echo -e "   $VAULT_CMD kv get secret/myapp/redis"
echo -e "${YELLOW}   # Delete a secret:${NC}"
echo -e "   $VAULT_CMD kv delete secret/myapp/database/password"

echo -e "\n${BLUE}📚 Environment variables for HushOpenbao:${NC}"
echo -e "export OPENBAO_ADDR=\"\$VAULT_ADDR\""
echo -e "export OPENBAO_TOKEN=\"\$VAULT_TOKEN\""