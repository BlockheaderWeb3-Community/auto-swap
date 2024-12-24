#!/bin/bash

# Build the project
scarb build || exit 1

# Substitute RPC_URL
sed -i "s|\$RPC_URL|$RPC_URL|g" Scarb.toml

# Run tests
snforge test || exit 1

# Restore Scarb.toml
git checkout Scarb.toml

echo "Local test completed successfully!"
