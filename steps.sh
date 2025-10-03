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

line(){ printf '%*s\n' "$COLUMNS" '' | tr ' ' '-' }

# ip_forward=1
echo "[INFO] enabling host ip_forward ..."
line
sudo sysctl -w net.ipv4.ip_forward=1
line

# networks
echo "[INFO] creating podman network n0 ..."
line
podman network create --subnet 10.89.0.0/24 n0
line

# r0
echo "[INFO] creating podman pod router r0 ..."
line
podman kube play --network n0 r0.yaml
sleep 7
line

echo "[INFO] configuring router r0 network ..."
line
podman cp ./network_r0 r0-r0:/etc/config/network
podman exec r0-r0 /etc/init.d/network restart
sleep 7
podman exec r0-r0 ip -o addr show | awk '{print $2,$4}'
line

echo "[INFO] configuring router r0 firewall ..."
line
podman cp ./firewall_r0 r0-r0:/etc/config/firewall
podman exec r0-r0 /etc/init.d/firewall restart
sleep 7
podman exec r0-r0 uci show firewall | grep network
podman exec r0-r0 uci show firewall | grep Allow-
line

# r1
echo "[INFO] creating podman pod router r1 ..."
line
podman kube play --network n0 r1.yaml
sleep 7
line

echo "[INFO] configuring router r1 network ..."
line
podman cp ./network_r1 r1-r1:/etc/config/network
podman exec r1-r1 /etc/init.d/network restart
sleep 7
podman exec r1-r1 ip -o addr show | awk '{print $2,$4}'
line

echo "[INFO] configuring router r1 firewall ..."
line
podman cp ./firewall_r1 r1-r1:/etc/config/firewall
podman exec r1-r1 /etc/init.d/firewall restart
sleep 7
podman exec r1-r1 uci show firewall | grep network
podman exec r0-r0 uci show firewall | grep Allow-
line

# test
echo "[INFO] router r0 pinging router r1 ..."
line
podman exec r0-r0 ping -c3 10.89.0.3
line

echo "[INFO] router r1 pinging router r0 ..."
line
podman exec r1-r1 ping -c3 10.89.0.2
line

# cleanup
echo "[INFO] cleaning ..."
line
podman kube down r0.yaml
podman kube down r1.yaml

podman network remove n0

sudo sysctl -w net.ipv4.ip_forward=0
line
