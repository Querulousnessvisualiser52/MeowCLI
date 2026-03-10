-- name: GetCodex :one
SELECT *
FROM codex
WHERE id = ?
LIMIT 1;

-- name: CountEnabledCodex :one
SELECT COUNT(*)
FROM codex
WHERE status = 'enabled';

-- name: UpdateCodexTokens :one
UPDATE codex
SET
    status = ?,
    access_token = ?,
    expired = ?,
    refresh_token = ?,
    plan_type = ?,
    plan_expired = ?
WHERE id = ?
RETURNING *;

-- name: CountCodex :one
SELECT COUNT(*) FROM codex;

-- name: ListCodex :many
SELECT
    c.*,
    COALESCE(q.quota_5h, 1.0) AS quota_5h,
    COALESCE(q.quota_7d, 1.0) AS quota_7d,
    COALESCE(q.reset_5h, '') AS reset_5h,
    COALESCE(q.reset_7d, '') AS reset_7d,
    COALESCE(q.throttled_until, '') AS throttled_until,
    COALESCE(q.synced_at, '') AS synced_at
FROM codex c
LEFT JOIN quota q ON q.credential_id = c.id
ORDER BY c.id;

-- name: ListCodexPaged :many
SELECT
    c.*,
    COALESCE(q.quota_5h, 1.0) AS quota_5h,
    COALESCE(q.quota_7d, 1.0) AS quota_7d,
    COALESCE(q.reset_5h, '') AS reset_5h,
    COALESCE(q.reset_7d, '') AS reset_7d,
    COALESCE(q.throttled_until, '') AS throttled_until,
    COALESCE(q.synced_at, '') AS synced_at
FROM codex c
LEFT JOIN quota q ON q.credential_id = c.id
ORDER BY c.id
LIMIT ? OFFSET ?;

-- name: CreateCodex :one
INSERT INTO codex (id, status, access_token, expired, refresh_token, plan_type, plan_expired)
VALUES (?, ?, ?, ?, ?, ?, ?)
RETURNING *;

-- name: DeleteCodex :execrows
DELETE FROM codex WHERE id = ?;

-- name: UpdateCodexStatus :one
UPDATE codex SET status = ? WHERE id = ?
RETURNING *;
