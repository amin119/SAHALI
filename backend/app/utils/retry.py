import time
import structlog

log = structlog.get_logger()


def with_retries(fn, *, attempts: int = 3, backoff_seconds: float = 2, task_name: str = "task"):
    """Run fn() with retries; logs a warning per retry and an error on final failure."""
    for attempt in range(1, attempts + 1):
        try:
            return fn()
        except Exception as e:
            if attempt == attempts:
                log.error("background_task_failed", task=task_name, attempt=attempt, error=str(e))
            else:
                log.warning("background_task_retry", task=task_name, attempt=attempt, error=str(e))
                time.sleep(backoff_seconds * attempt)
