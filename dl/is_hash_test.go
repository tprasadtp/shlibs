package dl

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/tprasadtp/shlibs/internal/libtest"
)

func Test__libdl_is_md5hash(t *testing.T) {
	// t.Parallel()
	libtest.AssertShellsAvailable(t)

	tests := []struct {
		name string
		code int
		hash string
	}{
		{name: "valid", hash: MD5_VALID},
		{name: "invalid", hash: MD5_INVALID, code: 1},
		{name: "filename", hash: "testdata/MD5SUMS.txt", code: 1},
		{name: "empty-quote", hash: `""`, code: 1},
		{name: "none", code: 1},
	}
	for _, shell := range libtest.SupportedShells() {
		for _, tc := range tests {
			t.Run(fmt.Sprintf("%s-%s", shell, tc.name), func(t *testing.T) {
				// t.Parallel()
				cmd := exec.Command(shell, "-c", fmt.Sprintf(". ./dl.sh && . ../logger/logger.sh && __libdl_is_md5hash %s", tc.hash))
				libtest.PrintCmdDebug(t, cmd)

				var stdoutBuf, stderrBuf bytes.Buffer
				cmd.Stdout = &stdoutBuf
				cmd.Stderr = &stderrBuf
				cmd.Env = append(os.Environ(), "TZ=UTC")

				err := cmd.Run()
				assert.Empty(t, stdoutBuf.String())
				assert.Empty(t, stdoutBuf.String())
				assert.Equal(t, tc.code, cmd.ProcessState.ExitCode())

				if tc.code == 0 {
					assert.Nil(t, err)
				} else {
					assert.NotNil(t, err)
				}
			})
		}
	}
}

func Test__libdl_is_sha1hash(t *testing.T) {
	// t.Parallel()

	libtest.AssertShellsAvailable(t)

	tests := []struct {
		name string
		code int
		hash string
	}{
		{name: "valid", hash: SHA1_VALID},
		{name: "invalid", hash: SHA1_INVALID, code: 1},
		{name: "filename", hash: "testdata/SHA1SUMS.txt", code: 1},
		{name: "empty-quote", hash: `""`, code: 1},
		{name: "none", code: 1},
	}
	for _, shell := range libtest.SupportedShells() {
		for _, tc := range tests {
			t.Run(fmt.Sprintf("%s-%s", shell, tc.name), func(t *testing.T) {
				cmd := exec.Command(shell, "-c", fmt.Sprintf(". ./dl.sh && . ../logger/logger.sh && __libdl_is_sha1hash %s", tc.hash))
				var stdoutBuf, stderrBuf bytes.Buffer
				cmd.Stdout = &stdoutBuf
				cmd.Stderr = &stderrBuf
				cmd.Env = append(os.Environ(), "TZ=UTC")

				err := cmd.Run()
				assert.Empty(t, stdoutBuf.String())
				assert.Empty(t, stdoutBuf.String())
				assert.Equal(t, tc.code, cmd.ProcessState.ExitCode())
				if tc.code == 0 {
					assert.Nil(t, err)
				} else {
					assert.NotNil(t, err)
				}
			})
		}
	}
}

func Test__libdl_is_sha256hash(t *testing.T) {
	// t.Parallel()

	libtest.AssertShellsAvailable(t)

	tests := []struct {
		name string
		code int
		hash string
	}{
		{name: "valid", hash: SHA256_VALID},
		{name: "invalid", hash: SHA256_INVALID, code: 1},
		{name: "empty-quote", hash: `""`, code: 1},
		{name: "filename", hash: "testdata/SHA256SUMS.txt", code: 1},
		{name: "none", code: 1},
	}
	for _, shell := range libtest.SupportedShells() {
		for _, tc := range tests {
			t.Run(fmt.Sprintf("%s-%s", shell, tc.name), func(t *testing.T) {
				cmd := exec.Command(shell, "-c", fmt.Sprintf(". ./dl.sh && . ../logger/logger.sh && __libdl_is_sha256hash %s", tc.hash))
				var stdoutBuf, stderrBuf bytes.Buffer
				cmd.Stdout = &stdoutBuf
				cmd.Stderr = &stderrBuf
				cmd.Env = append(os.Environ(), "TZ=UTC")

				err := cmd.Run()
				assert.Empty(t, stdoutBuf.String())
				assert.Empty(t, stdoutBuf.String())
				assert.Equal(t, tc.code, cmd.ProcessState.ExitCode())
				if tc.code == 0 {
					assert.Nil(t, err)
				} else {
					assert.NotNil(t, err)
				}
			})
		}
	}
}

func Test__libdl_is_sha512hash(t *testing.T) {
	// t.Parallel()

	libtest.AssertShellsAvailable(t)

	tests := []struct {
		name string
		code int
		hash string
	}{
		{name: "valid", hash: SHA512_VALID},
		{name: "invalid", hash: SHA512_INVALID, code: 1},
		{name: "filename", hash: "testdata/SHA256SUMS.txt", code: 1},
		{name: "empty-quote", hash: `""`, code: 1},
		{name: "none", code: 1},
	}
	for _, shell := range libtest.SupportedShells() {
		for _, tc := range tests {
			t.Run(fmt.Sprintf("%s-%s", shell, tc.name), func(t *testing.T) {
				cmd := exec.Command(shell, "-c", fmt.Sprintf(". ./dl.sh && . ../logger/logger.sh && __libdl_is_sha512hash %s", tc.hash))
				var stdoutBuf, stderrBuf bytes.Buffer
				cmd.Stdout = &stdoutBuf
				cmd.Stderr = &stderrBuf
				cmd.Env = append(os.Environ(), "TZ=UTC")

				err := cmd.Run()
				assert.Empty(t, stdoutBuf.String())
				assert.Empty(t, stdoutBuf.String())
				assert.Equal(t, tc.code, cmd.ProcessState.ExitCode())
				if tc.code == 0 {
					assert.Nil(t, err)
				} else {
					assert.NotNil(t, err)
				}
			})
		}
	}
}
