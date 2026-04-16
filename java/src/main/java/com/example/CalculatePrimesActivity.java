package com.example;

import io.dapr.workflows.WorkflowActivity;
import io.dapr.workflows.WorkflowActivityContext;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.List;

public class CalculatePrimesActivity implements WorkflowActivity {
    private static final Logger logger = LoggerFactory.getLogger(CalculatePrimesActivity.class);

    @Override
    public Object run(WorkflowActivityContext ctx) {
        logger.info("Starting Activity: {}", ctx.getName());

        PrimeInput input = ctx.getInput(PrimeInput.class);
        long startTime = System.currentTimeMillis();

        List<Integer> primes = calculatePrimes(input.getMaxNumber());

        long calculationTimeMs = System.currentTimeMillis() - startTime;

        PrimeOutput output = new PrimeOutput(
                primes,
                primes.size(),
                input.getMaxNumber(),
                calculationTimeMs
        );

        logger.info("CalculatePrimesActivity: found {} primes up to {} in {}ms",
                output.getCount(), output.getMaxNumber(), output.getCalculationTimeMs());

        return output;
    }

    private List<Integer> calculatePrimes(int maxNumber) {
        if (maxNumber < 2) {
            return new ArrayList<>();
        }

        // Sieve of Eratosthenes
        boolean[] isPrime = new boolean[maxNumber + 1];
        for (int i = 0; i <= maxNumber; i++) {
            isPrime[i] = true;
        }
        isPrime[0] = false;
        isPrime[1] = false;

        int sqrtMax = (int) Math.sqrt(maxNumber);
        for (int i = 2; i <= sqrtMax; i++) {
            if (isPrime[i]) {
                for (int j = i * i; j <= maxNumber; j += i) {
                    isPrime[j] = false;
                }
            }
        }

        List<Integer> primes = new ArrayList<>();
        for (int i = 2; i <= maxNumber; i++) {
            if (isPrime[i]) {
                primes.add(i);
            }
        }

        return primes;
    }
}
