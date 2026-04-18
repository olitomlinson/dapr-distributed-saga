#!/bin/bash

set -e

echo "=========================================="
echo "Dapr Saga Orchestrator Workflow Test"
echo "=========================================="
echo ""

# Configuration
TIMESTAMP=$(date +%s)
MAX_NUMBER=${1:-100}  # Default to 100, or use first argument

# Saga orchestrator app port
SAGA_PORT=8085

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is not installed. Please install jq to run this script.${NC}"
    echo "  macOS: brew install jq"
    echo "  Linux: sudo apt-get install jq"
    exit 1
fi

echo "Testing Saga Orchestrator with maxNumber=${MAX_NUMBER}"
echo ""

# Schedule saga workflow
echo -e "${BLUE}Starting saga orchestrator workflow...${NC}"

response=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X POST \
    "http://localhost:${SAGA_PORT}/saga/start" \
    -H "Content-Type: application/json" \
    -d "{
            \"maxNumber\": ${MAX_NUMBER},
            \"app_ids\": [\"primes-go\", \"primes-python\", \"primes-java\", \"primes-dotnet\"]
        }")

# Extract HTTP status and body
http_status=$(echo "$response" | grep "HTTP_STATUS:" | cut -d: -f2)
body=$(echo "$response" | sed '/HTTP_STATUS:/d')

# Check if request was successful
if [ "$http_status" != "200" ]; then
    echo -e "${RED}✗ Failed to start saga workflow (HTTP ${http_status})${NC}"
    echo "Response:"
    echo "$body" | jq '.' 2>/dev/null || echo "$body"
    exit 1
fi

INSTANCE_ID=$(echo "$body" | jq -r '.instance_id')

if [ -z "$INSTANCE_ID" ] || [ "$INSTANCE_ID" = "null" ]; then
    echo -e "${RED}✗ Failed to get instance ID from response${NC}"
    echo "Response:"
    echo "$body" | jq '.'
    exit 1
fi

echo -e "${GREEN}✓ Saga workflow started: ${INSTANCE_ID}${NC}"
echo ""

# Wait for completion
echo -e "${YELLOW}Waiting for saga orchestrator to complete...${NC}"

max_attempts=60
attempt=0

while [ $attempt -lt $max_attempts ]; do
    status=$(curl -s "http://localhost:${SAGA_PORT}/saga/status/${INSTANCE_ID}" | jq -r '.runtime_status // "UNKNOWN"')

    if [ "$status" = "COMPLETED" ]; then
        echo -e "${GREEN}✓ Saga orchestrator completed${NC}"
        break
    elif [ "$status" = "FAILED" ]; then
        echo -e "${RED}✗ Saga orchestrator failed${NC}"
        echo ""
        echo "Error details:"
        curl -s "http://localhost:${SAGA_PORT}/saga/status/${INSTANCE_ID}" | jq '.'
        exit 1
    fi

    echo -n "."
    sleep 2
    ((attempt++))
done

if [ $attempt -ge $max_attempts ]; then
    echo ""
    echo -e "${RED}✗ Saga orchestrator timed out${NC}"
    exit 1
fi

echo ""
echo ""
echo "=========================================="
echo "              RESULTS"
echo "=========================================="
echo ""

# Get full result
result=$(curl -s "http://localhost:${SAGA_PORT}/saga/status/${INSTANCE_ID}")

# Parse output - use the parsed output field
output=$(echo "$result" | jq '.output')

# Extract summary statistics
total_executions=$(echo "$output" | jq -r '.totalExecutions // 0')
successful_executions=$(echo "$output" | jq -r '.successfulExecutions // 0')
all_completed=$(echo "$output" | jq -r '.allCompleted // false')
total_primes=$(echo "$output" | jq -r '.totalPrimesFound // 0')
total_time=$(echo "$output" | jq -r '.totalCalculationTimeMs // 0')
avg_time=$(echo "$output" | jq -r '.averageCalculationTimeMs // 0')

echo "Instance ID: ${INSTANCE_ID}"
echo "Total Executions: ${total_executions}"
echo "Successful Executions: ${successful_executions}"
echo "All Completed: ${all_completed}"
echo "Total Primes Found: ${total_primes}"
echo "Total Calculation Time: ${total_time}ms"
echo "Average Calculation Time: ${avg_time}ms"
echo ""

# Show individual app results
echo -e "${BLUE}=== Individual App Results ===${NC}"
echo ""

# Get all app IDs from the results object
app_ids=$(echo "$output" | jq -r '.results | keys[]')

# Iterate over actual app IDs
for app_id in $app_ids; do
    app_result=$(echo "$output" | jq ".results.\"${app_id}\" // null")

    if [ "$app_result" != "null" ]; then
        count=$(echo "$app_result" | jq -r '.count // 0')
        time_ms=$(echo "$app_result" | jq -r '.calculationTimeMs // 0')
        primes=$(echo "$app_result" | jq -r '.primes[0:10] // [] | @json')

        echo -e "${GREEN}✓ ${app_id}:${NC}"
        echo "  Prime count: ${count}"
        echo "  Calculation time: ${time_ms}ms"
        echo "  First 10 primes: ${primes}"
        echo ""
    else
        echo -e "${RED}✗ ${app_id}: No result${NC}"
        echo ""
    fi
done

echo -e "${GREEN}=========================================="
echo "Saga orchestrator completed successfully!"
echo -e "==========================================${NC}"
echo ""
echo "View detailed workflow execution in Diagrid Dashboard: http://localhost:8080"
