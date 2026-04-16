package com.example;

import io.dapr.workflows.runtime.WorkflowRuntime;
import io.dapr.workflows.runtime.WorkflowRuntimeBuilder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import jakarta.annotation.PostConstruct;
import java.util.Map;

@SpringBootApplication
@RestController
public class Application {
    private static final Logger logger = LoggerFactory.getLogger(Application.class);

    private WorkflowRuntime workflowRuntime;

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }

    @PostConstruct
    public void init() {
        logger.info("Starting Dapr Prime Workflow Application...");

        // Register and start workflow runtime
        WorkflowRuntimeBuilder builder = new WorkflowRuntimeBuilder();
        // Register with simple name "PrimeWorkflow" instead of fully qualified class name
        builder.registerWorkflow("PrimeWorkflow", PrimeWorkflow.class);
        builder.registerActivity("CalculatePrimesActivity", CalculatePrimesActivity.class);

        workflowRuntime = builder.build();
        logger.info("Workflow runtime built successfully");

        workflowRuntime.start(false);
        logger.info("Workflow runtime started");
    }

    @GetMapping("/health")
    public Map<String, String> health() {
        return Map.of("status", "healthy");
    }
}
