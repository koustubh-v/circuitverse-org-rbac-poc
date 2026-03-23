# Organization & RBAC PoC for CircuitVerse #Project 6
Submitted as part of GSoC 2026 proposal for CircuitVerse.

This project is a Proof of Concept built with Ruby on Rails that demonstrates a minimal Organization and Role-Based Access Control (RBAC) system. It is based on [Project 6: Enterprise & Institutional Organization Features](https://github.com/CircuitVerse/CircuitVerse/wiki/GSoC'26-Project-List#project-6-enterprise--institutional-organization-features) from the CircuitVerse GSoC 2026 project list.

The goal of this PoC is to validate the core data model and permission structure in a simple, focused environment before scaling it into a full production feature.

---

## Overview

CircuitVerse needs a way to group users into organizations and control what each user can do within that organization. This PoC models that requirement at its simplest: a user can create an organization, invite others as instructors, and access is controlled by role.

The goal is to validate the data model and authorization approach before building it into the main application.

---

## Approach

The system is intentionally minimal. There are only two roles and three API endpoints. Authorization is enforced inline in the controller using plain ActiveRecord queries — no external gems like Pundit or CanCanCan.

This keeps the code readable and easy to audit. A more complex system can always be layered on top once the core logic is validated.

Authentication is out of scope for this PoC. Instead, each request carries an `X-User-Id` header that identifies the acting user.

---

## Why this PoC matters

This PoC focuses on validating a clean and scalable approach to organization-level RBAC before integrating it into a larger production system. It ensures that role boundaries, data relationships, and permission checks are well-defined early on.

---

## Data Model

### Users

| Column | Type   |
|--------|--------|
| id     | integer |
| name   | string |
| email  | string (unique) |

### Organizations

| Column     | Type    |
|------------|---------|
| id         | integer |
| name       | string  |
| creator_id | integer (FK → users) |

### OrganizationMemberships

| Column          | Type    |
|-----------------|---------|
| id              | integer |
| user_id         | integer (FK → users) |
| organization_id | integer (FK → organizations) |
| role            | integer (enum: 0=org_admin, 1=instructor) |

**Relationships:**

- A user can belong to many organizations through memberships.
- An organization has many members through memberships.
- Each membership is unique per user per organization (enforced at both the DB and model level).

---

## RBAC Logic

Roles are stored as an integer enum on `OrganizationMembership`:

```ruby
enum :role, { org_admin: 0, instructor: 1 }
```

Access control is handled by two private helpers in the controller:

```ruby
def member_of?(org)
  org.organization_memberships.exists?(user: @current_user)
end

def admin_of?(org)
  org.organization_memberships.org_admin.exists?(user: @current_user)
end
```

| Action          | org_admin | instructor |
|-----------------|-----------|------------|
| Create org      | yes       | yes (becomes admin) |
| View org        | yes       | yes        |
| Add instructor  | yes       | no (403)   |

---

## API Endpoints

All responses follow this structure:

```json
// Success
{ "success": true, "data": { ... } }

// Error
{ "success": false, "error": "...", "details": [...] }
```

The `details` field is only present when there are validation errors.

---

### POST /organizations

Creates a new organization. The requesting user automatically becomes `org_admin`.

**Request:**
```json
{ "name": "CircuitVerse" }
```

---

### GET /organizations/:id

Returns organization details and its member list. Accessible to both `org_admin` and `instructor`.

---

### POST /organizations/:id/add_instructor

Adds a user as an instructor. Only `org_admin` can call this.

**Request:**
```json
{ "user_id": 2 }
```

---

## Example Flow

1. Koustubh sends `POST /organizations` with `X-User-Id: 1`.
   - Organization is created.
   - Koustubh is automatically assigned `org_admin`.

2. Koustubh sends `POST /organizations/1/add_instructor` with `{ "user_id": 2 }`.
   - Vedant is added as `instructor`.

3. Vedant sends `GET /organizations/1` with `X-User-Id: 2`.
   - Returns organization details. Access granted.

4. Vedant tries `POST /organizations/1/add_instructor` with `X-User-Id: 2`.
   - Returns `403 Forbidden`. Instructors cannot add members.

---

## How to Run

**Prerequisites:** Ruby 3.2+, Bundler

```bash
git https://github.com/koustubh-v/circuitverse-org-rbac-poc.git
cd org_rbac_poc

bundle install

rails db:create db:migrate db:seed

rails server
```

After seeding, the database will have three users:

| id | name     | email                |
|----|----------|----------------------|
| 1  | Koustubh | koustubh@admin.com   |
| 2  | Vedant   | vedant@admin.com     |
| 3  | Pratham  | pratham@admin.com    |

---

## Testing the API

**Create an organization (as Koustubh):**
```bash
curl -X POST http://localhost:3000/organizations \
  -H "Content-Type: application/json" \
  -H "X-User-Id: 1" \
  -d '{"name": "CircuitVerse"}'
```

**View the organization:**
```bash
curl http://localhost:3000/organizations/1 \
  -H "X-User-Id: 1"
```

**Add Vedant as instructor:**
```bash
curl -X POST http://localhost:3000/organizations/1/add_instructor \
  -H "Content-Type: application/json" \
  -H "X-User-Id: 1" \
  -d '{"user_id": 2}'
```

**Instructor tries to add a member (expect 403):**
```bash
curl -X POST http://localhost:3000/organizations/1/add_instructor \
  -H "Content-Type: application/json" \
  -H "X-User-Id: 2" \
  -d '{"user_id": 3}'
```

**Duplicate membership attempt (expect 422):**
```bash
curl -X POST http://localhost:3000/organizations/1/add_instructor \
  -H "Content-Type: application/json" \
  -H "X-User-Id: 1" \
  -d '{"user_id": 2}'
```

---

## Design Decisions

**No authentication system.** Adding session management or token auth would obscure the RBAC logic, which is the actual subject of this PoC. The `X-User-Id` header is a stand-in that keeps the focus where it belongs.

**No authorization gems.** Pundit and CanCanCan are good tools, but they add abstraction. For three endpoints and two roles, a pair of ActiveRecord checks is simpler and easier to review.

**Inline authorization over callbacks.** Authorization logic lives directly in each action rather than in `before_action` hooks. This makes the permission model explicit and avoids hidden control flow.

---

## Possible Improvements

- **Authentication** — Integrate with CircuitVerse's existing auth (Devise/OmniAuth) rather than the header approach.
- **More roles** — Add roles like `viewer` or `co_admin` as the product requires.
- **Multi-organization membership** — A user holding different roles in different organizations simultaneously.
- **Audit log** — Track who added whom and when.
- **UI layer** — A frontend to manage organization members and roles.
- **SSO** — Integrate with institutional identity providers for organization-level sign-in.

---

## Demo

_Demo video link coming soon._
