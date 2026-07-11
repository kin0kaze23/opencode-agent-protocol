---
name: observability
description: Logging conventions, metrics, tracing, alerting, and health checks for application observability across all portfolio projects.
---

# Observability

Logging, metrics, tracing, alerting, and health check patterns for application observability.

## When to Use

- Setting up logging for a new project
- User mentions "logging", "metrics", "tracing", "observability", "monitoring", "health check"
- Adding alerting or error tracking
- Debugging production issues
- Setting up health check endpoints

## Logging Conventions

### Structured Logging (JSON)
```typescript
import pino from 'pino';

const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  transport: process.env.NODE_ENV === 'production'
    ? undefined // JSON to stdout, collected by platform
    : { target: 'pino-pretty' },
});

// Usage
logger.info({ userId: '123', action: 'login' }, 'User logged in');
logger.error({ err, userId: '123' }, 'Login failed');
logger.warn({ endpoint: '/api/users', latency: 2500 }, 'Slow response');
```

### Log Levels
| Level | When | Example |
|---|---|---|
| `ERROR` | Something broke, needs attention | Database connection lost, unhandled exception |
| `WARN` | Something is wrong but system continues | Rate limit approaching, deprecated API used |
| `INFO` | Important business events | User created, order placed, deployment started |
| `DEBUG` | Detailed diagnostic info | Query execution time, cache hit/miss |

### What to Log
- Request ID (for tracing)
- User ID (authenticated requests)
- Action/event name
- Relevant context (IDs, not full objects)
- Duration for slow operations
- Error details (server-side only)

### What NOT to Log
- Passwords, tokens, API keys
- Full request/response bodies (too noisy)
- PII (personal identifiable information)
- Stack traces in production responses

## Health Check Endpoints

```typescript
// GET /health — basic liveness
app.get('/health', (req, res) => {
  res.json({ status: 'ok', uptime: process.uptime() });
});

// GET /health/ready — readiness (dependencies checked)
app.get('/health/ready', async (req, res) => {
  const checks = {
    database: await checkDatabase(),
    cache: await checkCache(),
    externalApi: await checkExternalApi(),
  };

  const allHealthy = Object.values(checks).every(c => c.status === 'ok');
  const statusCode = allHealthy ? 200 : 503;

  res.status(statusCode).json({
    status: allHealthy ? 'ready' : 'degraded',
    checks,
  });
});
```

## Metrics

### Key Metrics to Track
| Metric | Why | How |
|---|---|---|
| Request rate | Traffic volume | Count requests/minute |
| Error rate | Reliability | Count 5xx responses/minute |
| Latency (p50, p95, p99) | Performance | Histogram of response times |
| Active users | Engagement | Unique authenticated users/hour |
| Queue depth | Backlog | Pending jobs count |
| Memory/CPU | Resource usage | Process metrics |

### Express Middleware for Metrics
```typescript
import promClient from 'prom-client';

const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.01, 0.05, 0.1, 0.5, 1, 2, 5, 10],
});

app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    httpRequestDuration
      .labels(req.method, req.route?.path || req.path, res.statusCode)
      .observe(duration);
  });
  next();
});
```

## Tracing

### Request ID Propagation
```typescript
// Generate request ID at the edge
app.use((req, res, next) => {
  req.requestId = req.headers['x-request-id'] || crypto.randomUUID();
  res.setHeader('X-Request-ID', req.requestId);
  next();
});

// Include in all logs
logger.info({ requestId: req.requestId }, 'Processing request');
```

### Distributed Tracing
For multi-service architectures (Tier 2 Docker projects):
- Propagate `X-Request-ID` across service boundaries
- Use OpenTelemetry for automatic instrumentation
- Correlate logs with trace IDs

## Alerting

### Alert Rules
| Alert | Threshold | Severity |
|---|---|---|
| Error rate > 5% | 5xx responses > 5% of total | Critical |
| Latency p99 > 5s | 99th percentile response time | High |
| Service down | Health check failing for 2min | Critical |
| Memory > 90% | Process memory usage | High |
| Queue depth > 1000 | Pending jobs | Medium |

### Alert Channels
- **Critical**: PagerDuty, SMS, or immediate notification
- **High**: Slack channel with @here
- **Medium**: Slack channel, no immediate page
- **Low**: Dashboard only, review weekly

## Project-Specific Setup

### Vercel Projects (Tier 1)
- Use Vercel Analytics for request metrics
- Use Vercel Logs for application logs
- Health checks via `/api/health` endpoint
- Error tracking: Sentry or Vercel Error Tracking

### Docker Projects (Tier 2)
- Structured JSON logging to stdout
- Log collection: Docker logging driver or sidecar
- Metrics: Prometheus + Grafana
- Health checks: `/health` and `/health/ready` endpoints
- Error tracking: Sentry

### Local-Only Projects (Tier 3)
- Console logging with levels
- No remote log collection needed
- Health checks optional

## Anti-Patterns (Never Do)

- Log passwords, tokens, or API keys
- Use `console.log` in production (use structured logger)
- Log full request/response bodies
- Ignore health check failures
- Set all logs to DEBUG in production (too noisy)
- Alert on every error (alert fatigue)
- No request ID (impossible to trace issues)
