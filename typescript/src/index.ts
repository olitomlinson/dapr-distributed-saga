import express from "express";
import { WorkflowRuntime } from "@dapr/dapr";
import { primeWorkflow } from "./workflows/prime-workflow.js";
import { calculatePrimesActivity } from "./activities/calculate-primes-activity.js";

const PORT = process.env.PORT || "8080";

async function main() {
  console.log("Initializing TypeScript Prime Workflow Application...");

  // Create Express server for health checks
  const app = express();
  app.use(express.json());

  app.get("/health", (req, res) => {
    res.status(200).json({ status: "healthy" });
  });

  // Initialize Workflow Runtime with Dapr configuration
  const daprHost = process.env.DAPR_HOST || "localhost";
  const daprPort = process.env.DAPR_GRPC_PORT || "50001";

  console.log(`Connecting to Dapr sidecar at ${daprHost}:${daprPort}`);

  const workflowRuntime = new WorkflowRuntime({
    daprHost,
    daprPort,
  });

  // Register workflow and activity with explicit names
  workflowRuntime
    .registerWorkflowWithName("PrimeWorkflow", primeWorkflow)
    .registerActivityWithName("CalculatePrimesActivity", calculatePrimesActivity);

  console.log("PrimeWorkflow registered");
  console.log("CalculatePrimesActivity registered");

  // Start workflow runtime
  await workflowRuntime.start();
  console.log("Workflow runtime started successfully");

  // Start HTTP server
  const server = app.listen(PORT, () => {
    console.log(`HTTP server listening on port ${PORT}`);
  });

  // Graceful shutdown
  const shutdown = async () => {
    console.log("Shutting down gracefully...");
    server.close();
    await workflowRuntime.stop();
    process.exit(0);
  };

  process.on("SIGINT", shutdown);
  process.on("SIGTERM", shutdown);
}

main().catch((error) => {
  console.error("Failed to start application:", error);
  process.exit(1);
});
