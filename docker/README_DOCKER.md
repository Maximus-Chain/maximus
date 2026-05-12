# Maximus Core - Docker Quick Start Guide

Want your own Maximus node running in minutes? This guide makes it easy.

---

## 🚀 Easiest Way (1-click)

Just install Docker first. Then copy and paste these commands:

### On Your Computer (Intel/AMD)

```bash
docker run -d \
  --name maximusd \
  -p 9938:9938 \
  -p 9939:9939 \
  ghcr.io/maximus-chain/maximusd:latest
```

### On Raspberry Pi or Mac M1/M2/M3

```bash
docker run -d \
  --name maximusd \
  -p 9938:9938 \
  -p 9939:9939 \
  ghcr.io/maximus-chain/maximusd:latest-arm64
```

Done! Your node is now running. It will start downloading the blockchain automatically.

---

## 📊 Useful Commands (After Starting)

```bash
# Check if it's running
docker ps

# Watch real-time logs (see sync progress)
docker logs -f maximusd

# Exit logs: Ctrl + C

# Get node info
docker exec maximusd maximus-cli getblockchaininfo

# Check how many blocks downloaded
docker exec maximusd maximus-cli getblockchaininfo | grep blocks

# Stop the node
docker stop maximusd

# Start it again
docker start maximusd

# Remove the container (keeps your data safe)
docker stop maximusd && docker rm maximusd
```

---

## 🔐 Basic Security

**Important:** By default, a password is created automatically. For production, use your own:

```bash
docker run -d \
  --name maximusd \
  -p 9938:9938 \
  -p 9939:9939 \
  -e RPC_PASSWORD=YOUR_VERY_SECURE_PASSWORD \
  ghcr.io/maximus-chain/maximusd:latest
```

> **Never** expose port 9939 (RPC) to the internet. It's only for local use.

---

## 🧪 I Want to Test (Testnet)

To try without using real money:

```bash
docker run -d \
  --name maximusd-testnet \
  -p 19938:19938 \
  -p 19939:19939 \
  -e NETWORK=testnet \
  ghcr.io/maximus-chain/maximusd:latest
```

---

## 💾 Saving Your Data (Volumes)

By default, Docker stores the blockchain in internal storage. If you want to choose where data is saved:

```bash
# Create a folder for data
mkdir -p ~/maximus-data

# Run maximus with that folder
docker run -d \
  --name maximusd \
  -p 9938:9938 \
  -p 9939:9939 \
  -v ~/maximus-data:/home/maximus/.maximuscore \
  ghcr.io/maximus-chain/maximusd:latest
```

---

## ❓ Frequently Asked Questions

### How much space do I need?
- Mainnet: ~50 GB (and growing)
- Testnet: ~5 GB

### How long does sync take?
- First time can take hours/days depending on your connection
- You can watch progress with `docker logs -f maximusd`

### Can I use it on a Raspberry Pi?
Yes! Use the `latest-arm64` image

### What if I shut down my computer?
Your data is safe. When you start Docker and run `docker start maximusd`, it will continue where it left off.

### How do I know it's working well?
Run:
```bash
docker exec maximusd maximus-cli getnetworkinfo
```

You should see `"version"`, `"subversion"` and `"protocolversion"`.

---

## 🛠️ Troubleshooting

### Container won't start
```bash
# See what error occurred
docker logs maximusd

# If error says "port already allocated", another program is using that port
# Close that program or change the ports:
docker run -d \
  --name maximusd \
  -p 19938:9938 \
  -p 19939:9939 \
  ghcr.io/maximus-chain/maximusd:latest
```

### Node won't sync
```bash
# See how many peers it has connected
docker exec maximusd maximus-cli getpeerinfo

# If empty, it might be a network issue. Wait a few minutes.
```

### Need more help
```bash
# See all logs
docker logs maximusd

# Enter the container to explore
docker exec -it maximusd /bin/bash
```

---

---

# 📖 Technical Documentation (For Advanced Users)

## Available Images

| Image | What it's for |
|-------|---------------|
| `latest` | Stable release (Intel/AMD) |
| `latest-arm64` | Stable release (Raspberry Pi, Mac M1/M2/M3) |
| `develop` | Development/testing version |
| `v1.x.x` | Specific version |

