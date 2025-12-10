# Pure Post-Quantum BGPsec Chain

**First complete pure Falcon-512 BGPsec + RPKI chain - December 2024**

## What This Is

This repository contains proof that complete post-quantum secure BGPsec certificate chains and RPKI ROAs are technically ready for production deployment right now.

The implementation provides:
- **CA certificate** using pure Falcon-512
- **Router certificates** signed by the CA with Falcon-512  
- **RPKI ROA** signed with router certificate using Falcon-512
- **Full chain validation** end-to-end with rpki-client

**Zero classical cryptography** - no RSA, no ECDSA, no hybrid fallback.

## Quick Start

### Prerequisites

1. Build oqs-provider (see `../oqs-provider-bgpsec/README.md`)
2. Patch and build rpki-client (see `rpki-client-patch/README.md`)

### Step 1: Build Certificate Chain

```bash
# From oqs-provider-bgpsec directory
./build-pq-bgpsec-chain.sh

# Or use the chain builder script
cd pure-pq-bgpsec-chain
python3 chain-builder.py
```

### Step 2: Generate ROA

```bash
cd pure-pq-bgpsec-chain
chmod +x generate-roa-openssl.sh
./generate-roa-openssl.sh
```

This creates a ROA signed with the Falcon-512 router certificate.

### Step 3: Validate with rpki-client

```bash
chmod +x validate-with-rpkiclient.sh
./validate-with-rpkiclient.sh
```

Check `validation.log` for the validation output.

## What It Proves

The "but the certificates" argument is now closed. Full chain validates end-to-end.

This demonstrates that:
1. Post-quantum certificates work in real RPKI infrastructure (with patched rpki-client)
2. Complete BGPsec certificate chains can be pure post-quantum
3. RPKI ROAs can be signed with post-quantum router certificates
4. The entire stack - CA → Router → ROA → Validation - works with Falcon-512

## Validation Results

See `validation.log` for rpki-client output showing the ROA validates successfully with the Falcon-512 certificate chain.

## Repository Structure

```
pure-pq-bgpsec-chain/
├── ca/                      # CA certificate and key
├── routers/                 # Router certificates
├── roas/                    # ROA files signed with router certs
├── rpki-client-patch/       # Patch for rpki-client Falcon-512 support
├── validation.log           # rpki-client validation output
├── chain-builder.py         # Script to build certificate chain
└── README.md                # This file
```

## Next Steps

Tomorrow: Generate real RFC 8205 BGPsec UPDATE messages using these certificates with full Secure_Path attribute.

## Author

Sam Moes  
December 2024

