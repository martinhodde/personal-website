#!/usr/bin/env bash
# One-time script to get a Spotify refresh token for update-shelf.sh.
# Run this once; it writes ~/.spotify_credentials with the refresh token.
#
# Prerequisites:
#   1. Create an app at https://developer.spotify.com/dashboard
#   2. Add http://localhost:8888/callback as a Redirect URI in the app settings
#   3. Copy the Client ID and Client Secret from the app dashboard

set -euo pipefail

read -rp "Client ID: " CLIENT_ID
read -rsp "Client Secret: " CLIENT_SECRET
echo

REDIRECT_URI="http://127.0.0.1:8888/callback"
SCOPE="user-top-read"

AUTH_URL="https://accounts.spotify.com/authorize?response_type=code&client_id=${CLIENT_ID}&scope=${SCOPE}&redirect_uri=${REDIRECT_URI}"

echo ""
echo "Open this URL in your browser and authorize the app:"
echo ""
echo "  $AUTH_URL"
echo ""
echo "After clicking Agree, the browser will fail to load (connection refused) —"
echo "that's fine. Copy the full URL from the address bar, which will look like:"
echo "  http://127.0.0.1:8888/callback?code=AQD..."
read -rp "Paste the full redirect URL here: " REDIRECT_RESPONSE

CODE=$(echo "$REDIRECT_RESPONSE" | sed 's/.*code=\([^&]*\).*/\1/')

if [ -z "$CODE" ]; then
  echo "Error: could not extract code from URL"
  exit 1
fi

TOKEN_RESPONSE=$(curl -sf -X POST "https://accounts.spotify.com/api/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=authorization_code&code=${CODE}&redirect_uri=${REDIRECT_URI}&client_id=${CLIENT_ID}&client_secret=${CLIENT_SECRET}")

REFRESH_TOKEN=$(echo "$TOKEN_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['refresh_token'])")

if [ -z "$REFRESH_TOKEN" ]; then
  echo "Error: failed to get refresh token"
  echo "Response: $TOKEN_RESPONSE"
  exit 1
fi

CREDS_FILE="${HOME}/.spotify_credentials"
cat > "$CREDS_FILE" <<EOF
SPOTIFY_CLIENT_ID=${CLIENT_ID}
SPOTIFY_CLIENT_SECRET=${CLIENT_SECRET}
SPOTIFY_REFRESH_TOKEN=${REFRESH_TOKEN}
EOF
chmod 600 "$CREDS_FILE"

echo ""
echo "Saved credentials to ${CREDS_FILE}"
echo "Run update-shelf.sh to populate the Spotify card."
