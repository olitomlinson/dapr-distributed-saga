import logging
import math
import time
from typing import List
from datetime import timedelta

import dapr.ext.workflow as wf
from dapr.ext.workflow import WorkflowRuntime, DaprWorkflowContext, WorkflowActivityContext
from fastapi import FastAPI
from pydantic import BaseModel

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create FastAPI app
app = FastAPI()

# Create workflow runtime
wfr = WorkflowRuntime()

# Data models
class PrimeInput(BaseModel):
    maxNumber: int

class PrimeOutput(BaseModel):
    primes: List[int]
    count: int
    maxNumber: int
    calculationTimeMs: int

# Workflow definition
@wfr.workflow(name='PrimeWorkflow')
def prime_workflow(ctx: DaprWorkflowContext, input_data: dict):
    """Prime number calculation workflow"""
    # Convert dict to PrimeInput if needed
    if isinstance(input_data, dict):
        input_obj = PrimeInput(**input_data)
    else:
        input_obj = input_data

    logger.info(f"PrimeWorkflow started with maxNumber={input_obj.maxNumber}")

    # Pass as dict to activity (Pydantic model needs to be serialized)
    result = yield ctx.call_activity("CalculatePrimesActivity", input=input_obj.model_dump())

    logger.info(f"PrimeWorkflow completed: found {result['count']} primes")
    # Return as dict (result is already a dict from activity)
    return result

# Activity definition
@wfr.activity(name='CalculatePrimesActivity')
def calculate_primes_activity(ctx: WorkflowActivityContext, input_data) -> PrimeOutput:
    """Calculate prime numbers using Sieve of Eratosthenes"""
    # Convert dict to PrimeInput if needed
    if isinstance(input_data, dict):
        input_obj = PrimeInput(**input_data)
    elif isinstance(input_data, PrimeInput):
        input_obj = input_data
    else:
        input_obj = input_data  # Fallback

    start_time = time.time()

    primes = calculate_primes(input_obj.maxNumber)

    calculation_time_ms = int((time.time() - start_time) * 1000)

    output = PrimeOutput(
        primes=primes,
        count=len(primes),
        maxNumber=input_obj.maxNumber,
        calculationTimeMs=calculation_time_ms
    )

    logger.info(f"CalculatePrimesActivity: found {output.count} primes up to {output.maxNumber} in {output.calculationTimeMs}ms")

    # Return as dict for serialization
    return output.model_dump()

def calculate_primes(max_number: int) -> List[int]:
    """Sieve of Eratosthenes algorithm"""
    if max_number < 2:
        return []

    # Initialize boolean array
    is_prime = [True] * (max_number + 1)
    is_prime[0] = False
    is_prime[1] = False

    # Sieve of Eratosthenes
    sqrt_max = int(math.sqrt(max_number))
    for i in range(2, sqrt_max + 1):
        if is_prime[i]:
            for j in range(i * i, max_number + 1, i):
                is_prime[j] = False

    # Collect primes
    primes = [i for i in range(2, max_number + 1) if is_prime[i]]

    return primes

# FastAPI endpoints
@app.get("/health")
def health():
    """Health check endpoint"""
    return {"status": "healthy"}

@app.on_event("startup")
async def startup_event():
    """Start the workflow runtime on app startup"""
    logger.info("Starting workflow runtime...")
    wfr.start()
    logger.info("Workflow runtime started successfully")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
