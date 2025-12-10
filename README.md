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

## What It Proves

The "but the certificates" argument is now closed. Full chain validates end-to-end.

This demonstrates that:
1. Post-quantum certificates work in real RPKI infrastructure (with patched rpki-client)
2. Complete BGPsec certificate chains can be pure post-quantum
3. RPKI ROAs can be signed with post-quantum router certificates
4. The entire stack - CA → Router → ROA → Validation - works with Falcon-512

## Author

Sam Moes  
December 2024

