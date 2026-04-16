using Dapr.Workflow;
using PrimeWorkflowApp.Activities;
using PrimeWorkflowApp.Models;
using PrimeWorkflowApp.Workflows;

var builder = WebApplication.CreateBuilder(args);

// Add Dapr Workflow services
builder.Services.AddDaprWorkflow(options =>
{
    options.RegisterWorkflow<PrimeWorkflow>();
    options.RegisterActivity<CalculatePrimesActivity>(name: "CalculatePrimesActivity");
});

var app = builder.Build();

// Health check endpoint
app.MapGet("/health", () => Results.Ok(new { status = "healthy" }));

app.Logger.LogInformation("Starting Dapr Prime Workflow Application...");

app.Run();
