package com.example;

import io.dapr.workflows.Workflow;
import io.dapr.workflows.WorkflowStub;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class PrimeWorkflow implements Workflow {
    private static final Logger logger = LoggerFactory.getLogger(PrimeWorkflow.class);

    @Override
    public WorkflowStub create() {
        return ctx -> {
            logger.info("PrimeWorkflow started");

            PrimeInput input = ctx.getInput(PrimeInput.class);
            logger.info("Calculating primes up to: {}", input.getMaxNumber());

            PrimeOutput output = ctx.callActivity(
                    "CalculatePrimesActivity",
                    input,
                    PrimeOutput.class).await();

            logger.info("PrimeWorkflow completed: found {} primes", output.getCount());
            ctx.complete(output);
        };
    }
}
