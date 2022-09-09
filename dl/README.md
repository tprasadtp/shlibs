# Download library

## Features

- Checksum verification via checksum file, checksum hash, file containing just hash from local or http(s) locations.
- Supports sha1, sha256, sha512 and md5 hashes
- GPG signature verification of checksum file or asset file, depending on which is specified.
- Supports templated parameters with placeholders for GOOS (`++GOOS++`), GOARCH (`++GOARCH++`), GOARM (`++GOARM++`), uname -m (`++SYS_ARCH++`) and uname -s (`++SYS_OS++`).
- Uses logger library for easy debuggingg and diagnostics `LOG_LVL=0`
- Clear defined exit codes with human readable explanations and helper function to decode it if necessary `libdl_err_map`
- Attempts to work with minimal existing tools wherever possible. i.e use `gpgv` instead of `gpg`
- Supports passing Auth tokens in headers for private downloads via `Authorzation: token` or `Authorization: Bearer` header.
- Multiple attempts are made to download the file using curl's `--retry` options to avoid transient errors.
- Option to override default user agent (`tprasadtp/shlibs/dl/v1`)

## API

### `shlib_download_file`

### `libdl_print_error`

- `libdl_print_error [0-127]`
    This is used to decode return codes from `shlib_download_file` with a human readable explanation.
    Known error codes `0`, unknown or invalid error codes return `1`. Messages are printed using logger library, and this follows all logger settings.

## Requirements

- Non ancient version of `curl` or `wget` (including the one bundled with busybox)
- `ca-certificates` if using https URLs
- `coreutils` or `busybox`

## Tests

- Tests are written in go (>1.17) and use docker to emulate some conditions of the filesystem.
- Tests require docker with buildkit enabled.
- Run Tests
  ```bash
  go test -v ./... -count=1
  ```
