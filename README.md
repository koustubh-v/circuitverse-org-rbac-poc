# org_rbac_poc

A minimal Proof of Concept for an **Organization + Role-Based Access Control (RBAC)** system built with Ruby on Rails (API-only mode).

---

## Overview

This PoC demonstrates how to structure a multi-tenant organization system where users can create organizations, invite others as instructors, and where access is controlled by role — all without relying on external authorization gems.

---

## Database Design

```
users
  id, name, email

organizations
  id, name, creator_id (→ users.id)

organization_memberships
  id, user_id (→ users), organization_id (→ organizations), role (0=org_admin, 1=instructor)
```

**Relationships:**
- A `User` has many `OrganizationMemberships` and organizations through them.
- An `Organization` has many `OrganizationMemberships` and members through them.
- Each `OrganizationMembership` links a user to an org with a specific role.

---

## RBAC Logic

Roles are stored as an enum integer on `OrganizationMembership`:

| Role        | Integer |
|-------------|---------|
| `org_admin` | 0       |
| `instructor`| 1       |

Authorization is handled inline in the controller using two simple private helpers:

```ruby
def member_of?(org)
  org.organization_memberships.exists?(user: @current_user)
end

def admin_of?(org)
  org.organization_memberships.org_admin.exists?(user: @current_user)
end
```

No Pundit, no CanCanCan — just plain ActiveRecord queries.

---

## Current User Simulation

Since this is a PoC, authentication is skipped. Pass the acting user's ID via an HTTP header:

```
X-User-Id: 1
```

---

## API Endpoints

| Method | Path                              | Who can call       | Description                         |
|--------|-----------------------------------|--------------------|-------------------------------------|
| POST   | `/organizations`                  | Any valid user     | Creates an org; creator → org_admin |
| GET    | `/organizations/:id`              | org_admin, instructor | View org details + members       |
| POST   | `/organizations/:id/add_instructor` | org_admin only   | Add a user as instructor            |

---

## Running the Project

**Prerequisites:** Ruby 3.2+, Bundler

```bash
cd org_rbac_poc
bundle install
rails db:create db:migrate db:seed
rails server
```

Seeded user IDs will be printed in the terminal (Alice=1, Bob=2, Carol=3 by default).

---

## Example API Requests

### 1. Create an Organization (as Alice)

```bash
curl -X POST http://localhost:3000/organizations \
  -H "Content-Type: application/json" \
  -H "X-User-Id: 1" \
  -d '{"name": "CircuitVerse"}'
```

**Response (201):**
```json
{
  "id": 1,
  "name": "CircuitVerse",
  "created_by": "Alice",
  "members": [{ "user_id": 1, "name": "Alice", "role": "org_admin" }]
}
```

---

### 2. View Organization (as Alice or an instructor)

```bash
curl http://localhost:3000/organizations/1 \
  -H "X-User-Id: 1"
```

---

### 3. Add Bob as Instructor (org_admin only)

```bash
curl -X POST http://localhost:3000/organizations/1/add_instructor \
  -H "Content-Type: application/json" \
  -H "X-User-Id: 1" \
  -d '{"user_id": 2}'
```

**Response (201):**
```json
{
  "message": "Bob added as instructor",
  "membership": { "user_id": 2, "name": "Bob", "role": "instructor" }
}
```

---

### 4. Instructor tries to add a member (should fail)

```bash
curl -X POST http://localhost:3000/organizations/1/add_instructor \
  -H "Content-Type: application/json" \
  -H "X-User-Id: 2" \
  -d '{"user_id": 3}'
```

**Response (403):**
```json
{ "error": "Only org admins can add instructors" }
```

---

### 5. Duplicate membership attempt

```bash
# Try adding Bob again as instructor
curl -X POST http://localhost:3000/organizations/1/add_instructor \
  -H "Content-Type: application/json" \
  -H "X-User-Id: 1" \
  -d '{"user_id": 2}'
```

**Response (422):**
```json
{ "errors": ["User is already a member of this organization"] }
```
