#!/bin/bash
# setup.sh - One-click setup for SecureBank on Linux/Mac

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════╗"
echo "║    🏦 SecureBank - Setup Script           ║"
echo "║    For Linux & macOS                     ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"
echo

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

# Function to install package
install_package() {
    local pkg=$1
    local install_cmd=""
    
    if command -v apt-get &> /dev/null; then
        install_cmd="sudo apt-get install -y $pkg"
    elif command -v yum &> /dev/null; then
        install_cmd="sudo yum install -y $pkg"
    elif command -v dnf &> /dev/null; then
        install_cmd="sudo dnf install -y $pkg"
    elif command -v pacman &> /dev/null; then
        install_cmd="sudo pacman -S --noconfirm $pkg"
    elif command -v brew &> /dev/null; then
        install_cmd="brew install $pkg"
    else
        echo -e "${RED}❌ Could not detect package manager${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}📦 Installing $pkg...${NC}"
    eval $install_cmd
    return $?
}

# Check if running as root (for some operations)
if [ "$EUID" -ne 0 ]; then 
    echo -e "${YELLOW}⚠️  Some operations require sudo privileges${NC}"
fi

echo -e "${BLUE}🔍 Checking prerequisites...${NC}"
echo

# Check Java
echo "Checking Java..."
if command -v java &> /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d '"' -f 2)
    print_status 0 "Java found: $JAVA_VERSION"
    
    # Check if Java 17+
    MAJOR_VERSION=$(echo $JAVA_VERSION | cut -d '.' -f 1)
    if [[ "$MAJOR_VERSION" -lt 17 ]]; then
        echo -e "${RED}❌ Java 17+ required. Found version $JAVA_VERSION${NC}"
        echo -e "${YELLOW}📥 Install Java 17:${NC}"
        echo "  Ubuntu/Debian: sudo apt install openjdk-17-jdk"
        echo "  Fedora/RHEL: sudo dnf install java-17-openjdk"
        echo "  Arch: sudo pacman -S jdk17-openjdk"
        echo "  macOS: brew install openjdk@17"
        exit 1
    fi
else
    echo -e "${RED}❌ Java not found${NC}"
    read -p "Install Java 17 now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_package "openjdk-17-jdk" || install_package "java-17-openjdk"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Java installed successfully${NC}"
        else
            echo -e "${RED}❌ Failed to install Java${NC}"
            exit 1
        fi
    else
        exit 1
    fi
fi

# Check Maven
echo "Checking Maven..."
if command -v mvn &> /dev/null; then
    MAVEN_VERSION=$(mvn -v 2>&1 | grep "Apache Maven" | cut -d ' ' -f 3)
    print_status 0 "Maven found: $MAVEN_VERSION"
else
    echo -e "${RED}❌ Maven not found${NC}"
    read -p "Install Maven now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_package "maven"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Maven installed successfully${NC}"
        else
            echo -e "${RED}❌ Failed to install Maven${NC}"
            exit 1
        fi
    else
        exit 1
    fi
fi

echo
echo -e "${BLUE}🗄️  Database Setup${NC}"
echo

# Check MySQL/MariaDB
echo "Checking database..."
if command -v mysql &> /dev/null || command -v mariadb &> /dev/null; then
    print_status 0 "MySQL/MariaDB found"
    
    # Check if service is running
    if sudo systemctl is-active --quiet mysql || sudo systemctl is-active --quiet mariadb; then
        print_status 0 "Database service is running"
    else
        echo -e "${YELLOW}⚠️  Database service not running${NC}"
        read -p "Start database service now? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sudo systemctl start mysql 2>/dev/null || sudo systemctl start mariadb
            sudo systemctl enable mysql 2>/dev/null || sudo systemctl enable mariadb
            print_status $? "Database service started"
        fi
    fi
