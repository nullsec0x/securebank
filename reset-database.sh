#!/bin/bash
# reset-database.sh - Reset SecureBank database

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}"
echo "╔══════════════════════════════════════════╗"
echo "║    ⚠️   DATABASE RESET TOOL              ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"
echo

echo -e "${RED}⚠️  WARNING: This will delete ALL banking data!${NC}"
echo -e "${RED}⚠️  All users, accounts, and transactions will be lost!${NC}"
echo
read -p "Type 'RESET' to confirm: " CONFIRM

if [ "$CONFIRM" != "RESET" ]; then
    echo -e "${YELLOW}❌ Cancelled${NC}"
    exit 0
fi

echo
echo -e "${YELLOW}🔍 Checking database connection...${NC}"

# Try default password first
MYSQL_PASSWORD="password"
mysql -u root -p$MYSQL_PASSWORD -e "SELECT 1;" &>/dev/null

if [ $? -ne 0 ]; then
    echo -e "${YELLOW}⚠️  Could not connect with default password${NC}"
    read -sp "Enter MySQL root password: " MYSQL_PASSWORD
    echo
fi

echo -e "${YELLOW}🗑️  Resetting database...${NC}"

mysql -u root -p$MYSQL_PASSWORD << 'EOF'
DROP DATABASE IF EXISTS banking_system;
CREATE DATABASE banking_system;
GRANT ALL PRIVILEGES ON banking_system.* TO 'root'@'localhost';
FLUSH PRIVILEGES;
EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Database reset successfully!${NC}"
    echo
    echo -e "${YELLOW}📋 Next steps:${NC}"
    echo "1. Restart the application: ./run.sh"
    echo "2. Demo users will be created automatically"
    echo "3. Login with:"
    echo "   - Admin: admin / admin123"
    echo "   - User:  john / password123"
else
    echo -e "${RED}❌ Failed to reset database${NC}"
    echo
    echo -e "${YELLOW}🔧 Manual reset required:${NC}"
    echo "1. Open MySQL: sudo mysql -u root -p"
    echo "2. Run: DROP DATABASE banking_system;"
    echo "3. Run: CREATE DATABASE banking_system;"
    echo "4. Run: GRANT ALL PRIVILEGES ON banking_system.* TO 'root'@'localhost';"
    echo "5. Run: FLUSH PRIVILEGES;"
    exit 1
fi
