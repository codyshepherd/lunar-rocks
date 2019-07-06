package main

import (
	"time"
)

type TokenType int

// Token types map to natural numbers starting with 0
const (
	Bigfoot TokenType = iota
	Pixie
)

// Token represents a row/entry in the 'tokens' table
type Token struct {
	TokenString  string
	Type         TokenType
	Valid        bool
	Expires      time.Time
	ForeignKeyID string
}
