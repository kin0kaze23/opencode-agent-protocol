#!/bin/bash
# DEPRECATED — This is a thin wrapper for backward compatibility.
# Canonical script: sync-opencode-runtime.sh
# This wrapper will be removed in a future cleanup phase.
exec bash "$(dirname "$0")/sync-opencode-runtime.sh" "$@"
