package dl

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/tprasadtp/shlibs/internal/libtest"
)

func Test__libdl_verify_sha512(t *testing.T) {
	// t.Parallel()
	libtest.AssertShellsAvailable(t)

	tests := []struct {
		name      string
		file      string
		code      int
		hash      string
		errString string
	}{
		{
			name: "existing-file-raw-hash-match",
			file: "testdata/checksum.txt",
			hash: SHA512_VALID,
		},
		{
			name: "existing-file-checksum-file-match",
			file: "testdata/checksum.txt",
			hash: "testdata/SHA512SUMS.txt",
		},
		// Checksums failure
		{
			name: "existing-file-raw-hash-err-on-mismatch",
			file: "testdata/checksum.txt",
			hash: SHA512_MISMATCH,
			code: 80,
		},
		{
			name: "existing-file-checksum-err-on-mismatch",
			file: "testdata/checksum.txt",
			hash: "testdata/SHA512SUMS.mismatch.txt",
			code: 80,
		},
		// Target is missing
		{
			name: "non-existing-target-err-checksum-raw",
			file: "testdata/no-such-file.txt",
			hash: SHA512_VALID,
			code: 31,
		},
		{
			name: "non-existing-target-err-checksum-file",
			file: "testdata/no-such-file.txt",
			hash: "testdata/SHA512SUMS.txt",
			code: 31,
		},
		// Invalid checksum
		{
			name: "existing-file-raw-hash-invalid-looks-for-file",
			file: "testdata/checksum.txt",
			hash: SHA512_INVALID,
			code: 32,
		},
		{
			name: "existing-file-checksum-file-invalid-checksum",
			file: "testdata/checksum.txt",
			hash: "testdata/SHA512SUMS.invalid.txt",
			code: 35,
		},
		// Target missing from checksums file
		{
			name:      "existing-file-err-on-missing-from-hashes-file",
			file:      "testdata/checksum.txt",
			hash:      "testdata/SHA512SUMS.missing.txt",
			errString: "failed to find sha512 hash corresponding to",
			code:      35,
		},
		// File contining just checksums, as it fallbacks to checksum file,
		// errors return 35
		{
			name: "checksum-file-has-only-hash-value",
			file: "testdata/checksum.txt",
			hash: "testdata/SHA512SUMS.hash.txt",
		},
		{
			name: "checksum-file-has-only-hash-value-with-newline",
			file: "testdata/checksum.txt",
			hash: "testdata/SHA512SUMS.hash.lf-1.txt",
		},
		{
			name: "checksum-file-has-only-hash-value-with-newlines",
			file: "testdata/checksum.txt",
			hash: "testdata/SHA512SUMS.hash.lf-2.txt",
		},
		{
			name: "checksum-file-has-only-hash-value-with-cr",
			file: "testdata/checksum.txt",
			hash: "testdata/SHA512SUMS.hash.cr-1.txt",
		},
		//mismatch should return checksum error
		// as the has in the file is a valid hash, but fails to match
		{
			name: "checksum-file-has-only-hash-mismatch",
			file: "testdata/checksum.txt",
			hash: "testdata/SHA512SUMS.hash.mismatch.txt",
			code: 80,
		},
		// these will cause the code to treat them as standard files and fail
		{
			name:      "checksum-file-has-only-hash-value-but-invalid",
			file:      "testdata/checksum.txt",
			errString: "failed to find sha512 hash corresponding to",
			hash:      "testdata/SHA512SUMS.hash.invalid.txt",
			code:      35,
		},
	}
	for _, shell := range libtest.SupportedShells() {
		for _, tc := range tests {
			for _, hashTypeInput := range []string{"sha512", "sha-512", "SHA512", "SHA-512"} {
				t.Run(fmt.Sprintf("%s-%s-%s=%d", shell, tc.name, hashTypeInput, tc.code), func(t *testing.T) {
					cmd := exec.Command(shell, "-c", fmt.Sprintf(". ./dl.sh && . ../logger/logger.sh && __libdl_hash_verify %s %s %s", tc.file, tc.hash, hashTypeInput))
					libtest.PrintCmdDebug(t, cmd)
					var stdoutBuf, stderrBuf bytes.Buffer
					cmd.Stdout = &stdoutBuf
					cmd.Stderr = &stderrBuf
					cmd.Env = append(os.Environ(), "TZ=UTC", "LOG_LVL=0")
					err := cmd.Run()
					assert.Empty(t, stdoutBuf.String())
					if tc.code == 0 {
						assert.Nil(t, err)
					} else {
						assert.NotNil(t, err)
						assert.Contains(t, strings.ToLower(stderrBuf.String()), tc.errString)
					}
					assert.Equal(t, tc.code, cmd.ProcessState.ExitCode())
				})
			}
		}
	}
}
