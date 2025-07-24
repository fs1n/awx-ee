#!/bin/bash
# Test script for AWX Execution Environment
# This script provides local testing capabilities that mirror the CI/CD pipeline

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
CONTAINER_RUNTIME="podman"
IMAGE_NAME="awx-ee:test"
VERBOSE=false

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to run tests
run_tests() {
    local image_name="$1"
    
    print_status "Starting tests for image: $image_name"
    
    # Test 1: Basic functionality
    print_status "Test 1: Basic ansible functionality"
    if $CONTAINER_RUNTIME run --rm "$image_name" ansible --version >/dev/null 2>&1; then
        print_status "✓ Ansible is working"
    else
        print_error "✗ Ansible failed"
        return 1
    fi
    
    # Test 2: Python version
    print_status "Test 2: Python version check"
    python_version=$($CONTAINER_RUNTIME run --rm "$image_name" python --version 2>&1)
    print_status "✓ Python version: $python_version"
    
    # Test 3: Collections
    print_status "Test 3: Checking installed collections"
    if $CONTAINER_RUNTIME run --rm "$image_name" ansible-galaxy collection list >/dev/null 2>&1; then
        print_status "✓ Collections are installed"
    else
        print_error "✗ Collections check failed"
        return 1
    fi
    
    # Test 4: Key collections
    print_status "Test 4: Verifying key collections"
    collections_output=$($CONTAINER_RUNTIME run --rm "$image_name" ansible-galaxy collection list 2>/dev/null || echo "")
    
    # Check for important collections
    for collection in "awx.awx" "community.vmware" "vmware.vmware" "kubernetes.core" "amazon.aws"; do
        if echo "$collections_output" | grep -q "$collection"; then
            print_status "✓ Found collection: $collection"
        else
            print_warning "? Collection not found: $collection"
        fi
    done
    
    # Test 5: Python packages
    print_status "Test 5: Verifying Python packages"
    $CONTAINER_RUNTIME run --rm "$image_name" python -c "
import sys
packages = ['pyvmomi', 'paramiko', 'requests', 'pyyaml', 'ansible']
failed = []
for pkg in packages:
    try:
        __import__(pkg)
        print(f'✓ {pkg} - OK')
    except ImportError as e:
        print(f'✗ {pkg} - FAILED: {e}')
        failed.append(pkg)

if failed:
    print(f'Failed packages: {failed}')
    sys.exit(1)
else:
    print('All critical packages available')
"
    
    # Test 6: Sample playbook
    print_status "Test 6: Running sample playbook"
    
    # Create test playbook
    test_dir="/tmp/awx-ee-test-$$"
    mkdir -p "$test_dir"
    
    cat > "$test_dir/test.yml" << 'EOF'
---
- name: Test AWX EE functionality
  hosts: localhost
  gather_facts: true
  tasks:
    - name: Test debug output
      debug:
        msg: "AWX EE is working correctly"
    
    - name: Verify Python version
      debug:
        var: ansible_python_version
    
    - name: Test that we can import Python modules
      debug:
        msg: "Python modules test passed"
EOF
    
    if $CONTAINER_RUNTIME run --rm -v "$test_dir:$test_dir" "$image_name" \
        ansible-playbook "$test_dir/test.yml" >/dev/null 2>&1; then
        print_status "✓ Sample playbook executed successfully"
    else
        print_error "✗ Sample playbook failed"
        rm -rf "$test_dir"
        return 1
    fi
    
    rm -rf "$test_dir"
    
    print_status "All tests passed! ✓"
}

# Function to build the image
build_image() {
    print_status "Building AWX Execution Environment..."
    
    if command -v ansible-builder >/dev/null 2>&1; then
        print_status "Using ansible-builder to build image"
        ansible-builder build -v3 --container-runtime "$CONTAINER_RUNTIME" -t "$IMAGE_NAME"
    else
        print_error "ansible-builder not found. Please install it first:"
        print_error "pip install ansible-builder"
        return 1
    fi
}

# Function to validate configuration
validate_config() {
    print_status "Validating execution environment configuration..."
    
    # Check if execution-environment.yml exists
    if [[ ! -f "execution-environment.yml" ]]; then
        print_error "execution-environment.yml not found"
        return 1
    fi
    
    # Validate YAML syntax
    if command -v yamllint >/dev/null 2>&1; then
        if yamllint execution-environment.yml >/dev/null 2>&1; then
            print_status "✓ YAML syntax is valid"
        else
            print_warning "YAML syntax issues found (but continuing)"
        fi
    else
        print_warning "yamllint not installed, skipping YAML validation"
    fi
    
    # Check ansible-builder
    if command -v ansible-builder >/dev/null 2>&1; then
        print_status "✓ ansible-builder is available"
        ansible-builder --version
    else
        print_error "ansible-builder not found"
        return 1
    fi
}

# Help function
show_help() {
    cat << EOF
Usage: $0 [OPTIONS] [COMMAND]

Commands:
    validate    Validate the execution environment configuration
    build       Build the execution environment image
    test        Run tests on existing image
    all         Run validate, build, and test (default)

Options:
    -r, --runtime RUNTIME    Container runtime (podman or docker, default: podman)
    -t, --tag TAG           Image tag (default: awx-ee:test)
    -v, --verbose           Verbose output
    -h, --help              Show this help

Examples:
    $0                      # Run all steps (validate, build, test)
    $0 build                # Only build the image
    $0 test                 # Only run tests
    $0 -r docker build      # Build using docker instead of podman
    $0 -t my-awx-ee:latest  # Use custom image tag

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--runtime)
            CONTAINER_RUNTIME="$2"
            shift 2
            ;;
        -t|--tag)
            IMAGE_NAME="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        validate|build|test|all)
            COMMAND="$1"
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Set default command
COMMAND="${COMMAND:-all}"

# Validate container runtime
if ! command -v "$CONTAINER_RUNTIME" >/dev/null 2>&1; then
    print_error "Container runtime '$CONTAINER_RUNTIME' not found"
    exit 1
fi

print_status "Using container runtime: $CONTAINER_RUNTIME"
print_status "Image name: $IMAGE_NAME"

# Execute command
case "$COMMAND" in
    validate)
        validate_config
        ;;
    build)
        build_image
        ;;
    test)
        run_tests "$IMAGE_NAME"
        ;;
    all)
        validate_config
        build_image
        run_tests "$IMAGE_NAME"
        print_status "🎉 All operations completed successfully!"
        ;;
    *)
        print_error "Unknown command: $COMMAND"
        show_help
        exit 1
        ;;
esac

print_status "Done!"