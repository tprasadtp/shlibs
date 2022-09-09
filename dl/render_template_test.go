package dl

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"runtime"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/tprasadtp/shlibs/internal/libtest"
)

func Test__libdl_get_rendered_string(t *testing.T) {
	// t.Parallel()
	libtest.AssertShellsAvailable(t)

	SYS_ARCH := libtest.UnameM()
	SYS_OS := libtest.UnameS()

	tests := []struct {
		name   string
		url    string
		expect string
		code   int
	}{
		{
			name:   "no-template",
			url:    "https://github.com/tprasadtp/gfilt/releases/download/v0.1.48/gfilt_linux_amd64.tar.gz",
			expect: "https://github.com/tprasadtp/gfilt/releases/download/v0.1.48/gfilt_linux_amd64.tar.gz",
		},
		{
			name:   "with-goos",
			url:    "https://github.com/tprasadtp/gfilt/releases/download/v0.1.48/gfilt_++GOOS++_amd64.tar.gz",
			expect: fmt.Sprintf("https://github.com/tprasadtp/gfilt/releases/download/v0.1.48/gfilt_%s_amd64.tar.gz", runtime.GOOS),
		},
		{
			name:   "with-goarch",
			url:    "https://github.com/tprasadtp/gfilt/releases/download/v0.1.48/gfilt_linux_++GOARCH++.tar.gz",
			expect: fmt.Sprintf("https://github.com/tprasadtp/gfilt/releases/download/v0.1.48/gfilt_linux_%s.tar.gz", runtime.GOARCH),
		},
		{
			name:   "with-system-os",
			url:    "https://github.com/tprasadtp/gfilt/releases/download/v0.1.48/gfilt_++SYS_OS++.tar.gz",
			expect: fmt.Sprintf("https://github.com/tprasadtp/gfilt/releases/download/v0.1.48/gfilt_%s.tar.gz", SYS_OS),
		},
		{
			name:   "with-system-arch",
			url:    "https://github.com/tprasadtp/gfilt/releases/download/v0.1.48/gfilt_linux_++SYS_ARCH++.tar.gz",
			expect: fmt.Sprintf("https://github.com/tprasadtp/gfilt/releases/download/v0.1.48/gfilt_linux_%s.tar.gz", SYS_ARCH),
		},
		{
			name:   "with-all",
			url:    "https://github.com/tprasadtp/gfilt/releases/download/v0.1.48/gfilt_++SYS_ARCH++_++SYS_ARCH++_++GOOS++_++GOARCH++.tar.gz",
			expect: fmt.Sprintf("https://github.com/tprasadtp/gfilt/releases/download/v0.1.48/gfilt_%s_%s_%s_%s.tar.gz", SYS_OS, SYS_ARCH, runtime.GOOS, runtime.GOARCH),
		},
	}
	for _, shell := range []string{"bash"} {
		for _, tc := range tests {
			t.Run(fmt.Sprintf("%s-%s", shell, tc.name), func(t *testing.T) {
				cmd := exec.Command(shell, "-c", fmt.Sprintf(". ./dl.sh && . ../logger/logger.sh && __libdl_render_template %s", tc.url))
				libtest.PrintCmdDebug(t, cmd)

				var stdoutBuf, stderrBuf bytes.Buffer
				cmd.Stdout = &stdoutBuf
				cmd.Stderr = &stderrBuf
				cmd.Env = append(os.Environ(), "TZ=UTC", "LOG_LVL=0")
				err := cmd.Run()

				assert.Equal(t, tc.code, cmd.ProcessState.ExitCode())
				assert.Equal(t, tc.expect, stdoutBuf.String())
				// no logs are generated here
				assert.Empty(t, stderrBuf.String())
				assert.Nil(t, err)
			})
		}
	}
}
