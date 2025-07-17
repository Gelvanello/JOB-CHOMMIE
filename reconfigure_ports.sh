#!/bin/bash

# AI Job Chommie Port Reconfiguration Script
# This script reconfigures the application to use the correct ports:
# - Frontend: 5173 (instead of 3000)
# - Backend: 5000 (no change)

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
FRONTEND_OLD_PORT=3000
FRONTEND_NEW_PORT=5173
BACKEND_PORT=5000
BACKUP_DIR="./backup_$(date +%Y%m%d_%H%M%S)"
LOG_FILE="./reconfigure_ports_$(date +%Y%m%d_%H%M%S).log"

# Base directories
FRONTEND_DIR="home/ubuntu/AIJobChommie/AIJobChommiefinal_package/ai-job-chommie-src/ai-job-chommie-frontend"
BACKEND_DIR="home/ubuntu/AIJobChommie/AIJobChommiefinal_package/ai-job-chommie-src/ai-job-chommie-backend"
ROOT_DIR="home/ubuntu/AIJobChommie/AIJobChommiefinal_package/ai-job-chommie-src"

# Files to check and update
declare -a FILES_TO_UPDATE=(
    "$FRONTEND_DIR/vite.config.js"
    "$FRONTEND_DIR/package.json"
    "$FRONTEND_DIR/src/lib/api.js"
    "$BACKEND_DIR/src/main.py"
    "$BACKEND_DIR/src/config.py"
    "$ROOT_DIR/docker-compose.yml"
    "$ROOT_DIR/start.bat"
    "$ROOT_DIR/README.md"
    "$ROOT_DIR/QUICK_START.md"
    "$ROOT_DIR/GET_STARTED.md"
    "$ROOT_DIR/API_DOCUMENTATION.md"
    "$ROOT_DIR/DEPLOYMENT.md"
)

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}" | tee -a "$LOG_FILE"
}

# Function to print status
print_status() {
    local status=$1
    local message=$2
    if [ "$status" = "success" ]; then
        print_message "$GREEN" "✓ $message"
    elif [ "$status" = "error" ]; then
        print_message "$RED" "✗ $message"
    elif [ "$status" = "warning" ]; then
        print_message "$YELLOW" "⚠ $message"
    else
        print_message "$BLUE" "→ $message"
    fi
}

# Function to check if a process is running on a port
check_port() {
    local port=$1
    if command -v lsof >/dev/null 2>&1; then
        lsof -i :$port >/dev/null 2>&1
    elif command -v netstat >/dev/null 2>&1; then
        netstat -tuln | grep -q ":$port "
    elif command -v ss >/dev/null 2>&1; then
        ss -tuln | grep -q ":$port "
    else
        print_status "warning" "Cannot check port status - no suitable command found"
        return 1
    fi
}

# Function to kill processes on a port
kill_port_process() {
    local port=$1
    print_status "info" "Checking for processes on port $port..."
    
    if check_port $port; then
        print_status "info" "Found process on port $port, attempting to stop..."
        
        # Try different methods to find and kill the process
        if command -v lsof >/dev/null 2>&1; then
            local pids=$(lsof -ti :$port)
            if [ ! -z "$pids" ]; then
                for pid in $pids; do
                    print_status "info" "Killing process $pid on port $port"
                    kill -TERM $pid 2>/dev/null || true
                    sleep 2
                    kill -KILL $pid 2>/dev/null || true
                done
            fi
        elif command -v fuser >/dev/null 2>&1; then
            fuser -k $port/tcp 2>/dev/null || true
        else
            print_status "warning" "Cannot kill process - no suitable command found"
            return 1
        fi
        
        sleep 2
        if check_port $port; then
            print_status "error" "Failed to stop process on port $port"
            return 1
        else
            print_status "success" "Successfully stopped process on port $port"
        fi
    else
        print_status "info" "No process found on port $port"
    fi
    return 0
}

# Function to create backup
create_backup() {
    print_status "info" "Creating backup directory: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    
    for file in "${FILES_TO_UPDATE[@]}"; do
        if [ -f "$file" ]; then
            local backup_path="$BACKUP_DIR/$(basename "$file")"
            cp "$file" "$backup_path" 2>/dev/null || true
            print_status "success" "Backed up: $(basename "$file")"
        fi
    done
    
    # Create restore script
    cat > "$BACKUP_DIR/restore.sh" << 'EOF'
#!/bin/bash
# Restore script for AI Job Chommie port configuration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Restoring files from backup..."

# List of files to restore with their original paths
declare -A FILE_PATHS=(
EOF

    # Add file mappings to restore script
    for file in "${FILES_TO_UPDATE[@]}"; do
        if [ -f "$file" ]; then
            echo "    [\"$(basename "$file")\"]=\"$file\"" >> "$BACKUP_DIR/restore.sh"
        fi
    done

    cat >> "$BACKUP_DIR/restore.sh" << 'EOF'
)

# Restore each file
for filename in "${!FILE_PATHS[@]}"; do
    src="$SCRIPT_DIR/$filename"
    dest="${FILE_PATHS[$filename]}"
    
    if [ -f "$src" ]; then
        cp "$src" "$dest" && echo "✓ Restored: $filename"
    else
        echo "✗ Backup file not found: $filename"
    fi
done

echo "Restore complete!"
EOF

    chmod +x "$BACKUP_DIR/restore.sh"
    print_status "success" "Backup complete. Restore script created at: $BACKUP_DIR/restore.sh"
}

