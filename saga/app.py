import logging
from typing import List, Optional, Dict, Any

from dapr.ext.workflow import WorkflowRuntime, DaprWorkflowContext, DaprWorkflowClient
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create FastAPI app
app = FastAPI()

# Create workflow runtime
wfr = WorkflowRuntime()

# Data models
class SagaInput(BaseModel):
    maxNumber: int
    app_ids: List[str]

class SagaOutput(BaseModel):
    results: Dict[str, Optional[Dict[str, Any]]]
    totalExecutions: int
    successfulExecutions: int
    allCompleted: bool
    totalCalculationTimeMs: int
    averageCalculationTimeMs: float
    totalPrimesFound: int

# Saga Orchestrator Workflow
@wfr.workflow(name='SagaOrchestratorWorkflow')
def saga_orchestrator_workflow(ctx: DaprWorkflowContext, input_data: dict):
    """Saga orchestrator that calls PrimeWorkflow on all apps in parallel"""
    # Parse input
    if isinstance(input_data, dict):
        input_obj = SagaInput(**input_data)
    else:
        input_obj = input_data

    logger.info(f"SagaOrchestratorWorkflow started with maxNumber={input_obj.maxNumber}")

    app_ids = input_obj.app_ids

    logger.info(f"Starting child workflows on {len(app_ids)} apps in parallel")

    # Create all child workflows (starts them in parallel)
    tasks = [
        (app_id, ctx.call_child_workflow(
            'PrimeWorkflow',
            input={"maxNumber": input_obj.maxNumber},
            app_id=app_id))
        for app_id in app_ids
    ]

    # Wait for each task individually with error handling
    results = {}
    for app_id, task in tasks:
        try:
            result = yield task
            results[app_id] = result
            logger.info(f"✓ {app_id} workflow completed successfully")
        except Exception as e:     
            
            # This is where you would typically apply a Saga-style compensation action to a failed task.
            # The compensation would take the form of another Workflow call or Activity call that can unwind
            # the operation, or put it back to a known good state
            #
            # yield ctx.call_child_workflow(
            #   'PrimeWorkflow-Unwind',
            #   input=None,
            #   app_id=app_id)

            logger.error(f"✗ {app_id} workflow failed: {e}")
            results[app_id] = None

    logger.info(f"All child workflows reached a terminal state. Processing results...")

    # Build output with results mapped to app names
    successful_results = [r for r in results.values() if r is not None]

    total_time = sum(r.get('calculationTimeMs', 0) for r in successful_results) if successful_results else 0
    total_primes = successful_results[0].get('count', 0) if successful_results else 0

    output = {
        'results': results,
        'totalExecutions': len(app_ids),
        'successfulExecutions': len(successful_results),
        'allCompleted': len(successful_results) == len(app_ids),
        'totalCalculationTimeMs': total_time,
        'averageCalculationTimeMs': total_time / len(successful_results) if successful_results else 0,
        'totalPrimesFound': total_primes
    }

    logger.info(f"SagaOrchestratorWorkflow completed: {len(successful_results)}/{len(app_ids)} apps succeeded")

    return output

# FastAPI endpoints
@app.get("/health")
def health():
    """Health check endpoint"""
    return {"status": "healthy", "service": "saga-orchestrator"}

@app.post("/saga/start")
def start_saga(saga_input: SagaInput):
    """Start the saga orchestrator workflow"""
    try:
        workflow_client = DaprWorkflowClient()

        instance_id = workflow_client.schedule_new_workflow(
            workflow=saga_orchestrator_workflow,
            input=saga_input.model_dump()
        )

        logger.info(f"Started SagaOrchestratorWorkflow with instance_id: {instance_id}")

        return {
            "instance_id": instance_id,
            "status": "started",
            "input": saga_input.model_dump()
        }
    except Exception as e:
        logger.error(f"Failed to start saga workflow: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to start workflow: {str(e)}")

@app.get("/saga/status/{instance_id}")
def get_saga_status(instance_id: str):
    """Get the status of a running saga workflow"""
    try:
        workflow_client = DaprWorkflowClient()
        state = workflow_client.get_workflow_state(instance_id=instance_id)

        if not state:
            raise HTTPException(status_code=404, detail=f"Workflow {instance_id} not found")

        return {
            "instance_id": instance_id,
            "workflow_name": state.name,
            "runtime_status": state.runtime_status.name if hasattr(state.runtime_status, 'name') else str(state.runtime_status),
            "created_at": state.created_at.isoformat() if state.created_at else None,
            "last_updated_at": state.last_updated_at.isoformat() if state.last_updated_at else None,
            "serialized_output": state.serialized_output
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get workflow status: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to get workflow status: {str(e)}")

@app.on_event("startup")
async def startup_event():
    """Start the workflow runtime on app startup"""
    logger.info("Starting Saga Orchestrator workflow runtime...")
    wfr.start()
    logger.info("Saga Orchestrator workflow runtime started successfully")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
