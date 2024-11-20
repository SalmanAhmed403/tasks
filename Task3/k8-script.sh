#!/bin/bash

# Set colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if kubectl is installed
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install it first."
        exit 1
    fi
}

# Function to check if namespace exists
check_namespace() {
    local namespace=$1
    if ! kubectl get namespace "$namespace" &> /dev/null; then
        print_error "Namespace '$namespace' does not exist!"
        return 1
    fi
    return 0
}

# Function to check if pod exists
check_pod() {
    local namespace=$1
    local pod_name=$2
    if ! kubectl get pod "$pod_name" -n "$namespace" &> /dev/null; then
        print_error "Pod '$pod_name' does not exist in namespace '$namespace'!"
        return 1
    fi
    return 0
}

# Function to gather pod information
gather_pod_info() {
    local namespace=$1
    local pod_name=$2
    local output_dir=$3

    print_info "Gathering information for pod '$pod_name' in namespace '$namespace'..."
    
    # Create output directory
    mkdir -p "$output_dir"
    
    # Get pod details
    kubectl get pod "$pod_name" -n "$namespace" -o yaml > "$output_dir/pod-details.yaml"
    
    # Get pod description
    kubectl describe pod "$pod_name" -n "$namespace" > "$output_dir/pod-description.txt"
    
    # Get pod logs
    kubectl logs "$pod_name" -n "$namespace" --all-containers=true --previous > "$output_dir/previous-logs.txt" 2>/dev/null
    kubectl logs "$pod_name" -n "$namespace" --all-containers=true > "$output_dir/current-logs.txt" 2>/dev/null
    
    # Get pod events
    kubectl get events -n "$namespace" --field-selector "involvedObject.name=$pod_name" > "$output_dir/pod-events.txt"
    
    # Get node information
    NODE_NAME=$(kubectl get pod "$pod_name" -n "$namespace" -o jsonpath='{.spec.nodeName}')
    if [ ! -z "$NODE_NAME" ]; then
        kubectl describe node "$NODE_NAME" > "$output_dir/node-info.txt"
    fi
}

# Main script
main() {
    # Check prerequisites
    check_kubectl

    # Get user input
    read -p "Enter namespace: " namespace
    check_namespace "$namespace" || exit 1

    read -p "Enter pod name: " pod_name
    check_pod "$namespace" "$pod_name" || exit 1

    # Create output directory with timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    output_dir="k8s_troubleshoot_${namespace}_${pod_name}_${timestamp}"

    # Gather information
    gather_pod_info "$namespace" "$pod_name" "$output_dir"

    # Display pod status
    print_info "Current pod status:"
    kubectl get pod "$pod_name" -n "$namespace"

    # Check for common issues
    status=$(kubectl get pod "$pod_name" -n "$namespace" -o jsonpath='{.status.phase}')
    restart_count=$(kubectl get pod "$pod_name" -n "$namespace" -o jsonpath='{.status.containerStatuses[0].restartCount}')

    if [ "$status" != "Running" ]; then
        print_warning "Pod is not in Running state. Current state: $status"
        print_info "Check $output_dir/pod-description.txt for more details"
    fi

    if [ "$restart_count" -gt 0 ]; then
        print_warning "Pod has restarted $restart_count times"
        print_info "Check $output_dir/previous-logs.txt for logs from previous crashes"
    fi

    print_info "All troubleshooting information has been saved to: $output_dir"
    print_info "Review the following files:"
    echo "- $output_dir/pod-details.yaml (Pod configuration)"
    echo "- $output_dir/pod-description.txt (Pod description)"
    echo "- $output_dir/current-logs.txt (Current container logs)"
    echo "- $output_dir/previous-logs.txt (Previous container logs)"
    echo "- $output_dir/pod-events.txt (Pod events)"
    echo "- $output_dir/node-info.txt (Node information)"
}

 #Run main function
main