package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"math"
	"net/http"
	"os"
	"time"

	"github.com/dapr/durabletask-go/workflow"
	"github.com/dapr/go-sdk/client"
)

type PrimeInput struct {
	MaxNumber int `json:"maxNumber"`
}

type PrimeOutput struct {
	Primes            []int `json:"primes"`
	Count             int   `json:"count"`
	MaxNumber         int   `json:"maxNumber"`
	CalculationTimeMs int64 `json:"calculationTimeMs"`
}

func main() {
	r := workflow.NewRegistry()

	if err := r.AddWorkflow(PrimeWorkflow); err != nil {
		log.Fatal(err)
	}
	log.Println("PrimeWorkflow registered")

	if err := r.AddActivity(CalculatePrimesActivity); err != nil {
		log.Fatal(err)
	}
	log.Println("CalculatePrimesActivity registered")

	wclient, err := client.NewWorkflowClient()
	if err != nil {
		log.Fatal(err)
	}
	log.Println("Workflow client initialized")

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	if err = wclient.StartWorker(ctx, r); err != nil {
		log.Fatal(err)
	}
	log.Println("Workflow worker started")

	// Start HTTP server for health checks
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(map[string]string{"status": "healthy"})
	})

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Starting HTTP server on port %s", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatal(err)
	}
}

func PrimeWorkflow(ctx *workflow.WorkflowContext) (any, error) {
	var input PrimeInput
	if err := ctx.GetInput(&input); err != nil {
		return nil, fmt.Errorf("failed to get workflow input: %w", err)
	}

	log.Printf("PrimeWorkflow started with maxNumber=%d", input.MaxNumber)

	var output PrimeOutput
	err := ctx.CallActivity("CalculatePrimesActivity", workflow.WithActivityInput(input)).Await(&output)
	if err != nil {
		return nil, fmt.Errorf("failed to call CalculatePrimesActivity: %w", err)
	}

	log.Printf("PrimeWorkflow completed: found %d primes", output.Count)
	return output, nil
}

func CalculatePrimesActivity(ctx workflow.ActivityContext) (any, error) {
	var input PrimeInput
	if err := ctx.GetInput(&input); err != nil {
		return nil, fmt.Errorf("failed to get activity input: %w", err)
	}

	startTime := time.Now()

	primes := calculatePrimes(input.MaxNumber)

	calculationTime := time.Since(startTime).Milliseconds()

	output := PrimeOutput{
		Primes:            primes,
		Count:             len(primes),
		MaxNumber:         input.MaxNumber,
		CalculationTimeMs: calculationTime,
	}

	log.Printf("CalculatePrimesActivity: found %d primes up to %d in %dms",
		output.Count, output.MaxNumber, output.CalculationTimeMs)

	return output, nil
}

func calculatePrimes(maxNumber int) []int {
	if maxNumber < 2 {
		return []int{}
	}

	// Sieve of Eratosthenes
	isPrime := make([]bool, maxNumber+1)
	for i := range isPrime {
		isPrime[i] = true
	}
	isPrime[0] = false
	isPrime[1] = false

	sqrtMax := int(math.Sqrt(float64(maxNumber)))
	for i := 2; i <= sqrtMax; i++ {
		if isPrime[i] {
			for j := i * i; j <= maxNumber; j += i {
				isPrime[j] = false
			}
		}
	}

	primes := []int{}
	for i := 2; i <= maxNumber; i++ {
		if isPrime[i] {
			primes = append(primes, i)
		}
	}

	return primes
}
