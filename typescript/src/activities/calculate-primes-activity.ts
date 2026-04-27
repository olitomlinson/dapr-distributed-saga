import { WorkflowActivityContext } from "@dapr/dapr";
import { PrimeInput, PrimeOutput } from "../models/prime-models.js";

function calculatePrimes(maxNumber: number): number[] {
  if (maxNumber < 2) {
    return [];
  }

  // Sieve of Eratosthenes
  const isPrime: boolean[] = new Array(maxNumber + 1).fill(true);
  isPrime[0] = false;
  isPrime[1] = false;

  const sqrtMax = Math.floor(Math.sqrt(maxNumber));
  for (let i = 2; i <= sqrtMax; i++) {
    if (isPrime[i]) {
      for (let j = i * i; j <= maxNumber; j += i) {
        isPrime[j] = false;
      }
    }
  }

  const primes: number[] = [];
  for (let i = 2; i <= maxNumber; i++) {
    if (isPrime[i]) {
      primes.push(i);
    }
  }

  return primes;
}

export async function calculatePrimesActivity(
  ctx: WorkflowActivityContext,
  input: PrimeInput
): Promise<PrimeOutput> {
  const startTime = Date.now();

  const primes = calculatePrimes(input.maxNumber);

  const calculationTimeMs = Date.now() - startTime;

  const output: PrimeOutput = {
    primes,
    count: primes.length,
    maxNumber: input.maxNumber,
    calculationTimeMs,
  };

  console.log(
    `CalculatePrimesActivity: found ${output.count} primes up to ${output.maxNumber} in ${output.calculationTimeMs}ms`
  );

  return output;
}
