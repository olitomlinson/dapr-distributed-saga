#!/bin/bash

set -e

echo "=========================================="
echo "Dapr Multi-Language Workflow Test Script"
echo "=========================================="
echo ""

# Parse command line flags
RUN_GO=false
RUN_PYTHON=false
RUN_JAVA=false
RUN_DOTNET=false
RUN_TYPESCRIPT=false

# If no flags provided, run all
if [ $# -eq 0 ]; then
    RUN_GO=true
    RUN_PYTHON=true
    RUN_JAVA=true
    RUN_DOTNET=true
    RUN_TYPESCRIPT=true
else
    # Parse flags
    while [[ $# -gt 0 ]]; do
        case $1 in
            --go)
                RUN_GO=true
                shift
                ;;
            --python)
                RUN_PYTHON=true
                shift
                ;;
            --java)
                RUN_JAVA=true
                shift
                ;;
            --dotnet)
                RUN_DOTNET=true
                shift
                ;;
            --typescript)
                RUN_TYPESCRIPT=true
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [--go] [--python] [--java] [--dotnet] [--typescript]"
                echo ""
                echo "Options:"
                echo "  --go         Run Go workflow"
                echo "  --python     Run Python workflow"
                echo "  --java       Run Java workflow"
                echo "  --dotnet     Run .NET workflow"
                echo "  --typescript Run TypeScript workflow"
                echo ""
                echo "If no options are provided, all workflows will run."
                echo ""
                echo "Examples:"
                echo "  $0                          # Run all workflows"
                echo "  $0 --python --java          # Run only Python and Java"
                echo "  $0 --go --typescript        # Run only Go and TypeScript"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
fi

# Configuration
TIMESTAMP=$(date +%s)
MAX_NUMBER=100

# Dapr sidecar ports
GO_PORT=3500
PYTHON_PORT=3501
JAVA_PORT=3502
DOTNET_PORT=3503
TYPESCRIPT_PORT=3505

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to schedule a workflow
schedule_workflow() {
    local lang=$1
    local port=$2
    local instance_id="primes-${lang}-${TIMESTAMP}"

    echo -e "${BLUE}Scheduling workflow on ${lang}...${NC}" >&2

    response=$(curl -s -X POST \
        "http://localhost:${port}/v1.0/workflows/dapr/PrimeWorkflow/start?instanceID=${instance_id}" \
        -H "Content-Type: application/json" \
        -d "{
                \"maxNumber\": ${MAX_NUMBER}
            }")

    echo -e "${GREEN}✓ Workflow scheduled: ${instance_id}${NC}" >&2
    echo "$instance_id:$port"
}

# Function to get workflow status
get_workflow_status() {
    local instance_id=$1
    local port=$2

    curl -s "http://localhost:${port}/v1.0/workflows/dapr/${instance_id}"
}

# Function to wait for workflow completion
wait_for_completion() {
    local instance_id=$1
    local port=$2
    local lang=$3
    local max_attempts=30
    local attempt=0

    echo -e "${YELLOW}Waiting for ${lang} workflow to complete...${NC}" >&2

    while [ $attempt -lt $max_attempts ]; do
        status=$(get_workflow_status "$instance_id" "$port" | jq -r '.runtimeStatus // "UNKNOWN"')

        if [ "$status" == "COMPLETED" ]; then
            echo -e "${GREEN}✓ ${lang} workflow completed${NC}" >&2
            return 0
        elif [ "$status" == "FAILED" ]; then
            echo -e "${RED}✗ ${lang} workflow failed${NC}" >&2
            return 1
        fi

        sleep 2
        ((attempt++))
    done

    echo -e "${RED}✗ ${lang} workflow timed out${NC}" >&2
    return 1
}

# Function to display results
display_results() {
    local instance_id=$1
    local port=$2
    local lang=$3

    echo ""
    echo -e "${BLUE}=== ${lang} Results ===${NC}"

    result=$(get_workflow_status "$instance_id" "$port")

    count=$(echo "$result" | jq -r '.properties."dapr.workflow.output" | fromjson | .count // 0')
    time_ms=$(echo "$result" | jq -r '.properties."dapr.workflow.output" | fromjson | .calculationTimeMs // 0')
    primes=$(echo "$result" | jq -r '.properties."dapr.workflow.output" | fromjson | .primes[0:10] // [] | @json')

    echo "Instance ID: $instance_id"
    echo "Prime count: $count"
    echo "Calculation time: ${time_ms}ms"
    echo "First 10 primes: $primes"
}

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is not installed. Please install jq to run this script.${NC}"
    echo "  macOS: brew install jq"
    echo "  Linux: sudo apt-get install jq"
    exit 1
