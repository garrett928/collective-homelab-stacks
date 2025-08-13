#!/bin/bash

# Ansible playbook syntax checker
# This script validates the syntax of all playbooks

echo "🔍 Checking Ansible playbook syntax..."
echo "===================================="

# Directory containing playbooks
PLAYBOOK_DIR="playbooks"
INVENTORY_FILE="inventories/host-inventory.yml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counter for results
passed=0
failed=0

# Check if ansible-playbook is available
if ! command -v ansible-playbook &> /dev/null; then
    echo -e "${RED}❌ ansible-playbook command not found${NC}"
    echo "Please install Ansible first"
    exit 1
fi

# Function to check playbook syntax
check_playbook() {
    local playbook="$1"
    echo -n "Checking $playbook... "
    
    if ansible-playbook --syntax-check "$playbook" -i "$INVENTORY_FILE" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
        ((passed++))
    else
        echo -e "${RED}❌ FAIL${NC}"
        echo -e "${YELLOW}Details:${NC}"
        ansible-playbook --syntax-check "$playbook" -i "$INVENTORY_FILE"
        ((failed++))
    fi
}

# Check main playbooks
echo -e "${YELLOW}Ubuntu playbooks:${NC}"
check_playbook "$PLAYBOOK_DIR/ubuntu/ubuntu-server-setup.yml"
check_playbook "$PLAYBOOK_DIR/ubuntu/install-node-exporter.yml"
check_playbook "$PLAYBOOK_DIR/ubuntu/install-promtail.yml"

echo ""
echo -e "${YELLOW}General playbooks:${NC}"
check_playbook "$PLAYBOOK_DIR/validate-setup.yml"

echo ""
echo -e "${YELLOW}Other playbooks:${NC}"
# Check other playbooks in subdirectories
find "$PLAYBOOK_DIR" -name "*.yml" -not -path "*/ubuntu/ubuntu-server-setup.yml" -not -path "*/ubuntu/install-*.yml" -not -path "*/validate-setup.yml" | while read -r playbook; do
    check_playbook "$playbook"
done

echo ""
echo "===================================="
if [ $failed -eq 0 ]; then
    echo -e "${GREEN}🎉 All playbooks passed syntax check!${NC}"
    exit 0
else
    echo -e "${RED}⚠️  $failed playbook(s) failed syntax check${NC}"
    exit 1
fi
