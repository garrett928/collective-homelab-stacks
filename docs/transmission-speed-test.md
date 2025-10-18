# Transmission Pod Internet Speed Test Guide

This guide shows how to test the internet speed of your Transmission pod running through the Gluetun VPN sidecar.

## Prerequisites

- Transmission pod running in the `media` namespace
- The pod should have `curl` and `bc` utilities available

## Quick Speed Test

### Get the Transmission Pod Name

```bash
kubectl get pods -n media | grep transmission
```

### Check VPN IP Address

Verify that traffic is going through the VPN:

```bash
kubectl exec -n media <transmission-pod-name> -c transmission -- curl -s https://ipinfo.io/json
```

This should show your VPN provider's IP address, not your home IP.

### Run Download Speed Test

#### Simple Speed Test (10MB file, ~15 seconds)

```bash
kubectl exec -n media <transmission-pod-name> -c transmission -- sh -c '
echo "=== Transmission Pod Internet Speed Test ==="
echo ""
echo "Testing download speed..."
SPEED=$(curl -o /dev/null -s -w "%{speed_download}" http://speedtest.tele2.net/10MB.zip --max-time 15)
echo "Raw speed: $SPEED bytes/sec"
echo "Speed in Mbps: $(echo "scale=2; $SPEED * 8 / 1000000" | bc -l)"
echo ""
'
```

#### Larger Speed Test (100MB file, ~30 seconds)

For more accurate results with faster connections:

```bash
kubectl exec -n media <transmission-pod-name> -c transmission -- sh -c '
echo "=== Transmission Pod Internet Speed Test (100MB) ==="
echo ""
echo "Testing download speed..."
SPEED=$(curl -o /dev/null -s -w "%{speed_download}" http://speedtest.tele2.net/100MB.zip --max-time 30)
echo "Raw speed: $SPEED bytes/sec"
echo "Speed in Mbps: $(echo "scale=2; $SPEED * 8 / 1000000" | bc -l)"
echo ""
'
```

## Comprehensive Speed Test Script

This script tests both download speed and provides detailed connection information:

```bash
kubectl exec -n media <transmission-pod-name> -c transmission -- sh -c '
echo "=========================================="
echo "  Transmission Pod Speed Test"
echo "=========================================="
echo ""

echo "--- VPN Connection Info ---"
curl -s https://ipinfo.io/json | grep -E "ip|city|region|country|org" | sed "s/\"//g"
echo ""

echo "--- Download Speed Test (10MB) ---"
SPEED=$(curl -o /dev/null -s -w "%{speed_download}" http://speedtest.tele2.net/10MB.zip --max-time 15)
MBPS=$(echo "scale=2; $SPEED * 8 / 1000000" | bc -l)
MBYTES=$(echo "scale=2; $SPEED / 1000000" | bc -l)

echo "Download Speed:"
echo "  - $SPEED bytes/sec"
echo "  - $MBYTES MB/sec"
echo "  - $MBPS Mbps"
echo ""
echo "=========================================="
'
```

## Current Pod Name (as of October 17, 2025)

Your current Transmission pod name is:
```
transmission-84fb48c844-4gr98
```

So you can run:

```bash
kubectl exec -n media transmission-84fb48c844-4gr98 -c transmission -- sh -c '
echo "=== Transmission Pod Internet Speed Test ==="
echo ""
echo "Testing download speed..."
SPEED=$(curl -o /dev/null -s -w "%{speed_download}" http://speedtest.tele2.net/10MB.zip --max-time 15)
echo "Raw speed: $SPEED bytes/sec"
echo "Speed in Mbps: $(echo "scale=2; $SPEED * 8 / 1000000" | bc -l)"
echo ""
'
```

## Alternative Test Files

You can use different test file sizes depending on your connection speed:

- **1MB**: `http://speedtest.tele2.net/1MB.zip` (good for slow connections)
- **10MB**: `http://speedtest.tele2.net/10MB.zip` (recommended default)
- **100MB**: `http://speedtest.tele2.net/100MB.zip` (for fast connections)
- **1GB**: `http://speedtest.tele2.net/1GB.zip` (for very fast connections, increase `--max-time`)

## Notes

- The speed test downloads a file to `/dev/null` (discards it), so it doesn't consume disk space
- The `--max-time` parameter prevents the test from running too long
- Results are shown in bytes/sec and Mbps (megabits per second)
- The test goes through your VPN connection, so speeds may be limited by your VPN provider
- Exit code 28 from curl means the operation timed out (reached max-time), which is expected

## Troubleshooting

### DNS Issues

If you get DNS resolution errors, check that the Gluetun VPN is running properly:

```bash
kubectl logs -n media <transmission-pod-name> -c gluetun --tail=50
```

### Slow Speeds

VPN speeds can be affected by:
- VPN server location (choose closer servers)
- VPN server load (try different servers)
- Time of day
- Your ISP's routing to the VPN provider

### Container Not Found

If the pod name has changed (after a restart), get the new name:

```bash
kubectl get pods -n media -l app=transmission
```
