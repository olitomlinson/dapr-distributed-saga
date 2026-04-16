namespace PrimeWorkflowApp.Models;

public record PrimeInput(int MaxNumber);

public record PrimeOutput(
    int[] Primes,
    int Count,
    int MaxNumber,
    long CalculationTimeMs
);