# Function to update port references in a file
update_port_in_file() {
    local file=$1
    local temp_file="${file}.tmp"
    
    if [ ! -f "$file" ]; then
        print_status "warning" "File not found: $file"
        return 0
    fi
    
    print_status "info" "Updating ports in: $(basename "$file")"
    
    # Create a temporary file with updated content
    cp "$file" "$temp_file"
    
    # Update port references
    # Replace :3000 with :5173 (with word boundaries where possible)
    sed -i 's/:3000/:5173/g' "$temp_file"
    
    # Replace port 3000 with port 5173 in various contexts
    sed -i 's/port[[:space:]]*3000/port 5173/g' "$temp_file"
    sed -i 's/PORT[[:space:]]*3000/PORT 5173/g' "$temp_file"
    sed -i 's/localhost:3000/localhost:5173/g' "$temp_file"
    sed -i 's/127\.0\.0\.1:3000/127.0.0.1:5173/g' "$temp_file"
    
    # Check if file was actually modified
    if ! diff -q "$file" "$temp_file" >/dev/null; then
        mv "$temp_file" "$file"
        print_status "success" "Updated: $(basename "$file")"
        return 0
    else
        rm "$temp_file"
        print_status "info" "No changes needed in: $(basename "$file")"
        return 0
    fi
}

# Function to update Vite configuration
update_vite_config() {
    local vite_config="$FRONTEND_DIR/vite.config.js"
    
    if [ ! -f "$vite_config" ]; then
        print_status "warning" "vite.config.js not found"
        return 0
    fi
    
    print_status "info" "Updating Vite configuration..."
    
    # Check if server configuration exists
    if ! grep -q "server:" "$vite_config"; then
        # Add server configuration before the last closing brace
        local temp_file="${vite_config}.tmp"
        awk '
            /^})/ && !done {
                print "  server: {"
                print "    port: 5173,"
                print "    host: true,"
                print "    strictPort: true"
                print "  },"
                done = 1
            }
            { print }
        ' "$vite_config" > "$temp_file"
        mv "$temp_file" "$vite_config"
        print_status "success" "Added server configuration to vite.config.js"
    else
        # Update existing server configuration
        sed -i 's/port:[[:space:]]*[0-9]\+/port: 5173/g' "$vite_config"
        print_status "success" "Updated existing server configuration in vite.config.js"
    fi
}

# Function to update package.json scripts
update_package_json() {
    local package_json="$FRONTEND_DIR/package.json"
    
    if [ ! -f "$package_json" ]; then
        print_status "warning" "package.json not found"
        return 0
    fi
    
    print_status "info" "Updating package.json scripts..."
    
    # Update dev script to explicitly use port 5173
    local temp_file="${package_json}.tmp"
    sed 's/"dev":[[:space:]]*"vite"/"dev": "vite --port 5173"/' "$package_json" > "$temp_file"
    
    if ! diff -q "$package_json" "$temp_file" >/dev/null; then
        mv "$temp_file" "$package_json"
        print_status "success" "Updated package.json dev script"
    else
        rm "$temp_file"
        # Try alternative format
        sed -i 's/"dev":[[:space:]]*"vite[^"]*"/"dev": "vite --port 5173"/' "$package_json"
        print_status "info" "Package.json dev script updated"
    fi
}

# Function to update CORS settings in backend
update_cors_settings() {
    local main_py="$BACKEND_DIR/src/main.py"
    
    if [ ! -f "$main_py" ]; then
        print_status "warning" "main.py not found"
        return 0
    fi
    
    print_status "info" "Updating CORS settings..."
    
    # The CORS settings are already correctly configured in main.py
    # Just ensure port 3000 references are updated to 5173
    update_port_in_file "$main_py"
}

# Function to verify services
verify_services() {
    print_status "info" "Verifying service accessibility..."
    
    local frontend_url="http://localhost:$FRONTEND_NEW_PORT"
    local backend_url="http://localhost:$BACKEND_PORT"
    
    # Check if curl is available
    if ! command -v curl >/dev/null 2>&1; then
        print_status "warning" "curl not found - cannot verify services"
        return 0
    fi
    
    # Check backend
    print_status "info" "Checking backend at $backend_url..."
    if curl -s -o /dev/null -w "%{http_code}" "$backend_url" | grep -q "200\|404"; then
        print_status "success" "Backend is accessible at $backend_url"
    else
        print_status "warning" "Backend may not be running at $backend_url"
    fi
    
    # Check frontend
    print_status "info" "Checking frontend at $frontend_url..."
    if curl -s -o /dev/null -w "%{http_code}" "$frontend_url" | grep -q "200\|404"; then
        print_status "success" "Frontend is accessible at $frontend_url"
    else
        print_status "warning" "Frontend may not be running at $frontend_url"
    fi
}

