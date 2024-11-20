#!/bin/bash

# Set colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Default thresholds
CPU_THRESHOLD=80
MEMORY_THRESHOLD=80
MAX_REPLICAS=10
MIN_REPLICAS=2
CHECK_INTERVAL=30  # seconds

# Print functions
print_info() {
    echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Function to check prerequisites
check_prerequisites() {
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed"
        exit 1
    fi

    # Check bc (for floating point arithmetic)
    if ! command -v bc &> /dev/null; then
        print_error "bc is not installed. Please install bc package."
        exit 1
    }
}

# Function to validate deployment
validate_deployment() {
    local namespace=$1
    local deployment=$2

    if ! kubectl get deployment "$deployment" -n "$namespace" &> /dev/null; then
        print_error "Deployment '$deployment' does not exist in namespace '$namespace'"
        exit 1
    fi
}

# Function to get current CPU usage percentage
get_cpu_usage() {
    local namespace=$1
    local deployment=$2
    
    # Get CPU usage for all pods in deployment
    local cpu_usage=$(kubectl top pods -n "$namespace" | grep "$deployment" | awk '{sum+=$2} END {print sum/NR}')
    echo "${cpu_usage:-0}"
}

# Function to get current memory usage percentage
get_memory_usage() {
    local namespace=$1
    local deployment=$2
    
    # Get memory usage for all pods in deployment
    local memory_usage=$(kubectl top pods -n "$namespace" | grep "$deployment" | awk '{sum+=$3} END {print sum/NR}')
    echo "${memory_usage:-0}"
}

# Function to get current replica count
get_replica_count() {
    local namespace=$1
    local deployment=$2
    
    kubectl get deployment "$deployment" -n "$namespace" -o jsonpath='{.spec.replicas}'
}

# Function to scale deployment
scale_deployment() {
    local namespace=$1
    local deployment=$2
    local replicas=$3
    
    print_info "Scaling deployment '$deployment' to $replicas replicas"
    kubectl scale deployment "$deployment" --replicas="$replicas" -n "$namespace"
    
    # Wait for scaling to complete
    kubectl rollout status deployment/"$deployment" -n "$namespace" --timeout=2m
}

# Function to log metrics to file
log_metrics() {
    local namespace=$1
    local deployment=$2
    local cpu=$3
    local memory=$4
    local replicas=$5
    local log_file="metrics_${namespace}_${deployment}.log"

    echo "$(date '+%Y-%m-%d %H:%M:%S') CPU: ${cpu}% Memory: ${memory}% Replicas: ${replicas}" >> "$log_file"
}

# Function to create monitoring dashboard using metrics
create_dashboard() {
    local namespace=$1
    local deployment=$2
    local log_file="metrics_${namespace}_${deployment}.log"
    
    print_info "Current Metrics Summary:"
    echo "----------------------------------------"
    echo "Last 5 measurements:"
    tail -n 5 "$log_file"
    echo "----------------------------------------"
}

# Main monitoring and auto-scaling logic
monitor_and_scale() {
    local namespace=$1
    local deployment=$2
    
    print_info "Starting automatic monitoring and scaling for $deployment in namespace $namespace"
    print_info "CPU Threshold: ${CPU_THRESHOLD}%"
    print_info "Memory Threshold: ${MEMORY_THRESHOLD}%"
    print_info "Min Replicas: $MIN_REPLICAS"
    print_info "Max Replicas: $MAX_REPLICAS"
    print_info "Check Interval: ${CHECK_INTERVAL}s"
    
    while true; do
        # Get current metrics
        local cpu_usage=$(get_cpu_usage "$namespace" "$deployment")
        local memory_usage=$(get_memory_usage "$namespace" "$deployment")
        local current_replicas=$(get_replica_count "$namespace" "$deployment")
        
        # Log metrics
        log_metrics "$namespace" "$deployment" "$cpu_usage" "$memory_usage" "$current_replicas"
        
        # Create dashboard
        create_dashboard "$namespace" "$deployment"
        
        # Check if scaling is needed
        if (( $(echo "$cpu_usage > $CPU_THRESHOLD" | bc -l) )) || (( $(echo "$memory_usage > $MEMORY_THRESHOLD" | bc -l) )); then
            if [ "$current_replicas" -lt "$MAX_REPLICAS" ]; then
                print_warning "High resource usage detected! CPU: ${cpu_usage}%, Memory: ${memory_usage}%"
                local new_replicas=$((current_replicas + 1))
                scale_deployment "$namespace" "$deployment" "$new_replicas"
            else
                print_warning "Max replicas reached, cannot scale up further"
            fi
        elif (( $(echo "$cpu_usage < $((CPU_THRESHOLD/2))" | bc -l) )) && (( $(echo "$memory_usage < $((MEMORY_THRESHOLD/2))" | bc -l) )); then
            if [ "$current_replicas" -gt "$MIN_REPLICAS" ]; then
                print_info "Low resource usage detected, scaling down"
                local new_replicas=$((current_replicas - 1))
                scale_deployment "$namespace" "$deployment" "$new_replicas"
            fi
        else
            print_info "Resource usage within normal range. CPU: ${cpu_usage}%, Memory: ${memory_usage}%"
        fi
        
        sleep "$CHECK_INTERVAL"
    done
}

# Main script
main() {
    # Check prerequisites
    check_prerequisites
    
    # Get deployment details
    read -p "Enter namespace: " namespace
    read -p "Enter deployment name: " deployment
    
    # Validate deployment
    validate_deployment "$namespace" "$deployment"
    
    # Optional: Configure thresholds
    read -p "Enter CPU threshold % (default ${CPU_THRESHOLD}): " custom_cpu
    read -p "Enter Memory threshold % (default ${MEMORY_THRESHOLD}): " custom_memory
    read -p "Enter minimum replicas (default ${MIN_REPLICAS}): " custom_min
    read -p "Enter maximum replicas (default ${MAX_REPLICAS}): " custom_max
    read -p "Enter check interval in seconds (default ${CHECK_INTERVAL}): " custom_interval
    
    # Set custom values if provided
    CPU_THRESHOLD=${custom_cpu:-$CPU_THRESHOLD}
    MEMORY_THRESHOLD=${custom_memory:-$MEMORY_THRESHOLD}
    MIN_REPLICAS=${custom_min:-$MIN_REPLICAS}
    MAX_REPLICAS=${custom_max:-$MAX_REPLICAS}
    CHECK_INTERVAL=${custom_interval:-$CHECK_INTERVAL}
    
    # Start monitoring and auto-scaling
    monitor_and_scale "$namespace" "$deployment"
}

# Run script
main