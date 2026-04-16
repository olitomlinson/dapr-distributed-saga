using Dapr.Workflow;
using PrimeWorkflowApp.Activities;
using PrimeWorkflowApp.Models;

namespace PrimeWorkflowApp.Workflows;

public class PrimeWorkflow : Workflow<PrimeInput, PrimeOutput>
{
    public override async Task<PrimeOutput> RunAsync(WorkflowContext context, PrimeInput input)
    {
        var logger = context.CreateReplaySafeLogger<PrimeWorkflow>();
        logger.LogInformation("PrimeWorkflow started with maxNumber={MaxNumber}", input.MaxNumber);

        // context.SetCustomStatus("Waiting for approval...");

        // bool approval = await context.WaitForExternalEventAsync<bool>("approval-event");
        // if (!approval)
        //     throw new Exception("not approved!");

        var output = await context.CallActivityAsync<PrimeOutput>(
            "CalculatePrimesActivity",
            input
        );

        // var output = await context.CallActivityAsync<PrimeOutput>(
        //     "CalculatePrimesActivity",
        //     input,
        //     new WorkflowTaskOptions { TargetAppId = "primes-python" }
        // );

        logger.LogInformation("PrimeWorkflow completed: found {Count} primes", output.Count);


        return output;
    }
}
