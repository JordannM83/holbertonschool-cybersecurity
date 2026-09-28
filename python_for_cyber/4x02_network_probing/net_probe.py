#!/usr/bin/env python3
import socket


def check_port(ip: str, port: int) -> bool:
    """Establish a simple TCP connection"""
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

    sock.settimeout(1.0)

    try:
        sock.connect((ip, port))
        sock.sendall(b"Hello!")
        response = sock.recv(1024)
        print(response.decode())

    except TimeoutError:
        print("Operation timed out")
        return False

    except ConnectionRefusedError:
        print("Connection refused")
        return False

    finally:
        sock.close()
        return True


def main():
    """main function"""
    print(f"Port 80 is open: {check_port('google.com', 80)}")
    print(f"Port 81 is open: {check_port('google.com', 81)}")
    return
