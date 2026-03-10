package store

import "errors"

var (
	ErrNotFound           = errors.New("db: not found")
	ErrConflict           = errors.New("db: conflict")
	ErrAlreadyInitialized = errors.New("db: already initialized")
	ErrLastAdmin          = errors.New("db: last admin")
)
