#!/bin/sh

printf "IP? (10.8.0.254): "
read SERVER_IP
SERVER_IP=${SERVER_IP:-10.8.0.254}

printf "PORT? (51820): "
read SERVER_PORT
SERVER_PORT=${SERVER_PORT:-51820}

printf "DIR? (./): "
read WG_DIR
WG_DIR=${WG_DIR:-$(pwd)}

printf "FILE? (wg0.conf): "
read WG_CONF
WG_CONF=${WG_CONF:-wg0.conf}

printf "ETH? (eth0): "
read ETH_IF
ETH_IF=${ETH_IF:-eth0}

mkdir -p "$WG_DIR"
cd "$WG_DIR" || exit 1

SERVER_PRIV=$(wg genkey)
SERVER_PUB=$(echo "$SERVER_PRIV" | wg pubkey)

echo "[+] .env"

cat > .env <<EOF
SERVER_ENDPOINT=$(curl -4 -s ifconfig.me)
SERVER_IP="$SERVER_IP"
SERVER_PORT="$SERVER_PORT"
SERVER_DIR="$WG_DIR"
SERVER_CONF="$WG_CONF"
SERVER_INTERFACE="$ETH_IF"
SERVER_PUBLIC_KEY="$SERVER_PUB"
SERVER_PRIVATE_KEY="$SERVER_PRIV"
EOF

echo "[+] CONF"

cat > "$WG_CONF" <<EOF
[Interface]
Address = ${SERVER_IP}/24
ListenPort = ${SERVER_PORT}
PrivateKey = $SERVER_PRIV
# PublicKey = $SERVER_PUB

PostUp = iptables -A INPUT -p udp --dport ${SERVER_PORT} -j ACCEPT
PostUp = iptables -t nat -A POSTROUTING -s ${SERVER_IP%.*}.0/24 -o ${ETH_IF} -j MASQUERADE

PostDown = iptables -D INPUT -p udp --dport ${SERVER_PORT} -j ACCEPT
PostDown = iptables -t nat -D POSTROUTING -s ${SERVER_IP%.*}.0/24 -o ${ETH_IF} -j MASQUERADE

SaveConfig = true
#0
EOF

echo
echo "[INFO]"
echo "  IP:"
echo "$SERVER_IP"
echo "  PORT:"
echo "$SERVER_PORT"
echo "  DIR:"
echo "$WG_DIR"
echo "  FILE:"
echo "$WG_CONF"
echo "  ETH:"
echo "$ETH_IF"
echo "  PUB:"
echo "$SERVER_PUB"
echo "  PRIVATE:"
echo "$SERVER_PRIV"
echo

echo
echo READY
echo
