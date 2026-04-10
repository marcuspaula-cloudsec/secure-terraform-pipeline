#!/bin/bash
# Pre-push security validation — run locally before pushing
# Same checks as CI/CD pipeline but faster feedback loop
# Based on the automation mindset: catch issues before they reach the pipeline

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0

echo "============================================"
echo " Terraform Security Validation"
echo "============================================"
echo ""

# 1. Format check
echo -n "[1/4] Terraform Format... "
if terraform -chdir=terraform fmt -check -recursive > /dev/null 2>&1; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC} — run: terraform -chdir=terraform fmt -recursive"
    ERRORS=$((ERRORS + 1))
fi

# 2. Validate
echo -n "[2/4] Terraform Validate... "
if terraform -chdir=terraform validate > /dev/null 2>&1; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
    terraform -chdir=terraform validate
    ERRORS=$((ERRORS + 1))
fi

# 3. Checkov scan
echo -n "[3/4] Checkov Security Scan... "
if command -v checkov > /dev/null 2>&1; then
    if checkov -d terraform/ --config-file checkov/.checkov.yml --compact --quiet > /dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC}"
    else
        echo -e "${RED}FAIL${NC}"
        checkov -d terraform/ --config-file checkov/.checkov.yml --compact
        ERRORS=$((ERRORS + 1))
    fi
else
    echo -e "${YELLOW}SKIP${NC} — install: pip install checkov"
fi

# 4. TFLint
echo -n "[4/4] TFLint... "
if command -v tflint > /dev/null 2>&1; then
    if tflint --config .tflint.hcl terraform/ > /dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC}"
    else
        echo -e "${RED}FAIL${NC}"
        tflint --config .tflint.hcl terraform/
        ERRORS=$((ERRORS + 1))
    fi
else
    echo -e "${YELLOW}SKIP${NC} — install: brew install tflint"
fi

echo ""
echo "============================================"
if [ $ERRORS -eq 0 ]; then
    echo -e " ${GREEN}All checks passed — safe to push${NC}"
else
    echo -e " ${RED}${ERRORS} check(s) failed — fix before pushing${NC}"
    exit 1
fi
