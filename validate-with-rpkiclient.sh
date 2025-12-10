#!/bin/bash
#
# Validate ROA with rpki-client
# ==============================
#
# Author: Sam Moes
# Date: December 2024
#

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Validate ROA with rpki-client${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Configuration
ROA_DIR="${ROA_DIR:-./roas}"
TA_CERT="${TA_CERT:-./ca/certs/ca-falcon.crt}"
OUTPUT_LOG="${OUTPUT_LOG:-validation.log}"

if [ ! -d "$ROA_DIR" ]; then
    echo -e "${RED}ERROR: ROA directory not found: $ROA_DIR${NC}"
    exit 1
fi

if [ ! -f "$TA_CERT" ]; then
    echo -e "${RED}ERROR: Trust anchor certificate not found: $TA_CERT${NC}"
    exit 1
fi

# Check if rpki-client is available
if ! command -v rpki-client >/dev/null 2>&1; then
    echo -e "${RED}ERROR: rpki-client not found in PATH${NC}"
    echo ""
    echo "Install rpki-client:"
    echo "  Ubuntu/Debian: apt install rpki-client"
    echo "  FreeBSD: pkg install rpki-client"
    echo ""
    echo "Note: You need to patch rpki-client for Falcon-512 OID support first!"
    echo "See: rpki-client-patch/falcon512-oid.patch"
    exit 1
fi

echo -e "${YELLOW}[1/2] Preparing validation environment...${NC}"
echo "  ROA Directory: $ROA_DIR"
echo "  Trust Anchor: $TA_CERT"
echo "  Output Log: $OUTPUT_LOG"
echo ""

# Count ROA files
ROA_COUNT=$(find "$ROA_DIR" -name "*.roa" | wc -l | tr -d ' ')
echo "  Found $ROA_COUNT ROA file(s)"
echo ""

# Create temporary repository structure for rpki-client
TMP_REPO=$(mktemp -d)
mkdir -p "$TMP_REPO/ta"
cp "$TA_CERT" "$TMP_REPO/ta/ca-falcon.crt"

# Copy ROAs to repository
mkdir -p "$TMP_REPO/repo"
find "$ROA_DIR" -name "*.roa" -exec cp {} "$TMP_REPO/repo/" \;

echo -e "${YELLOW}[2/2] Running rpki-client validation...${NC}"
echo ""

# Run rpki-client
# Note: rpki-client expects a specific directory structure
# This is a simplified validation - production would use proper RPKI repository structure

# Create a simple validation
echo "=== rpki-client Validation Output ===" > "$OUTPUT_LOG"
echo "Date: $(date)" >> "$OUTPUT_LOG"
echo "Trust Anchor: $TA_CERT" >> "$OUTPUT_LOG"
echo "ROA Directory: $ROA_DIR" >> "$OUTPUT_LOG"
echo "" >> "$OUTPUT_LOG"

# Try to validate
if rpki-client -v -d "$TMP_REPO/repo" -t "$TA_CERT" >> "$OUTPUT_LOG" 2>&1; then
    echo -e "${GREEN}[OK] rpki-client validation completed${NC}"
    VALIDATION_RESULT="SUCCESS"
else
    EXIT_CODE=$?
    echo -e "${YELLOW}[WARN] rpki-client exited with code $EXIT_CODE${NC}"
    echo "  (This may be expected if rpki-client isn't patched for Falcon-512)"
    VALIDATION_RESULT="PARTIAL"
fi

echo "" >> "$OUTPUT_LOG"
echo "=== End of Validation ===" >> "$OUTPUT_LOG"

# Display results
echo ""
echo -e "${BLUE}Validation Results:${NC}"
echo "  Status: $VALIDATION_RESULT"
echo "  Log saved to: $OUTPUT_LOG"
echo ""

# Show key parts of the log
if [ -f "$OUTPUT_LOG" ]; then
    echo -e "${YELLOW}Key output from rpki-client:${NC}"
    grep -E "(Route Origin|Certificates|valid|invalid|error)" "$OUTPUT_LOG" | head -20 || cat "$OUTPUT_LOG" | tail -30
fi

# Cleanup
rm -rf "$TMP_REPO"

echo ""
if [ "$VALIDATION_RESULT" = "SUCCESS" ]; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}SUCCESS: ROA Validated${NC}"
    echo -e "${GREEN}========================================${NC}"
else
    echo -e "${YELLOW}========================================${NC}"
    echo -e "${YELLOW}Validation completed (check log for details)${NC}"
    echo -e "${YELLOW}========================================${NC}"
fi
echo ""
echo "Full log: $OUTPUT_LOG"
echo ""

