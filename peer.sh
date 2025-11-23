#!/bin/sh

if [ ! -f .env ]; then
  echo "[ERROR] NEED START!!!!!!!!!!!!"
  exit 1
fi

. .env

WG_CONF_PATH="$SERVER_DIR/$SERVER_CONF"
CLIENT_DIR="$SERVER_DIR/clients"

mkdir -p "$CLIENT_DIR"

CLIENT_NAME=${CLIENT_NAME:-client}

BASE_NAME="$CLIENT_NAME"

LAST_NUM=$(grep -E "^#([0-9]+)$" "$WG_CONF_PATH" | sed 's/#//g' | sort -n | tail -1)

if [ -z "$LAST_NUM" ]; then
    LAST_NUM=0
fi

NEXT_NUM=$((LAST_NUM + 1))

echo "[+] LAST: #$LAST_NUM"
echo "[+] NEW:   #$NEXT_NUM"

BASE_NET="${SERVER_IP%.*}"
CLIENT_IP="${BASE_NET}.${NEXT_NUM}"

echo "[+] IP: $CLIENT_IP"

CLIENT_PRIV=$(wg genkey)
CLIENT_PUB=$(echo "$CLIENT_PRIV" | wg pubkey)

echo "[+] .env"

echo "CLIENT_PUBLIC_${NEXT_NUM}=\"$CLIENT_PUB\"" >> .env
echo "CLIENT_PRIVATE_${NEXT_NUM}=\"$CLIENT_PRIV\"" >> .env

printf "ALLOWED_IPS? (0.0.0.0/0): "
read ALLOWED_IPS
ALLOWED_IPS=${ALLOWED_IPS:-0.0.0.0/0}

cat >> "$WG_CONF_PATH" <<EOF

#${NEXT_NUM}
[Peer]
PublicKey = $CLIENT_PUB
AllowedIPs = ${CLIENT_IP}/32
#${NEXT_NUM}
EOF

CLIENT_FILE="${CLIENT_DIR}/${BASE_NAME}-${NEXT_NUM}.conf"

echo "[+] FILE: $CLIENT_FILE"

cat > "$CLIENT_FILE" <<EOF
# Client $BASE_NAME (#${NEXT_NUM})

[Interface]
PrivateKey = $CLIENT_PRIV
#PublicKey = $CLIENT_PUB
Address = ${CLIENT_IP}/32
DNS = 1.1.1.1

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = ${SERVER_ENDPOINT}:${SERVER_PORT}
AllowedIPs = $ALLOWED_IPS
PersistentKeepalive = 25
EOF

echo
echo "[INFO]"
echo "FILE: $CLIENT_FILE"
echo "NUM:  $NEXT_NUM"
echo "IP:   $CLIENT_IP"
echo "PUB:  $CLIENT_PUB"
echo
