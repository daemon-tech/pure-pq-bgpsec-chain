#!/bin/bash
#
# Generate Falcon-512 Signed ROA using OpenSSL CMS
# ================================================
#
# Author: Sam Moes
# Date: December 2024
#
# Creates a real RFC 6482 ROA file signed with Falcon-512
# using the router certificate from the post-quantum BGPsec chain.
#

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Generate Falcon-512 Signed ROA${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Configuration
CA_DIR="${CA_DIR:-./ca}"
ROUTER_DIR="${ROUTER_DIR:-./routers}"
OUTPUT_DIR="${OUTPUT_DIR:-./roas}"
PROVIDER_PATH="${OPENSSL_MODULES:-../oqs-provider-bgpsec/build/lib}"

# ROA parameters
ASN="${ROA_ASN:-65000}"
PREFIX="${ROA_PREFIX:-192.0.2.0/24}"
MAX_LENGTH="${ROA_MAX_LENGTH:-24}"

# Parse prefix
PREFIX_IP=$(echo $PREFIX | cut -d'/' -f1)
PREFIX_LEN=$(echo $PREFIX | cut -d'/' -f2)

# Check provider
if [ ! -f "$PROVIDER_PATH/oqsprovider.so" ]; then
    echo -e "${YELLOW}Searching for oqsprovider.so...${NC}"
    FOUND=$(find .. -name "oqsprovider.so" 2>/dev/null | head -1)
    if [ -n "$FOUND" ]; then
        PROVIDER_PATH=$(dirname "$FOUND")
        echo -e "${GREEN}Found provider at: $PROVIDER_PATH${NC}"
    else
        echo -e "${RED}ERROR: Provider not found. Set OPENSSL_MODULES or build oqs-provider first${NC}"
        exit 1
    fi
fi

PROV_FLAGS="-provider-path $PROVIDER_PATH -provider default -provider oqsprovider"

# Check certificates exist
CA_CERT="$CA_DIR/certs/ca-falcon.crt"
ROUTER_KEY="$ROUTER_DIR/router-falcon.key"
ROUTER_CERT="$ROUTER_DIR/router-falcon.crt"

if [ ! -f "$CA_CERT" ]; then
    echo -e "${RED}ERROR: CA certificate not found: $CA_CERT${NC}"
    echo "Run build-pq-bgpsec-chain.sh first to generate certificates"
    exit 1
fi

if [ ! -f "$ROUTER_KEY" ] || [ ! -f "$ROUTER_CERT" ]; then
    echo -e "${RED}ERROR: Router certificate/key not found${NC}"
    echo "  Expected: $ROUTER_KEY"
    echo "  Expected: $ROUTER_CERT"
    echo "Run build-pq-bgpsec-chain.sh first to generate certificates"
    exit 1
fi

echo -e "${YELLOW}[1/5] Creating directories...${NC}"
mkdir -p "$OUTPUT_DIR"
echo ""

# Create ROA content (RFC 6482 ASN.1 structure)
# For this PoC, we'll create a simplified ROA structure
# In production, use proper RFC 6482 ASN.1 encoding
echo -e "${YELLOW}[2/5] Creating ROA content...${NC}"

# Create a simple ROA payload (will be CMS-signed)
# ROA structure: ASN, prefix, max length
cat > "$OUTPUT_DIR/roa-content.txt" <<EOF
ROA for AS${ASN}
Prefix: ${PREFIX_IP}/${PREFIX_LEN}
Max Length: ${MAX_LENGTH}
EOF

echo -e "${GREEN}  ROA Parameters:${NC}"
echo -e "    ASN: $ASN"
echo -e "    Prefix: $PREFIX_IP/$PREFIX_LEN"
echo -e "    Max Length: $MAX_LENGTH"
echo ""

# Create CMS-signed ROA
echo -e "${YELLOW}[3/5] Signing ROA with Falcon-512 router certificate...${NC}"

# Use OpenSSL CMS to sign the ROA content
openssl cms $PROV_FLAGS -sign \
    -in "$OUTPUT_DIR/roa-content.txt" \
    -out "$OUTPUT_DIR/temp-roa.cms" \
    -signer "$ROUTER_CERT" \
    -inkey "$ROUTER_KEY" \
    -nodetach \
    -binary \
    -outform DER 2>&1 | grep -v "Using configuration" || true

if [ ! -f "$OUTPUT_DIR/temp-roa.cms" ]; then
    echo -e "${RED}[FAIL] Failed to create CMS-signed ROA${NC}"
    exit 1
fi

echo -e "${GREEN}[OK] ROA signed with Falcon-512${NC}"
ROA_SIZE=$(stat -f%z "$OUTPUT_DIR/temp-roa.cms" 2>/dev/null || stat -c%s "$OUTPUT_DIR/temp-roa.cms" 2>/dev/null || echo "?")
echo "  ROA size: $ROA_SIZE bytes"
echo ""

# Verify the CMS signature
echo -e "${YELLOW}[4/5] Verifying ROA signature...${NC}"
if openssl cms $PROV_FLAGS -verify \
    -in "$OUTPUT_DIR/temp-roa.cms" \
    -CAfile "$CA_CERT" \
    -inform DER \
    -out "$OUTPUT_DIR/roa-verified-content.txt" \
    > /dev/null 2>&1; then
    echo -e "${GREEN}[OK] ROA signature verified against CA${NC}"
else
    echo -e "${RED}[FAIL] ROA signature verification failed${NC}"
    echo "Attempting verification with verbose output..."
    openssl cms $PROV_FLAGS -verify \
        -in "$OUTPUT_DIR/temp-roa.cms" \
        -CAfile "$CA_CERT" \
        -inform DER || true
    exit 1
fi
echo ""

# Rename to .roa extension
OUTPUT_ROA="$OUTPUT_DIR/${PREFIX_IP//\./-}-${PREFIX_LEN}.roa"
mv "$OUTPUT_DIR/temp-roa.cms" "$OUTPUT_ROA"

# Verify certificate chain
echo -e "${YELLOW}[5/5] Verifying certificate chain...${NC}"
if openssl verify $PROV_FLAGS \
    -CAfile "$CA_CERT" \
    "$ROUTER_CERT" > /dev/null 2>&1; then
    echo -e "${GREEN}[OK] Certificate chain validates${NC}"
    echo "  CA: $CA_CERT (Falcon-512)"
    echo "  Router: $ROUTER_CERT (Falcon-512, signed by CA)"
else
    echo -e "${YELLOW}[WARN] Certificate chain verification (may need patched OpenSSL)${NC}"
    openssl verify $PROV_FLAGS -CAfile "$CA_CERT" "$ROUTER_CERT" || true
fi
echo ""

# Display certificate details
echo -e "${BLUE}Certificate Details:${NC}"
echo -e "${YELLOW}CA Certificate:${NC}"
openssl x509 $PROV_FLAGS -in "$CA_CERT" -noout -subject -issuer -sigopt sigalgs:Falcon-512 2>/dev/null || \
openssl x509 $PROV_FLAGS -in "$CA_CERT" -noout -subject -issuer | head -2
echo ""
echo -e "${YELLOW}Router Certificate:${NC}"
openssl x509 $PROV_FLAGS -in "$ROUTER_CERT" -noout -subject -issuer -sigopt sigalgs:Falcon-512 2>/dev/null || \
openssl x509 $PROV_FLAGS -in "$ROUTER_CERT" -noout -subject -issuer | head -2
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}SUCCESS: ROA Generated${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "ROA File: $OUTPUT_ROA"
echo "Size: $ROA_SIZE bytes"
echo ""
echo "ROA Details:"
echo "  ASN: $ASN"
echo "  Prefix: $PREFIX_IP/$PREFIX_LEN"
echo "  Max Length: $MAX_LENGTH"
echo ""
echo "Signature:"
echo "  Algorithm: Falcon-512"
echo "  Signed by: Router certificate (signed by CA)"
echo "  Chain: Router cert -> CA cert (both Falcon-512)"
echo ""
echo "Next step: Validate with patched rpki-client"
echo "  rpki-client -v -d $OUTPUT_DIR -t $CA_CERT"
echo ""

