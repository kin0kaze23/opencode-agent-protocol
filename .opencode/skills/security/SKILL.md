---
name: security
description: Security best practices for auth, APIs, blockchain, and web application hardening. Covers the 20-point vibe-code security audit checklist.
---

# Security Skill

Systematic security audit and hardening for portfolio applications.
Auto-activated when touch-list includes auth, payment, schema, security, crypto, or user-data paths.

## When to Use

- Any `/implement`, `/review`, or `/ship` touching sensitive paths
- User asks to "audit security", "harden", "is my code secure", "pentest"
- New API endpoints, auth flows, or data-exposing routes added
- Before any production deployment of a web application

## Audit Workflow

### Step 1 — Gather context
- Framework and language (Express, Next.js, Django, etc.)
- Monolith or separate frontend/backend?
- Authentication method (Clerk, JWT, sessions, OAuth)
- Database type and ORM

### Step 2 — Run the 20-point checklist
Work through each item below. For findings:
- Show the **offending code** with file:line reference
- Provide a **concrete fix** with code example
- Rate severity: CRITICAL, HIGH, MEDIUM, LOW
- Classify as VERIFIED (found in code), INFERRED (likely but unconfirmed), or CLEAN (verified absent)

### Step 3 — Report
Lead with CRITICAL findings. End with severity count and prioritized action list.
Only report actual findings — skip items verified clean.

---

## The 20-Point Security Checklist

### CRITICAL — Exploitable now, no auth required

#### 1. API keys hardcoded in frontend JavaScript
Keys in client-side code are visible to anyone opening devtools. AI tools do this constantly.

```typescript
// ❌ Key visible to anyone
const res = await fetch('https://api.example.com/data', {
  headers: { 'Authorization': `Bearer ${API_KEY}` }
});

// ✅ Frontend calls your backend, backend holds the key
const res = await fetch('/api/data');
```

**Fix**: Move all secrets to backend. Frontend should never hold secrets.
**Check**: Search for `API_KEY`, `SECRET`, `apiKey`, `secretKey` in `*.tsx`, `*.jsx`, `*.js`, `*.ts` under `src/`, `app/`, `components/`, `pages/`.

#### 3. SQL queries built with string concatenation
`"SELECT * FROM users WHERE id=" + userId` is textbook SQL injection.

```typescript
// ❌ SQL injection
const query = "SELECT * FROM users WHERE id=" + userId;

// ✅ Parameterized (Drizzle/Prisma safe by default)
db.query.users.findFirst({ where: eq(users.id, userId) })
```

**Fix**: Use parameterized queries. Drizzle/Prisma are safe by default — verify no raw SQL with string interpolation.
**Check**: Search for string concatenation in SQL: `+ userId`, `+ req.body`, template literals in query strings.

#### 8. .env committed to git (even once)
It's in history forever even if deleted. `git log --all --full-history -- .env` finds it.

**Fix**: Rotate every key that was ever committed. Add `.env` to `.gitignore`. Use `gitleaks` or `trufflehog` to scan history.
**Check**: `git log --all --full-history -- '*.env*' '*.key' 'credentials.json'`

#### 14. Server running as root
One exploit = full system access.

**Fix**: Run as non-privileged user. In Docker: `USER appuser` in Dockerfile.
**Check**: Dockerfile for missing `USER` directive, process running as uid 0.

#### 15. Database port exposed to the internet
PostgreSQL on 5432 should never have a public IP.

**Fix**: Put behind firewall/private network. One-click fix in most cloud providers.
**Check**: Cloud provider security groups, `docker-compose.yml` port mappings for DB services.

---

### HIGH — Exploitable with some effort or preconditions

#### 2. No rate limiting on authentication endpoints
Bots can try thousands of combos unimpeded.

```typescript
import rateLimit from 'express-rate-limit';
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  message: 'Too many login attempts. Try again later.'
});
app.post('/login', loginLimiter, loginHandler);
```

**Fix**: Rate limit + lockout after 5 failed attempts on `/login`, `/register`, `/reset-password`.
**Check**: Search for route definitions of auth endpoints — verify rate limiter middleware is applied.

#### 5. JWTs stored in localStorage
localStorage is readable by any JS on the page. One XSS steals every token.

```typescript
// ❌ XSS-readable
localStorage.setItem('token', jwt);

// ✅ httpOnly cookie — inaccessible to JavaScript
res.cookie('token', jwt, {
  httpOnly: true,
  secure: true,
  sameSite: 'strict',
  maxAge: 3600000
});
```

**Fix**: Use httpOnly cookies. Never store tokens in localStorage or sessionStorage.
**Check**: Search for `localStorage`, `sessionStorage` with token/auth-related keys.

