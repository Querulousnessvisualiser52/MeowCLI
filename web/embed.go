package webui

import "embed"

// Dist contains the pre-rendered Nuxt admin application.
//
//go:embed all:dist
var Dist embed.FS
