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

func Test__shlib_explain_error(t *testing.T) {
	t.Parallel()
	libtest.AssertShellsAvailable(t)

	for _, shell := range libtest.SupportedShells() {
		for tc := 1; tc < 128; tc++ {
			t.Run(fmt.Sprintf("%s=%d", shell, tc), func(t *testing.T) {
				cmd := exec.Command(shell, "-c", fmt.Sprintf(". ../logger/logger.sh && . ./__dl_errors.sh && shlib_explain_error %d", tc))

				libtest.PrintCmdDebug(t, cmd)
				var stdoutBuf, stderrBuf bytes.Buffer
				cmd.Stdout = &stdoutBuf
				cmd.Stderr = &stderrBuf
				cmd.Env = append(os.Environ(), "TZ=UTC")

				cmd.Run()
				cmd.Run()
				if tc != 0 {
					assert.NotEqual(t, 0, cmd.ProcessState.ExitCode())
					assert.Empty(t, stdoutBuf.String())
				} else {
					assert.Empty(t, stderrBuf.String())
					assert.Empty(t, stdoutBuf.String())
				}
			})
		}
	}
}