#### 6. Weak or default JWT secrets
If the secret is `"secret"`, `"password"`, or from a tutorial, it's on a wordlist.

**Fix**: Generate 256-bit random secret: `node -e "console.log(require('crypto').randomBytes(64).toString('hex'))"`. Store in env var. Rotate periodically.
**Check**: Search for `JWT_SECRET` values in code (not env var references). Check for common defaults.

#### 11. Passwords hashed with MD5 or SHA1
Rainbow tables crack MD5 in seconds. No salt = no protection.

```typescript
import bcrypt from 'bcrypt';
const hash = await bcrypt.hash(password, 12);
const match = await bcrypt.compare(password, hash);
```

**Fix**: Use bcrypt (cost factor 12+) or argon2. Never MD5, SHA1, or unsalted hashes.
**Check**: Search for `md5(`, `sha1(`, `createHash('md5')`, `createHash('sha1')` in auth-related code.

#### 12. Auth tokens that never expire
Stolen token = permanent access forever.

```typescript
const token = jwt.sign({ userId: user.id }, secret, { expiresIn: '15m' });
const refreshToken = jwt.sign({ userId: user.id }, refreshSecret, { expiresIn: '7d' });
```

**Fix**: Short expiry on access tokens (15m-1h). Implement refresh token rotation. Invalidate old refresh tokens on use.
**Check**: JWT `sign()` calls — verify `expiresIn` is set. Check for refresh token rotation logic.

#### 16. IDOR on resource endpoints
Change the ID in the URL — can you access another user's data?

```typescript
app.get('/api/orders/:id', auth, async (req, res) => {
  const order = await Order.findById(req.params.id);
  if (!order || order.userId !== req.user.id) {
    return res.status(404).json({ error: 'Not found' });
  }
  res.json(order);
});
```

**Fix**: Validate ownership server-side on every resource endpoint. Return 404 (not 403) to avoid confirming resource existence.
**Check**: All `/:id` route handlers — verify ownership check against `req.user.id` or equivalent.

---

### MEDIUM — Requires specific conditions or chaining

#### 4. CORS set to wildcard (*)
`Access-Control-Allow-Origin: *` means any site can make requests to your API.

```typescript
// ❌ Any site can call your API
app.use(cors({ origin: '*' }));

// ✅ Explicit whitelist
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || [],
  credentials: true
}));
```

**Fix**: Whitelist specific origins. Never use `*` with credentials.
**Check**: Search for `cors({`, `Access-Control-Allow-Origin`, `origin: '*'`.

#### 7. Admin routes protected only in frontend
React Router guards are cosmetic. The server doesn't care. Hit the API directly and it opens.

**Fix**: Protect every route server-side. Frontend guards are UX only.
**Check**: Admin/protected routes — verify server-side middleware, not just client-side guards.

#### 9. Error responses exposing internals
Stack traces, DB table names, and file paths give attackers an infrastructure map.

```typescript
// ❌ Handing attackers a blueprint
app.use((err, req, res, next) => {
  res.status(500).json({ error: err.message, stack: err.stack });
});

// ✅ Keep internals internal
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: 'Internal server error' });
});
```

**Fix**: Log full errors server-side. Return generic messages to client. Never expose `err.stack`, `err.message`, or DB details.
**Check**: Error handlers, `catch` blocks that send `err` directly to response.

#### 10. File uploads with no MIME type validation
Extension checks alone don't protect. Upload a disguised script = full server access.

**Fix**: Validate MIME type server-side using magic bytes (not filename). Store uploads outside web root.
**Check**: File upload handlers — verify MIME validation, not just extension checks.

#### 13. Auth middleware missing on internal API routes
AI adds middleware to obvious routes and skips the rest. One unprotected endpoint is all it takes.

**Fix**: Apply auth middleware globally and opt-out for public routes, not the other way around. Audit every endpoint.
**Check**: List all route handlers. Verify each has auth middleware or is explicitly marked public.

#### 17. No HTTPS enforcement
Credentials over plain HTTP can be intercepted on any public network.

**Fix**: Enforce HTTPS at server level. Redirect all HTTP traffic. Set HSTS headers.
**Check**: Server config for HTTP→HTTPS redirect, HSTS header, `x-forwarded-proto` handling.

#### 20. Open redirects in callback URLs
Used to send users to phishing sites through your trusted domain.

```typescript
const ALLOWED_REDIRECTS = ['/dashboard', '/profile', '/settings'];
app.get('/callback', (req, res) => {
  const redirect = req.query.redirect || '/dashboard';
  if (!ALLOWED_REDIRECTS.includes(redirect)) {
    return res.redirect('/dashboard');
  }
  res.redirect(redirect);
});
```

