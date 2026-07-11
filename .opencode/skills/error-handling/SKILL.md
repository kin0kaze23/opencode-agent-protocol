---
name: error-handling
description: Structured error patterns, error boundaries, retry logic, circuit breakers, and graceful degradation for resilient applications.
---

# Error Handling

Systematic error handling patterns for resilient applications.

## Procedure

Before implementing error handling, read the following:

1. Read the target module to understand what operations could fail
2. Read the existing error handling patterns in the codebase to match conventions
3. Read the repo's logging configuration to understand how errors are recorded
4. Read any existing error type definitions or base error classes

Then implement error handling following these patterns:

1. Define structured error types with codes, messages, and status codes
2. Implement retry logic for transient failures (network timeouts, rate limits)
3. Add circuit breakers for external service dependencies
4. Set up error boundaries for React UI components
5. Apply graceful degradation for non-critical external calls
6. Never swallow errors silently — always log with context

---

## When to Use

- Designing error handling for new features
- User mentions "error handling", "retry", "circuit breaker", "error boundary"
- Adding resilience to external API calls
- Reviewing error handling in existing code

## Structured Error Types

### Application Error Hierarchy
```typescript
class AppError extends Error {
  constructor(
    public code: string,
    public message: string,
    public statusCode: number,
    public details?: Record<string, unknown>
  ) {
    super(message);
    this.name = 'AppError';
  }
}

// Domain-specific errors
class NotFoundError extends AppError {
  constructor(resource: string, id: string) {
    super('NOT_FOUND', `${resource} with ID ${id} not found`, 404);
  }
}

class ValidationError extends AppError {
  constructor(field: string, message: string) {
    super('VALIDATION_ERROR', message, 400, { field });
  }
}

class UnauthorizedError extends AppError {
  constructor(message = 'Authentication required') {
    super('UNAUTHORIZED', message, 401);
  }
}

class ForbiddenError extends AppError {
  constructor(message = 'Insufficient permissions') {
    super('FORBIDDEN', message, 403);
  }
}

class ConflictError extends AppError {
  constructor(message: string) {
    super('CONFLICT', message, 409);
  }
}
```

### Global Error Handler (Express)
```typescript
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  // Log full error server-side
  console.error('[ERROR]', {
    message: err.message,
    stack: err.stack,
    path: req.path,
    method: req.method,
    userId: req.user?.id,
  });

  // Return generic error to client
  if (err instanceof AppError) {
    return res.status(err.statusCode).json({
      error: {
        code: err.code,
        message: err.message,
        details: err.details,
      },
    });
  }

  // Unknown errors — never expose internals
  res.status(500).json({
    error: {
      code: 'INTERNAL_ERROR',
      message: 'An unexpected error occurred',
    },
  });
});
```

## Retry Logic

### Exponential Backoff
```typescript
async function withRetry<T>(
  fn: () => Promise<T>,
  options: {
    maxRetries?: number;
    baseDelay?: number;
    maxDelay?: number;
    retryableErrors?: string[];
  } = {}
): Promise<T> {
  const {
    maxRetries = 3,
    baseDelay = 1000,
    maxDelay = 30000,
    retryableErrors = ['ECONNRESET', 'ETIMEDOUT', 'ECONNREFUSED'],
  } = options;

  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      const isRetryable = retryableErrors.includes(error.code);
      const isLastAttempt = attempt === maxRetries;

      if (!isRetryable || isLastAttempt) {
        throw error;
      }

      const delay = Math.min(baseDelay * 2 ** attempt + Math.random() * 1000, maxDelay);
      console.warn(`[RETRY] Attempt ${attempt + 1}/${maxRetries}, waiting ${delay}ms`);
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }

  throw new Error('Unreachable');
}
```

### When to Retry
| Scenario | Retry? | Why |
|---|---|---|
| Network timeout | ✅ Yes | Transient |
| Rate limit (429) | ✅ Yes, after Retry-After | Transient |
| 500/502/503 | ✅ Yes | Server may recover |
| 400/401/403/404 | ❌ No | Client error, won't fix itself |
| Database constraint violation | ❌ No | Data issue, not transient |

## Circuit Breaker

```typescript
class CircuitBreaker {
  private state: 'closed' | 'open' | 'half-open' = 'closed';
  private failures = 0;
  private lastFailure: number = 0;

  constructor(
    private threshold: number = 5,
    private timeout: number = 60000
  ) {}

  async execute<T>(fn: () => Promise<T>): Promise<T> {
    if (this.state === 'open') {
      if (Date.now() - this.lastFailure > this.timeout) {
        this.state = 'half-open';
      } else {
        throw new AppError('CIRCUIT_OPEN', 'Service unavailable', 503);
      }
    }

    try {
      const result = await fn();
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }

  private onSuccess() {
    this.failures = 0;
    this.state = 'closed';
  }

  private onFailure() {
    this.failures++;
    this.lastFailure = Date.now();
    if (this.failures >= this.threshold) {
      this.state = 'open';
    }
  }
}
```

## Error Boundaries (React)

```typescript
class ErrorBoundary extends React.Component<
  { fallback?: React.ReactNode; onError?: (error: Error) => void },
  { hasError: boolean; error: Error | null }
> {
  state = { hasError: false, error: null };

  static getDerivedStateFromError(error: Error) {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, info: React.ErrorInfo) {
    console.error('[ERROR BOUNDARY]', error, info);
    this.props.onError?.(error);
  }

  render() {
    if (this.state.hasError) {
      return this.props.fallback || (
        <div role="alert">
          <h2>Something went wrong</h2>
          <p>We're working on fixing this.</p>
          <button onClick={() => this.setState({ hasError: false })}>
            Try again
          </button>
        </div>
      );
    }
    return this.props.children;
  }
}
```

## Graceful Degradation

```typescript
// External API call with fallback
async function getUserProfile(userId: string) {
  try {
    return await externalApi.getUser(userId);
  } catch (error) {
    if (error.code === 'NOT_FOUND') {
      return null; // Expected absence
    }
    // Degrade gracefully — return cached or default data
    console.warn('[DEGRADED] Using cached profile for', userId);
    return getCachedProfile(userId) || getDefaultProfile(userId);
  }
}
```

## Anti-Patterns (Never Do)

- Swallow errors silently (`catch (e) {}`)
- Return 200 with error in body (use proper HTTP status)
- Expose stack traces to clients
- Retry non-retryable errors (400, 401, 403, 404)
- Use `try/catch` without logging the error
- Return different error shapes across endpoints
- Let unhandled promise rejections crash the server

## Output format

Produce an error handling report in this exact format:

```
## Error Handling — <module/feature name>

**Patterns applied:** <error types / retry / circuit breaker / error boundary / graceful degradation>

### Error types added
- <error class>: <when it is thrown>

### Retry logic
- <operation>: <retry strategy>

### Circuit breaker
- <service>: <threshold and timeout>

### Error boundaries
- <component>: <fallback UI>

### Verification
- [ ] All errors logged with context
- [ ] Client-facing messages are user-friendly
- [ ] No stack traces exposed to users
- [ ] Retry logic only applies to transient errors
```

## Out of Scope

This skill does NOT:
- Fix production bugs caused by error handling (that is /debug)
- Replace logging infrastructure setup (that is observability/SKILL.md)
- Audit security of error messages (that is security/SKILL.md)
- Write tests for error handling (that is testing-validation/SKILL.md)
- Handle database transaction rollback on errors (that is database/SKILL.md)
