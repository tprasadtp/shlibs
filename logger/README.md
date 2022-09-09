# logger

Simple sh logger.

- Supports levelled logging
- Outputs to stderr by default, Optionally log to stdout instead of stderr by setting `LOG_TO_STDOUT=true` or `LOG_TO_STDOUT=1`
- Supports colored logs
- Supports https://bixense.com/clicolors/ and https://no-color.org/ standards.
- Can be used with bash, ash, dash, or zsh.
- Avoids use of global variables for anything other than configuration.
- Avoids global state variables
- No pipes are involded in your log plumbing, Unless you pipe output manually to `log_tail()`

## Dependencies

- `coreutils` or `busybox`

## Levels

| Function | Level |
|---|---|
| `log_trace` | 0
| `log_debug` | 10
| `log_info` | 20
| `log_success` | 20
| `log_warning` | 30
| `log_notice` | 35
| `log_error` | 40
| `log_critical` | 50

- `log_info` and `log_success` have the same level, as it "mapped" to `log_info`, with a tweak to enable colored output when colors are supported or enabled.
- For compatibility, `log()` and `error()` and `info()` functions have been as "mapped" to `log_info()`, `log_info()` and `log_error()` respectively.
- Logging levels are similar to Python. Though it is not identical.


## Experimental Features

- `log_tail` to pipe output of external commands an print them as trace level logs. If an optional argument is specified, all the lines from output will be prefixed with the prefix specified,
- **WARNING** If you use log_tail and without a pipe, your script hangs forever! I dont think there is much that can be done without breaking compatibility.


## Settings

- `LOG_FMT` (string) Log format. Default is `pretty`. Set it to `short` to enable showing level names. Set to any other value to show with timestamps. If stdout and stderr is not terminal, colors are disabled `LOG_FMT` will revert to logs with timestamps.
- `LOG_LVL` (integer) Log Level. Default is `20`. All levels below this value will not be logged.
- `LOG_TO_STDOUT` (boolean) Log to stdout instead of stderr (Default is false). If set to `true` logs will be written to stdout instead of stderr.
- You can set `CLICOLOR_FORCE` to non zero to force colored output.
- You can set `NO_COLOR` to non empty value or `CLICOLOR` to non zero value to disabled colored output. `CLICOLOR_FORCE=1` always takes precedence over others.


## Tests

- Tests are written in go.
- Tests require [faketime](https://github.com/wolfcw/libfaketime).
  - On Ubuntu/Mint `faketime` package is available from universe repository.
  - On Debian `faketime` package is available from repositories
  - On CentOS/Fedora/RHEL package `libfaketime` is available form EPEL repositories.
- Run Tests
  ```bash
  go test -v ./... -count=1
  ```

## Usage

See [`demo.bash`](./demo.sh).
