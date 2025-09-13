sudo sysctl -w net.ipv4.ip_forward=1

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

# networks
podman network create --subnet 10.89.0.0/24 n0

# r0
podman kube play --network n0 r0.yaml

podman cp ./network_r0 r0-r0:/etc/config/network
podman exec r0-r0 /etc/init.d/network restart
podman exec r0-r0 ip -o addr show | awk '{print $2,$4}'

podman cp ./firewall_r0 r0-r0:/etc/config/firewall
podman exec r0-r0 /etc/init.d/firewall restart
podman exec r0-r0 uci show firewall | grep network

# r1
podman kube play --network n0 r1.yaml

podman cp ./network_r1 r1-r1:/etc/config/network
podman exec r1-r1 /etc/init.d/network restart
podman exec r1-r1 ip -o addr show | awk '{print $2,$4}'

podman cp ./firewall_r1 r1-r1:/etc/config/firewall
podman exec r1-r1 /etc/init.d/firewall restart
podman exec r1-r1 uci show firewall | grep network

# test
podman exec r0-r0 ping -c3 10.80.0.3
podman exec r1-r1 ping -c3 10.80.0.2

# cleanup
podman kube down r0.yaml
podman kube down r1.yaml

podman network remove n0
