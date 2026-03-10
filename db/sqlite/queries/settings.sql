-- name: ListSettings :many
SELECT key, value, updated_at
FROM settings
ORDER BY key;

-- name: UpsertSetting :one
INSERT INTO settings (key, value, updated_at)
VALUES (?, ?, datetime('now'))
ON CONFLICT(key) DO UPDATE SET
    value = excluded.value,
    updated_at = datetime('now')
RETURNING key, value, updated_at;
