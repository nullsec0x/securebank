#!/bin/bash
# run.sh - Start SecureBank application

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════╗"
echo "║    🏦 SecureBank Banking System          ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"
echo

# Check if MySQL is running
echo -e "${YELLOW}🔍 Checking database service...${NC}"
if ! sudo systemctl is-active --quiet mysql 2>/dev/null && ! sudo systemctl is-active --quiet mariadb 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Database service not running${NC}"
    read -p "Start MariaDB/MySQL service now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo systemctl start mariadb 2>/dev/null || sudo systemctl start mysql 2>/dev/null
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Database service started${NC}"
        else
            echo -e "${YELLOW}⚠️  Could not start database service${NC}"
            echo "Please start MySQL/MariaDB manually and try again"
            exit 1
        fi
    fi
else
    echo -e "${GREEN}✅ Database service is running${NC}"
fi

echo
echo -e "${YELLOW}🚀 Starting SecureBank...${NC}"
echo -e "${BLUE}➡️  Application will start at: http://localhost:8080${NC}"
echo -e "${YELLOW}➡️  Press Ctrl+C to stop${NC}"
echo

# Run in background with logging
nohup mvn spring-boot:run > nohup.out 2>&1 &
APP_PID=$!

echo -e "${GREEN}✅ Application started with PID: $APP_PID${NC}"
echo -e "${YELLOW}📝 Logs are being written to: nohup.out${NC}"
echo -e "${YELLOW}👀 To view logs in real-time: tail -f nohup.out${NC}"
echo

# Show initial logs
sleep 3
echo -e "${BLUE}════════════════════════════════════════════${NC}"
echo -e "${YELLOW}Initial application output:${NC}"
echo -e "${BLUE}════════════════════════════════════════════${NC}"
tail -20 nohup.out
echo -e "${BLUE}════════════════════════════════════════════${NC}"
echo

echo -e "${GREEN}🎉 SecureBank is running!${NC}"
echo -e "${YELLOW}🌐 Open your browser and go to:${NC}"
echo -e "${GREEN}   http://localhost:8080${NC}"
echo
echo -e "${YELLOW}🔑 Default logins:${NC}"
echo -e "   👑 Admin: ${GREEN}admin${NC} / ${GREEN}admin123${NC}"
echo -e "   👤 User:  ${GREEN}john${NC}  / ${GREEN}password123${NC}"
echo
echo -e "${YELLOW}🛑 To stop the application:${NC}"
echo -e "   Press ${GREEN}Ctrl+C${NC} in this terminal"
echo -e "   Or run: ${GREEN}kill $APP_PID${NC}"
echo

# Wait for Ctrl+C
trap "echo -e '\n${YELLOW}🛑 Stopping SecureBank...${NC}'; kill $APP_PID 2>/dev/null; exit 0" INT

# Keep script running
while kill -0 $APP_PID 2>/dev/null; do
    sleep 1
done

echo -e "${GREEN}✅ Application stopped${NC}"
