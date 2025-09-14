# ---
# /etc/config/network
# ---
# router	interface	device		ip
# ---
# r0		net0		eth0		10.89.0.2/24
# r1		net0		eth0		10.89.0.3/24
# ---

# ---
# /etc/config/firewall
# ---
# router	zone		interface	rules
# ---
# r0 		zone0		net0		Allow-Ping-Request-Out
# 						Allow-Ping-Reply-In
# 						Allow-Ping-Request-In
# 						Allow-Ping-Reply-Out
# r1 		zone0		net0		Allow-Ping-Request-Out
# 						Allow-Ping-Reply-In
# 						Allow-Ping-Request-In
# 						Allow-Ping-Reply-Out
# ---

# ip_forward=1
printf '%*s\n' "$COLUMNS" '' | tr ' ' '#'
printf '%*s\n' "$COLUMNS" '' | tr ' ' '#'
echo "[INFO] enabling host ip_forward ..."
printf '%*s\n' "$COLUMNS" '' | tr ' ' '#'
sudo sysctl -w net.ipv4.ip_forward=1
printf '%*s\n' "$COLUMNS" '' | tr ' ' '#'

# networks
echo "[INFO] creating podman network n0 ..."
printf '%*s\n' "$COLUMNS" '' | tr ' ' '#'
podman network create --subnet 10.89.0.0/24 n0
printf '%*s\n' "$COLUMNS" '' | tr ' ' '#'

# r0
echo "[INFO] creating podman pod router r0 ..."
printf '%*s\n' "$COLUMNS" '' | tr ' ' '#'
podman kube play --network n0 r0.yaml
sleep 7
printf '%*s\n' "$COLUMNS" '' | tr ' ' '#'

echo "[INFO] configuring router r0 network ..."
printf '%*s\n' "$COLUMNS" '' | tr ' ' '#'
podman cp ./network_r0 r0-r0:/etc/config/network
podman exec r0-r0 /etc/init.d/network restart
sleep 7
podman exec r0-r0 ip -o addr show | awk '{print $2,$4}'
printf '%*s\n' "$COLUMNS" '' | tr ' ' '#'

echo "[INFO] configuring router r0 firewall ..."
printf '%*s\n' "$COLUMNS" '' | tr ' ' '#'
podman cp ./firewall_r0 r0-r0:/etc/config/firewall
podman exec r0-r0 /etc/init.d/firewall restart
sleep 7
podman exec r0-r0 uci show firewall | grep network
podman exec r0-r0 uci show firewall | grep Allow-
printf '%*s\n' "$COLUMNS" '' | tr ' ' '#'

# r1
echo "[INFO] creating podman pod router r1 ..."
printf '%*s\n' "$COLUMNS" '' | tr ' ' '#'
podman kube play --network n0 r1.yaml
sleep 7
printf '%*s\n' "$COLUMNS" '' | tr ' ' '#'

echo "[INFO] configuring router r1 network ..."
printf '%*s\n' "$COLUMNS" '' | tr ' ' '#'
podman cp ./network_r1 r1-r1:/etc/config/network
podman exec r1-r1 /etc/init.d/network restart
sleep 7
podman exec r1-r1 ip -o addr show | awk '{print $2,$4}'
printf '%*s\n' "$COLUMNS" '' | tr ' ' '#'

echo "[INFO] configuring router r1 firewall ..."
printf '%*s\n' "$COLUMNS" '' | tr ' ' '#'
podman cp ./firewall_r1 r1-r1:/etc/config/firewall
podman exec r1-r1 /etc/init.d/firewall restart
sleep 7
podman exec r1-r1 uci show firewall | grep network
podman exec r0-r0 uci show firewall | grep Allow-
printf '%*s\n' "$COLUMNS" '' | tr ' ' '#'

# test
echo "[INFO] router r0 pinging router r1 ..."
printf '%*s\n' "$COLUMNS" '' | tr ' ' '#'
podman exec r0-r0 ping -c3 10.89.0.3
printf '%*s\n' "$COLUMNS" '' | tr ' ' '#'

echo "[INFO] router r1 pinging router r0 ..."
printf '%*s\n' "$COLUMNS" '' | tr ' ' '#'
podman exec r1-r1 ping -c3 10.89.0.2
printf '%*s\n' "$COLUMNS" '' | tr ' ' '#'

# cleanup
echo "[INFO] cleaning ..."
printf '%*s\n' "$COLUMNS" '' | tr ' ' '#'
podman kube down r0.yaml
podman kube down r1.yaml

podman network remove n0

sudo sysctl -w net.ipv4.ip_forward=0
printf '%*s\n' "$COLUMNS" '' | tr ' ' '#'
