import socket
import subprocess
import sys
from pathlib import Path

def get_local_ip():
    """return local private IP address"""
    hostname = socket.gethostname()
    ips = socket.gethostbyname_ex(hostname)[2]
    for ip in ips:
        if ip.startswith("192.") or ip.startswith("10.") or ip.startswith("172."):
            return ip
    raise RuntimeError("can't find local IP")

def read_ip_list(path):
    """read IP list file"""
    with open(path, 'r') as f:
        return [line.strip() for line in f if line.strip()]

def main():
    if len(sys.argv) != 2:
        print(f"usage: python {sys.argv[0]} <num_parties>")
        sys.exit(1)

    num_parties = sys.argv[1]
    ip_file = Path("./iplist/ip.txt")
    if not ip_file.exists():
        print(f"error: {ip_file} does not exist")
        sys.exit(1)

    local_ip = get_local_ip()
    ip_list = read_ip_list(ip_file)

    try:
        party_id = ip_list.index(local_ip)
    except ValueError:
        print(f"error: local IP ({local_ip}) not found in ip.txt")
        sys.exit(1)

    print(f"My IP: {local_ip}")
    print(f"My party_id: {party_id}")
    print(f"run: ./target/release/examples/thfhe -n {num_parties} -i {party_id}")

    # execute command
    try:
        subprocess.run(
            ["./target/release/examples/thfhe", "-n", num_parties, "-i", str(party_id)],
            check=True
        )
    except subprocess.CalledProcessError as e:
        print("command failed:", e)

if __name__ == "__main__":
    main()
