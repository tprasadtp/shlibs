// Package dl is a shell library for downloading files with checksum and gpg signature verification.
// This package is not meant to be used in go, but in shells instead.
// This go package exists to extensively unit test the shellscripts.
// Test data can be generated with go generate

//go:generate ./testdata/gen-hash-data.sh

package dl