**Fix**: Whitelist redirect destinations. Never trust user-supplied redirect URLs.
**Check**: Search for `redirect(`, `res.redirect`, `next(` with URL parameters from `req.query` or `req.body`.

---

### LOW — Best practice violation, increases attack surface

#### 18. Sessions not invalidated on logout
Clearing the cookie client-side is not enough. The old token still works server-side.

```typescript
app.post('/logout', auth, async (req, res) => {
  await Session.destroy({ where: { token: req.token } });
  res.clearCookie('token');
  res.json({ message: 'Logged out' });
});
```

**Fix**: Invalidate sessions server-side on every logout.
**Check**: Logout handlers — verify server-side session/token invalidation, not just cookie clearing.

#### 19. npm packages not audited since setup
Run `npm audit` right now. Count the criticals.

```bash
npm audit
npm audit fix

# For Rust
cargo audit
```

**Fix**: Schedule `npm audit` as part of every deploy. Fix critical/high vulnerabilities.
**Check**: Last audit date, CI pipeline for dependency scanning.

---

## Project-Specific Patterns

### ClearPathOS (Clerk)
- Never expose Clerk secret keys
- Use Clerk's middleware for route protection
- Validate session tokens server-side
- Clerk handles JWT storage, expiry, and rotation — verify middleware is applied to all protected routes

### Express Backends (example-analyzer, example-dashboard, AgentMonitor, ImagineHub)
- Always validate JWT server-side
- Apply auth middleware globally, opt-out for public routes
- Use zod for input validation on all endpoints
- Rate limit auth endpoints specifically (not just global rate limiting)

### Next.js App Router (ClearPathOS, example-toolchainMissionControl)
- Server Components are safe by default — secrets in server code are not exposed
- API routes (`app/api/`) need explicit auth middleware
- Edge middleware can enforce auth at the edge before page render
- Environment variables prefixed with `NEXT_PUBLIC_` are exposed to client — audit all of them

### Solana/Blockchain (StableVault, example-analyzer)
- NEVER store private keys in code — use env vars only
- Always simulate transactions before sending
- Use `sec-solana` skill for Solana-specific vulnerability patterns (CPI, PDA, signer checks)

### sample-service (n8n)
- n8n credentials must not be exposed in workflow definitions
- Webhook endpoints need authentication
- n8n instance should not be publicly accessible without auth

### example-cli (Rust)
- Secure AI assistant prompts — never leak system prompts
- Use `cargo audit` for dependency scanning
- Memory safety is handled by Rust — focus on logic vulnerabilities

---

## Input Validation

```typescript
import { z } from 'zod'

const UserSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  name: z.string().max(100).optional()
})

export function validateInput<T>(schema: z.ZodSchema<T>, data: unknown): T {
  return schema.parse(data)
}
```

Validate all user input at the boundary. Never trust client-side validation alone.

## XSS Prevention

```typescript
// React — safe by default
<div>{content}</div>

// AVOID unless absolutely necessary
<div dangerouslySetInnerHTML={{__html: content}} />

// Sanitize if HTML is required
import DOMPurify from 'dompurify'
const clean = DOMPurify.sanitize(dirty)
```

## Secrets Management

### NEVER Commit
- `.env` files
- `*.key` files
- `credentials.json`
- API keys/secrets
- Private keys

### Always Use
```bash
# .gitignore
.env
.env.local
.env.*.local
*.key
credentials.json
```

## Security Checklist (Quick Reference)

- [ ] No API keys or secrets in frontend code
- [ ] Rate limiting on auth endpoints (5 attempts/15min)
- [ ] No SQL injection (parameterized queries only)
- [ ] CORS whitelisted (no wildcard with credentials)
- [ ] JWTs in httpOnly cookies (not localStorage)
- [ ] JWT secret is 256-bit random (not default/tutorial)
- [ ] All routes protected server-side (not just frontend guards)
- [ ] No .env in git history
- [ ] Error responses are generic (no stack traces)
- [ ] File uploads validate MIME type (not just extension)
- [ ] Passwords hashed with bcrypt/argon2 (not MD5/SHA1)
- [ ] Auth tokens have expiry + refresh rotation
- [ ] Auth middleware on every endpoint (audit all routes)
- [ ] Server runs as non-root user
- [ ] Database not exposed to internet
- [ ] IDOR prevented (ownership validation on all resource endpoints)
- [ ] HTTPS enforced with redirect
- [ ] Sessions invalidated server-side on logout
- [ ] Dependencies audited (npm audit / cargo audit)
- [ ] No open redirects (whitelist callback URLs)
- [ ] CSRF tokens for state-changing operations
- [ ] Secure headers (helmet.js or equivalent)
