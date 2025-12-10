# rpki-client Falcon-512 OID Patch

This patch adds support for Falcon-512 signature algorithm (OID `1.3.9999.3.1`) to rpki-client.

## How to Apply

1. Download or clone rpki-client source:
   ```bash
   git clone https://github.com/rpki-client/rpki-client.git
   cd rpki-client
   ```

2. Apply the patch:
   ```bash
   patch -p1 < path/to/falcon512-oid.patch
   ```

3. Build rpki-client as normal:
   ```bash
   ./configure
   make
   sudo make install
   ```

## What This Patch Does

- Adds `OID_FALCON512_SIG` constant for OID `1.3.9999.3.1`
- Modifies `valid_signature_algorithm()` to accept Falcon-512 signatures
- Allows rpki-client to validate certificates and ROAs signed with Falcon-512

## Note on OID

The patch uses OID `1.3.9999.3.1` for Falcon-512. This is the draft OID. The final standardized OID may differ when NIST/IETF finalizes the standard.

## Verification

After patching and building, rpki-client should accept and validate ROAs signed with Falcon-512 certificates:

```bash
rpki-client -v -d /path/to/roas -t /path/to/falcon-ca.crt
```

## Author

Sam Moes  
December 2024

