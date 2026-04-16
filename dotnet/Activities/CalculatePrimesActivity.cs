using Dapr.Workflow;
using PrimeWorkflowApp.Models;

namespace PrimeWorkflowApp.Activities;

public class CalculatePrimesActivity : WorkflowActivity<PrimeInput, PrimeOutput>
{
    private readonly ILogger<CalculatePrimesActivity> _logger;

    public CalculatePrimesActivity(ILogger<CalculatePrimesActivity> logger)
    {
        _logger = logger;
    }

    public override Task<PrimeOutput> RunAsync(WorkflowActivityContext context, PrimeInput input)
    {
        var startTime = DateTimeOffset.UtcNow;

        var primes = CalculatePrimes(input.MaxNumber);

        var calculationTimeMs = (DateTimeOffset.UtcNow - startTime).TotalMilliseconds;

        var output = new PrimeOutput(
            Primes: primes,
            Count: primes.Length,
            MaxNumber: input.MaxNumber,
            CalculationTimeMs: (long)calculationTimeMs
        );

        _logger.LogInformation(
            "CalculatePrimesActivity: found {Count} primes up to {MaxNumber} in {TimeMs}ms",
            output.Count, output.MaxNumber, output.CalculationTimeMs
        );

        return Task.FromResult(output);
    }

    private static int[] CalculatePrimes(int maxNumber)
    {
        if (maxNumber < 2)
        {
            return Array.Empty<int>();
        }

        // Sieve of Eratosthenes
        var isPrime = new bool[maxNumber + 1];
        Array.Fill(isPrime, true);
        isPrime[0] = false;
        isPrime[1] = false;

        var sqrtMax = (int)Math.Sqrt(maxNumber);
        for (var i = 2; i <= sqrtMax; i++)
        {
            if (isPrime[i])
            {
                for (var j = i * i; j <= maxNumber; j += i)
                {
                    isPrime[j] = false;
                }
            }
        }

        var primes = new List<int>();
        for (var i = 2; i <= maxNumber; i++)
        {
            if (isPrime[i])
            {
                primes.Add(i);
            }
        }

        return primes.ToArray();
    }
}
