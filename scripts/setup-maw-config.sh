#!/usr/bin/env bash
# Create ~/.config/maw/maw.config.json for Tham Oracle.
# Generates a federationToken but does NOT commit it.
# peers: [] always (prevents session duplication bug maw-js#175)

CONFIG_DIR="$HOME/.config/maw"
CONFIG_FILE="$CONFIG_DIR/maw.config.json"
FLEET_DIR="$CONFIG_DIR/fleet"

mkdir -p "$CONFIG_DIR" "$FLEET_DIR"

# Check if config already exists
if [ -f "$CONFIG_FILE" ]; then
  echo "Config already exists: $CONFIG_FILE"
  echo "Delete it first if you want to regenerate."
  cat "$CONFIG_FILE"
  exit 0
fi

# Generate token — not committed, stored locally only
TOKEN=$(openssl rand -base64 32)

cat > "$CONFIG_FILE" << EOF
{
  "host": "local",
  "bind": "0.0.0.0",
  "port": 3457,
  "node": "tham-node",
  "federationToken": "${TOKEN}",
  "peers": [],
  "namedPeers": [],
  "agents": {
    "tham":   "tham-node",
    "omega":  "tham-node",
    "core":   "tham-node",
    "bob":    "tham-node",
    "hermes": "tham-node"
  }
}
EOF

# Fleet config: tham (window 0)
cat > "$FLEET_DIR/01-tham.json" << 'EOF'
{
  "name": "tham",
  "windows": [
    {"name": "tham", "repo": "E0993599799/tham-oracle"}
  ]
}
EOF

# Fleet config: omega/core (window 1)
cat > "$FLEET_DIR/02-omega.json" << 'EOF'
{
  "name": "omega",
  "windows": [
    {"name": "core", "repo": "E0993599799/Omega"}
  ]
}
EOF

# Fleet config: bob coordinator (window 2)
cat > "$FLEET_DIR/03-bob.json" << 'EOF'
{
  "name": "bob",
  "windows": [
    {"name": "bob", "repo": "E0993599799/tham-oracle"}
  ]
}
EOF

# Fleet config: hermes specialist (window 3)
cat > "$FLEET_DIR/04-hermes.json" << 'EOF'
{
  "name": "hermes",
  "windows": [
    {"name": "hermes", "repo": "E0993599799/tham-oracle"}
  ]
}
EOF

echo "✓ Config created: $CONFIG_FILE"
echo "✓ Fleet configs:"
echo "   $FLEET_DIR/01-tham.json"
echo "   $FLEET_DIR/02-omega.json"
echo "   $FLEET_DIR/03-bob.json"
echo "   $FLEET_DIR/04-hermes.json"
echo ""
echo "⚠ federationToken is stored locally only — do NOT commit $CONFIG_FILE"
echo ""
echo "Next: maw --version && maw fleet ls"