fi

# Show which workflows will run
RUNNING_LANGS=()
$RUN_GO && RUNNING_LANGS+=("Go")
$RUN_PYTHON && RUNNING_LANGS+=("Python")
$RUN_JAVA && RUNNING_LANGS+=("Java")
$RUN_DOTNET && RUNNING_LANGS+=(".NET")
$RUN_TYPESCRIPT && RUNNING_LANGS+=("TypeScript")

echo "Scheduling workflows for: ${RUNNING_LANGS[*]}"
echo ""

# Schedule workflows
if [ "$RUN_GO" = true ]; then
    GO_INSTANCE=$(schedule_workflow "go" "$GO_PORT")
fi

if [ "$RUN_PYTHON" = true ]; then
    PYTHON_INSTANCE=$(schedule_workflow "python" "$PYTHON_PORT")
fi

if [ "$RUN_JAVA" = true ]; then
    JAVA_INSTANCE=$(schedule_workflow "java" "$JAVA_PORT")
fi

if [ "$RUN_DOTNET" = true ]; then
    DOTNET_INSTANCE=$(schedule_workflow "dotnet" "$DOTNET_PORT")
fi

if [ "$RUN_TYPESCRIPT" = true ]; then
    TYPESCRIPT_INSTANCE=$(schedule_workflow "typescript" "$TYPESCRIPT_PORT")
fi

echo ""
echo "All workflows scheduled. Waiting for completion..."
echo ""

# Parse instance IDs and ports
if [ "$RUN_GO" = true ]; then
    GO_ID=$(echo "$GO_INSTANCE" | cut -d':' -f1)
    GO_P=$(echo "$GO_INSTANCE" | cut -d':' -f2)
fi

if [ "$RUN_PYTHON" = true ]; then
    PYTHON_ID=$(echo "$PYTHON_INSTANCE" | cut -d':' -f1)
    PYTHON_P=$(echo "$PYTHON_INSTANCE" | cut -d':' -f2)
fi

if [ "$RUN_JAVA" = true ]; then
    JAVA_ID=$(echo "$JAVA_INSTANCE" | cut -d':' -f1)
    JAVA_P=$(echo "$JAVA_INSTANCE" | cut -d':' -f2)
fi

if [ "$RUN_DOTNET" = true ]; then
    DOTNET_ID=$(echo "$DOTNET_INSTANCE" | cut -d':' -f1)
    DOTNET_P=$(echo "$DOTNET_INSTANCE" | cut -d':' -f2)
fi

if [ "$RUN_TYPESCRIPT" = true ]; then
    TYPESCRIPT_ID=$(echo "$TYPESCRIPT_INSTANCE" | cut -d':' -f1)
    TYPESCRIPT_P=$(echo "$TYPESCRIPT_INSTANCE" | cut -d':' -f2)
fi

# Wait for all workflows to complete
if [ "$RUN_GO" = true ]; then
    wait_for_completion "$GO_ID" "$GO_P" "Go"
fi

if [ "$RUN_PYTHON" = true ]; then
    wait_for_completion "$PYTHON_ID" "$PYTHON_P" "Python"
fi

if [ "$RUN_JAVA" = true ]; then
    wait_for_completion "$JAVA_ID" "$JAVA_P" "Java"
fi

if [ "$RUN_DOTNET" = true ]; then
    wait_for_completion "$DOTNET_ID" "$DOTNET_P" ".NET"
fi

if [ "$RUN_TYPESCRIPT" = true ]; then
    wait_for_completion "$TYPESCRIPT_ID" "$TYPESCRIPT_P" "TypeScript"
fi

echo ""
echo "=========================================="
echo "              RESULTS"
echo "=========================================="

# Display results for all workflows
if [ "$RUN_GO" = true ]; then
    display_results "$GO_ID" "$GO_P" "Go"
fi

if [ "$RUN_PYTHON" = true ]; then
    display_results "$PYTHON_ID" "$PYTHON_P" "Python"
fi

if [ "$RUN_JAVA" = true ]; then
    display_results "$JAVA_ID" "$JAVA_P" "Java"
fi

if [ "$RUN_DOTNET" = true ]; then
    display_results "$DOTNET_ID" "$DOTNET_P" ".NET"
fi

if [ "$RUN_TYPESCRIPT" = true ]; then
    display_results "$TYPESCRIPT_ID" "$TYPESCRIPT_P" "TypeScript"
fi

echo ""
echo -e "${GREEN}=========================================="
echo "All workflows completed successfully!"
echo -e "==========================================${NC}"
echo ""
echo "View detailed results in Diagrid Dashboard: http://localhost:8080"