# Function to update environment files
update_env_files() {
    print_status "info" "Checking for .env files..."
    
    # Check for .env files in various locations
    local env_files=(
        "$FRONTEND_DIR/.env"
        "$FRONTEND_DIR/.env.local"
        "$FRONTEND_DIR/.env.development"
        "$FRONTEND_DIR/.env.production"
        "$BACKEND_DIR/.env"
        "$BACKEND_DIR/src/.env"
        "$ROOT_DIR/.env"
    )
    
    for env_file in "${env_files[@]}"; do
        if [ -f "$env_file" ]; then
            print_status "info" "Updating environment file: $env_file"
            update_port_in_file "$env_file"
            
            # Update VITE_API_BASE_URL if present
            sed -i 's/VITE_API_BASE_URL=http:\/\/localhost:3000/VITE_API_BASE_URL=http:\/\/localhost:5000/g' "$env_file"
        fi
    done
}

# Main execution
main() {
    print_message "$BLUE" "========================================="
    print_message "$BLUE" "AI Job Chommie Port Reconfiguration Tool"
    print_message "$BLUE" "========================================="
    print_message "$BLUE" "Frontend: $FRONTEND_OLD_PORT → $FRONTEND_NEW_PORT"
    print_message "$BLUE" "Backend: $BACKEND_PORT (no change)"
    print_message "$BLUE" "========================================="
    echo ""
    
    # Start logging
    echo "Port reconfiguration started at $(date)" > "$LOG_FILE"
    
    # Step 1: Create backup
    print_status "info" "Step 1: Creating backup..."
    create_backup
    echo ""
    
    # Step 2: Stop running processes
    print_status "info" "Step 2: Stopping processes on old ports..."
    kill_port_process $FRONTEND_OLD_PORT
    kill_port_process $FRONTEND_NEW_PORT
    kill_port_process $BACKEND_PORT
    echo ""
    
    # Step 3: Update configuration files
    print_status "info" "Step 3: Updating configuration files..."
    
    # Update all files
    for file in "${FILES_TO_UPDATE[@]}"; do
        update_port_in_file "$file"
    done
    
    # Special handling for specific files
    update_vite_config
    update_package_json
    update_cors_settings
    update_env_files
    echo ""
    
    # Step 4: Restart services
    print_status "info" "Step 4: Starting services on correct ports..."
    
    # Check if we should use the start.bat script
    if [ -f "$ROOT_DIR/start.bat" ] && command -v cmd.exe >/dev/null 2>&1; then
        print_status "info" "Starting services using start.bat..."
        cd "$ROOT_DIR" && cmd.exe /c start.bat &
    else
        # Start services manually
        print_status "info" "Starting backend service..."
        cd "$BACKEND_DIR/src" && {
            if [ -d "venv" ]; then
                source venv/bin/activate 2>/dev/null || . venv/Scripts/activate 2>/dev/null || true
            fi
            python main.py > /dev/null 2>&1 &
            print_status "success" "Backend service started"
        }
        
        print_status "info" "Starting frontend service..."
        cd "$FRONTEND_DIR" && {
            npm run dev > /dev/null 2>&1 &
            print_status "success" "Frontend service started"
        }
    fi
    
    # Wait for services to start
    print_status "info" "Waiting for services to start..."
    sleep 5
    echo ""
    
    # Step 5: Verify services
    print_status "info" "Step 5: Verifying services..."
    verify_services
    echo ""
    
    # Summary
    print_message "$GREEN" "========================================="
    print_message "$GREEN" "Port reconfiguration completed!"
    print_message "$GREEN" "========================================="
    print_status "success" "Frontend: http://localhost:$FRONTEND_NEW_PORT"
    print_status "success" "Backend: http://localhost:$BACKEND_PORT"
    print_status "success" "Backup created at: $BACKUP_DIR"
    print_status "success" "Log file: $LOG_FILE"
    echo ""
    print_message "$YELLOW" "To restore previous configuration, run:"
    print_message "$YELLOW" "  $BACKUP_DIR/restore.sh"
    echo ""
    
    # Final check
    if check_port $FRONTEND_NEW_PORT && check_port $BACKEND_PORT; then
        print_message "$GREEN" "✓ All services are running correctly!"
    else
        print_message "$YELLOW" "⚠ Some services may not be running. Check the log file for details."
    fi
}

# Error handler
error_handler() {
    local line_no=$1
    print_status "error" "An error occurred at line $line_no"
    print_status "error" "Check the log file: $LOG_FILE"
    print_message "$YELLOW" "You can restore the previous configuration by running:"
    print_message "$YELLOW" "  $BACKUP_DIR/restore.sh"
    exit 1
}

# Set error trap
trap 'error_handler $LINENO' ERR

# Run main function
main

# Disable error trap
trap - ERR

exit 0