else
    echo -e "${RED}❌ MySQL/MariaDB not found${NC}"
    read -p "Install MariaDB now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        install_package "mariadb"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ MariaDB installed successfully${NC}"
            
            # Initialize database
            sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
            sudo systemctl start mariadb
            sudo systemctl enable mariadb
            
            echo -e "${YELLOW}🔐 Running mysql_secure_installation...${NC}"
            echo "Please set root password to: password (for this demo)"
            echo "Answer Y to all security questions"
            sudo mariadb-secure-installation
        else
            echo -e "${RED}❌ Failed to install MariaDB${NC}"
            exit 1
        fi
    else
        exit 1
    fi
fi

# Setup database
echo
echo -e "${YELLOW}📊 Setting up banking_system database...${NC}"

# Try with default password first, then prompt
mysql -u root -ppassword -e "SELECT 1;" &>/dev/null
if [ $? -ne 0 ]; then
    echo -e "${YELLOW}⚠️  Could not connect with default password${NC}"
    read -sp "Enter MySQL root password: " MYSQL_PASSWORD
    echo
else
    MYSQL_PASSWORD="password"
fi

# Create database
mysql -u root -p$MYSQL_PASSWORD << EOF 2>/dev/null
DROP DATABASE IF EXISTS banking_system;
CREATE DATABASE banking_system;
GRANT ALL PRIVILEGES ON banking_system.* TO 'root'@'localhost';
FLUSH PRIVILEGES;
EOF

if [ $? -eq 0 ]; then
    print_status 0 "Database created successfully"
else
    echo -e "${RED}❌ Failed to create database${NC}"
    echo -e "${YELLOW}Manual setup required:${NC}"
    echo "1. Open MySQL: sudo mysql -u root -p"
    echo "2. Run: CREATE DATABASE banking_system;"
    echo "3. Run: GRANT ALL PRIVILEGES ON banking_system.* TO 'root'@'localhost';"
    echo "4. Run: FLUSH PRIVILEGES;"
    echo "5. Exit and run this script again"
    exit 1
fi

echo
echo -e "${BLUE}🏗️  Building Project${NC}"
echo

# Clean and build
echo -e "${YELLOW}🧹 Cleaning previous builds...${NC}"
mvn clean -q
print_status $? "Clean completed"

echo -e "${YELLOW}🔨 Building project...${NC}"
mvn install -DskipTests -q
if [ $? -eq 0 ]; then
    print_status 0 "Build successful!"
else
    echo -e "${RED}❌ Build failed! Trying verbose mode...${NC}"
    mvn install
    exit 1
fi

echo
echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           🎉 SETUP COMPLETE!             ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
echo
echo -e "${GREEN}✅ SecureBank is ready to use!${NC}"
echo
echo -e "${YELLOW}📋 Quick Start:${NC}"
echo "  1. Start the application: ./run.sh"
echo "  2. Or: mvn spring-boot:run"
echo "  3. Open browser: ${GREEN}http://localhost:8080${NC}"
echo
echo -e "${YELLOW}🔑 Default Credentials:${NC}"
echo "  👑 Admin: ${GREEN}admin${NC} / ${GREEN}admin123${NC}"
echo "  👤 User:  ${GREEN}john${NC}  / ${GREEN}password123${NC}"
echo
echo -e "${YELLOW}🗄️  Database Info:${NC}"
echo "  Database: ${GREEN}banking_system${NC}"
echo "  Username: ${GREEN}root${NC}"
echo "  Password: ${GREEN}password${NC}"
echo
echo -e "${YELLOW}🛠️  Useful Commands:${NC}"
echo "  Start:        ./run.sh"
echo "  Reset DB:     ./reset-database.sh"
echo "  View logs:    tail -f nohup.out"
echo "  Stop app:     Ctrl+C"
echo
echo -e "${YELLOW}📁 Project Structure:${NC}"
echo "  Main app:     src/main/java/com/banking/system/BankApplication.java"
echo "  Config:       src/main/resources/application.properties"
echo "  Templates:    src/main/resources/templates/"
echo
echo -e "${BLUE}════════════════════════════════════════════${NC}"
echo -e "${GREEN}Need help? Check README.md for more details${NC}"
