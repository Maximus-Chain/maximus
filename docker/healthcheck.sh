#!/bin/bash
# ============================================
# Maximus Core - Docker Healthcheck Script
# ============================================

# Determine RPC port based on network
case "${NETWORK:-mainnet}" in
    mainnet)
        PORT=9938
        ;;
    testnet)
        PORT=19938
        ;;
    regtest)
        PORT=19838
        ;;
    *)
        PORT=9938
        ;;
esac

# Check if port is listening
nc -z localhost $PORT
exit $?