### Pull a Specific Image

```bash
# Stable version
docker pull ghcr.io/maximus-chain/maximusd:latest

# Specific version
docker pull ghcr.io/maximus-chain/maximusd:v1.1.0

# Development version
docker pull ghcr.io/maximus-chain/maximusd:develop
```

## Docker Compose (Server Deployment)

Create a file called `docker-compose.yml`:

```yaml
version: '3.8'

services:
  maximusd:
    image: ghcr.io/maximus-chain/maximusd:latest
    container_name: maximusd
    restart: always
    ports:
      - "9938:9938"  # P2P (node connections)
      - "9939:9939"  # RPC (API and control)
    environment:
      - NETWORK=mainnet
      - RPC_USER=admin
      - RPC_PASSWORD=YOUR_PASSWORD_HERE
    volumes:
      - maximus-data:/home/maximus/.maximuscore
    logging:
      driver: "json-file"
      options:
        max-size: "100m"
        max-file: "3"

volumes:
  maximus-data:
```

### Docker Compose Commands

```bash
# Start
docker-compose up -d

# Watch logs
docker-compose logs -f

# Stop
docker-compose down

# Start again after stopping
docker-compose up -d
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `NETWORK` | `mainnet` | Network: `mainnet`, `testnet`, `regtest` |
| `RPC_USER` | `maximus` | RPC username |
| `RPC_PASSWORD` | (auto-generated) | RPC password |
| `RPC_PORT` | `9939` | RPC port (mainnet) |
| `PORT` | `9938` | P2P port |

## Build Your Own Image

If you prefer to build instead of downloading:

```bash
# Clone the repo
git clone https://github.com/maximus-chain/maximus.git
cd maximus

# Build
docker build -f docker/Dockerfile -t maximus-local:latest .
```

## Server Deployment (Production)

### Option 1: Direct Pull

```bash
# On your server
docker pull ghcr.io/maximus-chain/maximusd:latest

# Run
docker run -d \
  --name maximusd \
  -p 9938:9938 \
  -p 9939:9939 \
  -v /opt/maximus/data:/home/maximus/.maximuscore \
  -e RPC_PASSWORD=your_secure_password \
  ghcr.io/maximus-chain/maximusd:latest
```

### Option 2: With systemd (Auto-restart)

Create `/etc/systemd/system/maximusd.service`:

```ini
[Unit]
Description=Maximus Core Daemon
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStartPre=/usr/bin/docker pull ghcr.io/maximus-chain/maximusd:latest
ExecStart=/usr/bin/docker run \
    --name maximusd \
    --read-only \
    --tmpfs /tmp \
    -p 9938:9938 \
    -p 9939:9939 \
    -v /opt/maximus/data:/home/maximus/.maximuscore \
    -e RPC_USER=admin \
    -e RPC_PASSWORD=YOUR_PASSWORD \
    ghcr.io/maximus-chain/maximusd:latest
ExecStop=/usr/bin/docker stop -t 60 maximusd
ExecStopPost=/usr/bin/docker rm -f maximusd
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
```

Enable it:

```bash
sudo systemctl daemon-reload
sudo systemctl enable maximusd
sudo systemctl start maximusd
sudo systemctl status maximusd
```

## Node Verification

### Is it synced?

```bash
docker exec maximusd maximus-cli getblockchaininfo
```

Look for these values:
- `"blocks"`: number of blocks downloaded
- `"verificationprogress"`: 0.99+ means synced

### How many peers?

```bash
docker exec maximusd maximus-cli getpeerinfo
```

### How much space used?

```bash
docker exec maximusd du -sh /home/maximus/.maximuscore
```

## Ports

| Port | Protocol | Use |
|------|----------|-----|
| 9938 | P2P | Node-to-node connections (public) |
| 9939 | RPC | API and control (local only) |
| 19938 | P2P | Testnet |
| 19939 | RPC | Testnet |

## Links

- [Maximus Core GitHub](https://github.com/maximus-chain/maximus)
- [Official Documentation](https://docs.maximuschain.com)
- [Docker Docs](https://docs.docker.com)