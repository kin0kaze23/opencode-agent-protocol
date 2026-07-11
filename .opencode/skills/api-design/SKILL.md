---
name: api-design
description: REST and GraphQL API design patterns — versioning, pagination, error conventions, API contracts, and request/response standards.
---

# API Design

Systematic API design patterns for REST and GraphQL services.

## When to Use

- Designing new API endpoints
- Reviewing or refactoring existing APIs
- User mentions "API endpoint", "REST", "GraphQL", "API design", "API contract"
- Adding versioning, pagination, or error handling to APIs

## REST API Design

### URL Conventions
```
# Resources (nouns, plural)
GET    /api/users          # List users
GET    /api/users/:id      # Get user
POST   /api/users          # Create user
PUT    /api/users/:id      # Replace user
PATCH  /api/users/:id      # Update user
DELETE /api/users/:id      # Delete user

# Nested resources
GET    /api/users/:id/orders        # User's orders
POST   /api/users/:id/orders        # Create order for user
GET    /api/users/:id/orders/:oid   # Specific order

# Actions (use POST with action in body, not URL)
POST   /api/users/:id/activate      # Activate user
POST   /api/users/:id/deactivate    # Deactivate user
```

### Versioning
```typescript
// URL versioning (recommended for public APIs)
/api/v1/users
/api/v2/users

// Header versioning (cleaner URLs)
Accept: application/vnd.myapp.v1+json
```

### Pagination
```typescript
// Cursor-based (recommended for large datasets)
GET /api/users?limit=20&cursor=eyJpZCI6MTAwfQ

// Response
{
  "data": [...],
  "pagination": {
    "nextCursor": "eyJpZCI6MTIwfQ",
    "hasMore": true,
    "total": 1500
  }
}

// Offset-based (simpler, good for small datasets)
GET /api/users?limit=20&offset=40
```

### Error Response Format
```typescript
// Consistent error shape
{
  "error": {
    "code": "USER_NOT_FOUND",
    "message": "User with ID 123 not found",
    "details": {
      "userId": "123"
    }
  }
}

// HTTP status codes
200 OK              // Success
201 Created         // Resource created
204 No Content      // Success, no body (DELETE)
400 Bad Request     // Invalid input
401 Unauthorized    // Not authenticated
403 Forbidden       // Authenticated but not authorized
404 Not Found       // Resource doesn't exist
409 Conflict        // Resource conflict (e.g., duplicate)
422 Unprocessable   // Valid syntax, invalid semantics
429 Too Many Requests // Rate limited
500 Internal Error  // Server error
```

### Input Validation
```typescript
import { z } from 'zod';

const CreateUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
  role: z.enum(['user', 'admin']).default('user'),
});

// Validate at the boundary
export function createUser(req, res) {
  const result = CreateUserSchema.safeParse(req.body);
  if (!result.success) {
    return res.status(400).json({
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Invalid input',
        details: result.error.flatten(),
      },
    });
  }
  // ... proceed with valid data
}
```

### IDOR Prevention
```typescript
// ALWAYS validate ownership
app.get('/api/orders/:id', auth, async (req, res) => {
  const order = await Order.findById(req.params.id);
  if (!order || order.userId !== req.user.id) {
    return res.status(404).json({
      error: { code: 'NOT_FOUND', message: 'Order not found' }
    });
  }
  res.json(order);
});
```

## GraphQL Design

### Schema Organization
```graphql
# Types
type User {
  id: ID!
  email: String!
  name: String!
  orders: [Order!]!
  createdAt: DateTime!
}

# Queries (read)
type Query {
  user(id: ID!): User
  users(limit: Int = 20, cursor: String): UserConnection!
}

# Mutations (write)
type Mutation {
  createUser(input: CreateUserInput!): CreateUserPayload!
  updateUser(id: ID!, input: UpdateUserInput!): UpdateUserPayload!
}

# Input types
input CreateUserInput {
  email: String!
  name: String!
}

# Payload types (consistent error handling)
type CreateUserPayload {
  user: User
  errors: [Error!]
}

# Connection type (pagination)
type UserConnection {
  edges: [UserEdge!]!
  pageInfo: PageInfo!
  totalCount: Int!
}

type UserEdge {
  node: User!
  cursor: String!
}

type PageInfo {
  hasNextPage: Boolean!
  endCursor: String
}
```

## API Contract Documentation

Every API endpoint must be documented in `APP_FLOW.md` or equivalent:

```markdown
## POST /api/users

**Auth**: Required (JWT)
**Rate limit**: 100/15min

**Request:**
```json
{
  "email": "user@example.com",
  "name": "John Doe"
}
```

**Response 201:**
```json
{
  "data": {
    "id": "123",
    "email": "user@example.com",
    "name": "John Doe",
    "createdAt": "2026-04-04T00:00:00Z"
  }
}
```

**Response 400:**
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid email format"
  }
}
```
```

## Anti-Patterns (Never Do)

- Return different error shapes for different endpoints
- Use HTTP status codes inconsistently (e.g., 200 for errors)
- Expose internal IDs in URLs without validation
- Return stack traces or internal details in error responses
- Use GET for state-changing operations
- Return unbounded lists (always paginate)
- Mix authentication and authorization errors (401 vs 403)
- Return 403 for missing resources (use 404 to avoid enumeration)
