# Maximus Core - Docker Deployment Guide

This directory contains all the necessary files to build and run Maximus Core using Docker containers.

## Table of Contents

- [Quick Start](#quick-start)
- [Building Locally](#building-locally)
- [Testing Before Push](#testing-before-push)
- [Deployment to Your Server](#deployment-to-your-server)
- [Configuration Options](#configuration-options)
- [Troubleshooting](#troubleshooting)

---

## Quick Start

### Build and run locally

```bash
# Build the image
docker build -f docker/Dockerfile -t maximus-local:latest .

# Run the container
docker run -d \
  --name maximusd \
  -p 9938:9938 \
  -p 9939:9939 \
  -v maximus-data:/home/maximus/.maximuscore \
  maximus-local:latest
```

### Using Docker Compose (Recommended)

```bash
cd docker

# Start the container
docker-compose up -d

# View logs
docker-compose logs -f

# Stop the container
docker-compose down
```

---

## Building Locally

### Prerequisites

- Docker 20.10+ with BuildKit enabled
- 4GB+ RAM available for build
- ~20GB disk space (for build cache)
- Linux, macOS, or Windows with WSL2

### Enable BuildKit

```bash
# Option 1: Environment variables
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# Option 2: Add to ~/.bashrc or ~/.zshrc
echo 'export DOCKER_BUILDKIT=1' >> ~/.bashrc
echo 'export COMPOSE_DOCKER_CLI_BUILD=1' >> ~/.bashrc
```

### Build Commands

```bash
# Build for current architecture only (faster)
docker build -f docker/Dockerfile -t maximus-local:latest .

# Build for multiple architectures (amd64 + arm64)
docker buildx create --use
docker buildx build \
  -f docker/Dockerfile \
  --platform linux/amd64,linux/arm64 \
  -t maximus-local:latest \
  --load \
  .

# Build with no cache (clean build)
docker build --no-cache -f docker/Dockerfile -t maximus-local:latest .
```

---

## Testing Before Push

### Step 1: Verify Build

```bash
# Check the image was created
docker images | grep maximus

# Verify binary exists inside image
docker run --rm maximus-local:latest /usr/local/bin/maximusd --version
```

### Step 2: Run Basic Tests

```bash
# Start container in foreground to see logs
docker run -it \
  -p 9938:9938 \
  -p 9939:9939 \
  maximus-local:latest

# Or with docker-compose in foreground
docker-compose up

# Press Ctrl+C to stop
```

### Step 3: Test RPC Connection

```bash
# Wait for the node to start (about 30 seconds)
sleep 30

# Create a test file with RPC credentials
cat > /tmp/rpc-test.sh << 'EOF'
#!/bin/bash
RPC_USER="${RPC_USER:-maximus}"
RPC_PASSWORD="${RPC_PASSWORD:-changeme}"
RPC_HOST="${RPC_HOST:-localhost}"
RPC_PORT="${RPC_PORT:-9939}"

echo "Testing RPC connection to ${RPC_HOST}:${RPC_PORT}..."
curl -s -X POST \
  -H "Content-Type: application/json" \
  -u "${RPC_USER}:${RPC_PASSWORD}" \
  -d '{"jsonrpc":"1.0","id":"test","method":"getnetworkinfo","params":[]}' \
  http://${RPC_HOST}:${RPC_PORT}/
EOF

chmod +x /tmp/rpc-test.sh

# Run the test
RPC_USER=maximus RPC_PASSWORD=changeme_secure_password_here /tmp/rpc-test.sh
```

### Step 4: Verify Blockchain Sync

```bash
# Check sync status
docker exec maximusd /usr/local/bin/maximus-cli getblockchaininfo

# Look for "blocks" and "verificationprogress" in the output
# 99%+ means fully synced
```

### Step 5: Test Different Networks

```bash
# Test mainnet (default)
docker-compose up -d
sleep 60
docker exec maximusd maximus-cli getblockchaininfo | grep initialblockdownload

# Test testnet
docker-compose -f docker-compose.yml -f docker-compose.testnet.yml up -d
# Note: You may need to create docker-compose.testnet.yml or use environment variables
NETWORK=testnet docker-compose up -d
```

### Step 6: Volume Persistence Test

```bash
# Create the container with a named volume
docker-compose up -d

# Wait for it to start and create some data
sleep 30

# Check that data was created
docker exec maximusd ls -la /home/maximus/.maximuscore/

# Stop and remove the container
docker-compose down

# Start again - data should persist
docker-compose up -d
sleep 10

# Verify data still exists
docker exec maximusd ls -la /home/maximus/.maximuscore/
```

### Step 7: Resource Usage Check

```bash
# Check CPU and memory usage
docker stats maximusd --no-stream

# Check disk usage of the volume
docker volume inspect docker_maximus-data

# Inside container
docker exec maximusd du -sh /home/maximus/.maximuscore
```

---

## Deployment to Your Server

### Option 1: Pull from GitHub Container Registry

```bash
# On your server, login to ghcr.io
echo "$GITHUB_TOKEN" | docker login ghcr.io -u USERNAME --password-stdin

# Pull the image
docker pull ghcr.io/maximuschain/maximusd:develop

# Run the container
docker run -d \
  --name maximusd \
  -p 9938:9938 \
  -p 9939:9939 \
  -v /path/to/maximus-data:/home/maximus/.maximuscore \
  -e RPC_PASSWORD=your_secure_password \
  ghcr.io/maximuschain/maximusd:develop
```

### Option 2: Copy Image as Tar (Air-Gapped)

```bash
# On your build machine, save the image
docker save ghcr.io/maximuschain/maximusd:develop -o maximusd.tar

# Transfer to server (USB, scp, etc.)
scp maximusd.tar user@your-server:/tmp/

# On your server, load the image
docker load -i /tmp/maximusd.tar

# Run
docker run -d \
  --name maximusd \
  -p 9938:9938 \
  -p 9939:9939 \
  ghcr.io/maximuschain/maximusd:develop
```

### Option 3: Deploy with Docker Compose (Recommended for Production)

Create `docker-compose.prod.yml` on your server:

```yaml
version: '3.8'

services:
  maximusd:
    image: ghcr.io/maximuschain/maximusd:develop
    container_name: maximusd
    restart: always
    ports:
      - "9938:9938"  # Mainnet P2P
      - "9939:9939"  # Mainnet RPC
    environment:
      - NETWORK=mainnet
      - RPC_USER=admin
      - RPC_PASSWORD=<PUT_A_STRONG_PASSWORD_HERE>
      - RPC_PORT=9939
      - PORT=9938
    volumes:
      - /opt/maximus/data:/home/maximus/.maximuscore
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9938"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 60s
    logging:
      driver: "json-file"
      options:
        max-size: "100m"
        max-file: "3"
```

Deploy:

```bash
# Create data directory
sudo mkdir -p /opt/maximus/data
sudo chown 1000:1000 /opt/maximus/data

# Deploy
docker-compose -f docker-compose.prod.yml up -d

# Check status
docker-compose -f docker-compose.prod.yml logs -f
```

### Option 4: Deploy with systemd (Production Recommended)

Create `/etc/systemd/system/maximusd.service`:

```ini
[Unit]
Description=Maximus Core Daemon
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStartPre=/usr/bin/docker pull ghcr.io/maximuschain/maximusd:develop
ExecStart=/usr/bin/docker run \
    --name maximusd \
    --read-only \
    --tmpfs /tmp \
    -p 9938:9938 \
    -p 9939:9939 \
    -v /opt/maximus/data:/home/maximus/.maximuscore \
    -e RPC_USER=admin \
    -e RPC_PASSWORD=<YOUR_PASSWORD> \
    ghcr.io/maximuschain/maximusd:develop
ExecStop=/usr/bin/docker stop -t 60 maximusd
ExecStopPost=/usr/bin/docker rm -f maximusd
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable maximusd
sudo systemctl start maximusd
sudo systemctl status maximusd
```

---

## Configuration Options

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `NETWORK` | `mainnet` | Network: `mainnet`, `testnet`, or `regtest` |
| `RPC_USER` | `maximus` | RPC authentication username |
| `RPC_PASSWORD` | auto-generated | RPC authentication password |
| `RPC_PORT` | `9939` | RPC port (mainnet) |
| `PORT` | `9938` | P2P port |
| `MAXIMUSD_OPTS` | | Extra command line options for maximusd |
| `USER_ID` | `1000` | UID of the maximus user inside container |
| `GROUP_ID` | `1000` | GID of the maximus group inside container |

### Example Configurations

```bash
# Mainnet with custom RPC credentials
docker run -d \
  -e RPC_USER=myuser \
  -e RPC_PASSWORD=supersecret123 \
  maximus-local:latest

# Testnet
docker run -d \
  -e NETWORK=testnet \
  maximus-local:latest

# Regtest for development
docker run -d \
  -e NETWORK=regtest \
  -e MAXIMUSD_OPTS="-printtoconsole=1 -debug=1" \
  maximus-local:latest

# Disable RPC authentication (NOT FOR PRODUCTION)
docker run -d \
  -e RPC_PASSWORD= "" \
  maximus-local:latest
```

### Volume Mounts

| Mount Point | Description |
|-------------|-------------|
| `/home/maximus/.maximuscore` | Blockchain data and config |

---

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker logs maximusd

# Run in foreground to see errors
docker run -it maximus-local:latest
```

### RPC Connection Refused

```bash
# Check if maximusd is running
docker exec maximusd maximus-cli getblockchaininfo

# Check RPC configuration
docker exec maximusd cat /home/maximus/.maximuscore/maximus.conf

# Verify ports are exposed
docker port maximusd
```

### Out of Disk Space

```bash
# Check disk usage
docker system df

# Prune unused images and containers
docker system prune -a

# Prune volumes (WARNING: deletes blockchain data)
docker volume prune
```

### Slow Sync

```bash
# Check peer connections
docker exec maximusd maximus-cli getpeerinfo

# Force add a peer
docker exec maximusd maximus-cli addnode "seed.maximus.org:9938" add

# Check sync progress
docker exec maximusd maximus-cli getblockchaininfo
```

### View Logs in Real-Time

```bash
# All logs
docker logs -f maximusd

# Only errors
docker logs -f maximusd 2>&1 | grep -i error

# Last 100 lines
docker logs --tail 100 maximusd
```

### Access Container Shell

```bash
# If running as root user in container
docker exec -u root -it maximusd /bin/bash

# As the maximus user
docker exec -it maximusd /bin/bash
```

---

## Security Notes

1. **Change default RPC password** - Always set a strong `RPC_PASSWORD`
2. **Don't expose RPC to internet** - Keep port 9939 firewalled
3. **Use TLS for RPC** - Configure RPC over TLS in production
4. **Regular updates** - Pull latest image regularly
5. **Backup wallet** - If using wallet features, backup regularly
6. **Read-only mode** - Use `--read-only` flag for added security with Docker

---

## Links

- [Maximus Core GitHub](https://github.com/maximuschain/maximus)
- [Maximus Core Documentation](https://docs.maximuschain.com)
- [Docker Documentation](https://docs.docker.com)