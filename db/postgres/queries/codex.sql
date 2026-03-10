-- name: GetCodex :one
SELECT *
FROM codex
WHERE id = $1
LIMIT 1;

-- name: CountEnabledCodex :one
SELECT COUNT(*)
FROM codex
WHERE status = 'enabled';

-- name: UpdateCodexTokens :one
UPDATE codex
SET
    status = $2,
    access_token = $3,
    expired = $4,
    refresh_token = $5,
    plan_type = $6,
    plan_expired = $7
WHERE id = $1
RETURNING *;

-- name: CountCodex :one
SELECT COUNT(*) FROM codex;

-- name: ListCodex :many
SELECT
    c.*,
    COALESCE(q.quota_5h, 1.0) AS quota_5h,
    COALESCE(q.quota_7d, 1.0) AS quota_7d,
    COALESCE(q.reset_5h, '0001-01-01'::timestamptz) AS reset_5h,
    COALESCE(q.reset_7d, '0001-01-01'::timestamptz) AS reset_7d,
    COALESCE(q.throttled_until, '0001-01-01'::timestamptz) AS throttled_until,
    COALESCE(q.synced_at, '0001-01-01'::timestamptz) AS synced_at
FROM codex c
LEFT JOIN quota q ON q.credential_id = c.id
ORDER BY c.id;

-- name: ListCodexPaged :many
SELECT
    c.*,
    COALESCE(q.quota_5h, 1.0) AS quota_5h,
    COALESCE(q.quota_7d, 1.0) AS quota_7d,
    COALESCE(q.reset_5h, '0001-01-01'::timestamptz) AS reset_5h,
    COALESCE(q.reset_7d, '0001-01-01'::timestamptz) AS reset_7d,
    COALESCE(q.throttled_until, '0001-01-01'::timestamptz) AS throttled_until,
    COALESCE(q.synced_at, '0001-01-01'::timestamptz) AS synced_at
FROM codex c
LEFT JOIN quota q ON q.credential_id = c.id
ORDER BY c.id
LIMIT $1 OFFSET $2;

-- name: CreateCodex :one
INSERT INTO codex (id, status, access_token, expired, refresh_token, plan_type, plan_expired)
VALUES ($1, $2, $3, $4, $5, $6, $7)
RETURNING *;

-- name: DeleteCodex :execrows
DELETE FROM codex WHERE id = $1;

-- name: UpdateCodexStatus :one
UPDATE codex SET status = $2 WHERE id = $1
RETURNING *;
