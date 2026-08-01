#!/bin/bash
# ============================================
# Maximus Core - Docker Entrypoint Script
# ============================================
# All configuration via DAEMON_ARGS env var
# SNAPSHOT_URL for bootstrap acceleration
# ============================================

set -e

# Data directory
DATA_DIR="${HOME}/.maximuscore"

# ============================================
# Wait for filesystem readiness
# ============================================
wait_ready() {
    local max_wait=30
    local count=0
    echo "Waiting for filesystem to be ready..."
    while [ $count -lt $max_wait ]; do
        if [ -w "${DATA_DIR}" ] || mkdir -p "${DATA_DIR}" 2>/dev/null; then
            return 0
        fi
        sleep 1
        count=$((count + 1))
    done
    echo "Warning: Filesystem not ready after ${max_wait}s"
}

# ============================================
# Bootstrap from snapshot
# ============================================
bootstrap_snapshot() {
    local snapshot_url="${SNAPSHOT_URL:-}"
    local snapshot_file="/tmp/snapshot.tar.xz"

    if [ -z "${snapshot_url}" ]; then
        return 0
    fi

    # Skip if already synced (chainstate exists)
    if [ -d "${DATA_DIR}/chainstate" ] || [ -d "${DATA_DIR}/testnet3/chainstate" ]; then
        echo "Chainstate already exists, skipping snapshot bootstrap"
        return 0
    fi

    echo "Downloading snapshot from: ${snapshot_url}"
    echo "This may take several minutes..."

    # Download with progress
    if command -v curl &> /dev/null; then
        curl -fL --progress-bar -o "${snapshot_file}" "${snapshot_url}"
    elif command -v wget &> /dev/null; then
        wget -q --show-progress -O "${snapshot_file}" "${snapshot_url}"
    else
        echo "Error: Neither curl nor wget found"
        return 1
    fi

    echo "Extracting snapshot..."
    mkdir -p "${DATA_DIR}"

    # Extract based on extension
    case "${snapshot_url}" in
        *.tar.xz|*.txz)
            tar -xJf "${snapshot_file}" -C "${DATA_DIR}"
            ;;
        *.tar.gz|*.tgz)
            tar -xzf "${snapshot_file}" -C "${DATA_DIR}"
            ;;
        *.zip)
            unzip -o "${snapshot_file}" -d "${DATA_DIR}"
            ;;
        *)
            echo "Error: Unsupported archive format: ${snapshot_url}"
            rm -f "${snapshot_file}"
            return 1
            ;;
    esac

    # Cleanup
    rm -f "${snapshot_file}"

    echo "Snapshot bootstrap completed successfully"
}

# ============================================
# Graceful shutdown handler
# ============================================
shutdown_handler() {
    echo "Received shutdown signal, stopping maximusd..."
    /usr/local/bin/maximus-cli stop 2>/dev/null || true
    exit 0
}

trap shutdown_handler SIGTERM SIGINT SIGHUP

# ============================================
# Main execution
# ============================================
main() {
    echo "Starting Maximus Core..."

    # Wait for filesystem
    wait_ready

    # Bootstrap from snapshot if provided
    if [ -n "${SNAPSHOT_URL}" ]; then
        bootstrap_snapshot
    fi

    # Build command
    CMD="/usr/local/bin/maximusd"
    ARGS="${DAEMON_ARGS:-}"

    # Add provided arguments (e.g., -printtoconsole)
    if [ -n "$1" ]; then
        ARGS="${ARGS} $@"
    fi

    echo "Command: ${CMD} ${ARGS}"
    echo ""

    # Execute
    exec ${CMD} ${ARGS}
}

main "$@"