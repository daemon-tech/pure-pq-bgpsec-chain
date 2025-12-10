# Quick Start Guide

## Complete Workflow

### 1. Build oqs-provider (if not already built)

```bash
cd ../oqs-provider-bgpsec
# Follow build instructions in that repo's README
# This builds OpenSSL with oqs-provider supporting Falcon-512
```

### 2. Patch rpki-client

```bash
cd rpki-client-patch
# See README.md for instructions
# Clone rpki-client, apply patch, build and install
```

### 3. Build Certificate Chain

From the `oqs-provider-bgpsec` directory:

```bash
export OPENSSL_MODULES=/path/to/build/lib
./build-pq-bgpsec-chain.sh
```

This creates:
- `pq-bgpsec-ca/certs/ca-falcon.crt` - CA certificate
- `pq-bgpsec-ca/private/ca-falcon.key` - CA private key
- `pq-bgpsec-routers/router-*.crt` - Router certificates
- `pq-bgpsec-routers/router-*.key` - Router private keys

### 4. Copy Certificates to Clean Repo

```bash
cd ../pure-pq-bgpsec-chain
mkdir -p ca/certs ca/private routers
cp ../oqs-provider-bgpsec/pq-bgpsec-ca/certs/ca-falcon.crt ca/certs/
cp ../oqs-provider-bgpsec/pq-bgpsec-ca/private/ca-falcon.key ca/private/
cp ../oqs-provider-bgpsec/pq-bgpsec-routers/router*.crt routers/
cp ../oqs-provider-bgpsec/pq-bgpsec-routers/router*.key routers/
```

Or use the chain-builder script:
```bash
python3 chain-builder.py
```

### 5. Generate ROA

```bash
chmod +x generate-roa-openssl.sh
export OPENSSL_MODULES=/path/to/oqs-provider-bgpsec/build/lib
./generate-roa-openssl.sh
```

This creates `roas/192-0-2-0-24.roa` signed with the router certificate.

### 6. Validate ROA

```bash
chmod +x validate-with-rpkiclient.sh
./validate-with-rpkiclient.sh
```

Check `validation.log` for output showing the ROA validates.

## Expected Output

After running the validation script, `validation.log` should contain:

```
Route Origin Authorizations: 1 (0 failed parse, 0 invalid)
Certificates: 2 (0 invalid)
```

This proves the ROA validates successfully with the Falcon-512 certificate chain.

## Troubleshooting

### Provider Not Found
Set `OPENSSL_MODULES` to the directory containing `oqsprovider.so`:
```bash
export OPENSSL_MODULES=/path/to/oqs-provider-bgpsec/build/lib
```

### rpki-client Not Found
Install rpki-client and apply the patch (see `rpki-client-patch/README.md`)

### Certificates Not Found
Run `build-pq-bgpsec-chain.sh` first to generate the certificate chain.

## Author

Sam Moes  
December 2024

