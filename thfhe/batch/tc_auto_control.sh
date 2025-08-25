#!/bin/bash

# auto get first non-lo net device (remove @ suffix)
NETIF=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | cut -d@ -f1 | head -n 1)

if [ -z "$NETIF" ]; then
    echo "can't find lo net device, exit"
    exit 1
fi

echo "detected target net device: $NETIF"

# clean old configuration
reset_tc() {
    echo "clean $NETIF tc configuration..."
    sudo tc qdisc del dev "$NETIF" root 2>/dev/null || true
    echo "clean old configuration done"
}

# set the delay + bandwidth
set_tc() {
    local delay=$1
    local rate=$2
    reset_tc
    echo "set delay $delay and bandwidth $rate to $NETIF..."
    sudo tc qdisc add dev "$NETIF" root handle 1: htb default 10
    sudo tc class add dev "$NETIF" parent 1: classid 1:10 htb rate "$rate"
    sudo tc qdisc add dev "$NETIF" parent 1:10 handle 10: netem delay "$delay"
    echo "set done: $NETIF ← delay=$delay, rate=$rate"
}

# show current configuration
show_tc() {
    echo "current tc configuration:"
    sudo tc qdisc show dev "$NETIF"
}

# ===============================
# main:
# ===============================

# external parameter commands
if [ "$1" == "--reset" ]; then
    reset_tc
    exit 0
fi

if [ "$1" == "--show" ]; then
    show_tc
    exit 0
fi

if [ $# -eq 2 ]; then
    set_tc "$1" "$2"
    exit 0
fi

# ===============================
# if no input parameters
# ===============================

echo "please choose which network limit option to apply:"
echo "1. delay 1ms, bandwidth 1Gbit/s"
echo "2. delay 100ms, bandwidth 100Mbit/s"
echo "3. delay 0.1ms, bandwidth 10Gbit/s"
echo "4. delay 0.1ms, bandwidth 1Gbit/s"
echo "5. reset configuration"
echo "6. show current configuration"
read -p "please enter your choice (1-6): " choice

case "$choice" in
    1) set_tc "1ms" "1gbit" ;;
    2) set_tc "100ms" "100mbit" ;;
    3) set_tc "0.1ms" "10gbit" ;;
    4) set_tc "0.1ms" "1gbit" ;;
    5) reset_tc ;;
    6) show_tc ;;
    *) echo "invalid option, exit." ;;
esac
