import { WorkflowContext, TWorkflow } from "@dapr/dapr";
import { PrimeInput, PrimeOutput } from "../models/prime-models.js";

export const primeWorkflow: TWorkflow = async function* (
  ctx: WorkflowContext,
  input: PrimeInput
): any {
  console.log(`PrimeWorkflow started with maxNumber=${input.maxNumber}`);

  const result: PrimeOutput = yield ctx.callActivity(
    "CalculatePrimesActivity",
    input
  );

  console.log(`PrimeWorkflow completed: found ${result.count} primes`);

  return result;
};
