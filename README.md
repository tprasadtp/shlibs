# shlibs

Portable easy to use shell libraries

## Supported shells

| Shell              | Supported
|--------------------|----
| Bash               | ✅
| Bash (macOS)       | ✅
| Zsh                | ✅
| dash               | ✅
| ash                | ✅
| Bash (Git-Windows) | ✅
| Cygwin             | ✅
| Fish               | ❌
| Powershell         | ❌
| tcsh               | ❌

> - Scripts with a supported shebang like `#!/bin/bash` will still work in unsupported shells.


## Features

- We dont care much about POSIX  standard as long as it works accross ALL supported shells. Only non POSIX feature used is `local` keyword, but most shells including dash and ash implement it anyway. See [this](https://github.com/koalaman/shellcheck/wiki/SC3043).
- Extensive unit tests

## Roadmap

### dl

- [ ] HTTP Proxy support
- [ ] More unit tests
- [ ] Better integration with GitHub releases
- [ ] Cloudfront/S3 signed URL support
- [ ] Support for Google Cloud storage

### logger

- [x] Ability to pipe output from other commands/functions to logger (Still experimental)
- [ ] Prevent blocking read for `log_tail` and silently return on empty input.

## Testing

- Unit tests are written in Go.
- Some unit tests require docker with buildkit support enabled.
- Some unit tests require `faketime`
- Unit tests expect following shells to be present on your system `bash`, `dash` and `zsh`

## Development

- Almost all other libraries use logger library as a dependency.
- You can `export LOG_LVL=0`, before running any script to get debug and trace level logs.
- Logs are written to stderr and this should not be changed if running unit tests.
