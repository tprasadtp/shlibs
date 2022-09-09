# shellcheck shell=sh
# shellcheck disable=SC3043,SC2119

# tprasadtp/shlibs/dl/dl.sh

# DEPENDS ON LOGGING LIBRARY
# Requires
# - wget/curl for downloading
#
# - For checksum verification:
#   - gsha256sum/sha256sum/shasum/rhash - for SHA256
#   - gsha512sum/sha512sum/shasum/rhash - for SHA512
#   - gsha1/sha1sum/shasum/rhash        - for SHA1
#   - gmd5sum/md5sum/rhash              - for MD5
#
# - For signature verification
#   - gpgv/gpg                          - if gpg key/signature is binary
#   - gpg                               - if gpg key/signature is ascii armored
#
# See https://github.com/tprasadtp/shlibs/dl/README.md
# If included in other files, contents between snippet markers is
# automatically updated and all changes between markers will be ignored.

# ERRORS
shlib_explain_error() {

    local err_code="${1}"

    case ${err_code} in
    0) ;;
    # We should never return 1 or 127
    1 | 127) printf "[ERROR ] An unhandled exception occured!\n" ;;
    # Assume we do not have logging functions available either.
    2)
        printf "[ERROR ] Dependency Error.\n"
        printf "[ERROR ] This script requires logger library from https://github.com/tprasadtp/shlibs/logger\n"
        printf "[ERROR ] Please source it or embed it in file before using dl library.\n"
        ;;
    3)
        log_error "Invalid, Unsupported or not enough arguments"
        ;;
    4)
        log_error "--shlib-id must be the only argument/option"
        ;;
    # Token/Auth Errors
    5) log_error "Authorization token specified is empty" ;;
    6) log_error "Bearer token specified is empty" ;;
    8) log_error "Output destination is not writable" ;;
    9) log_error "GPG Key specified is invalid" ;;
    11)
        log_error "Failed to detect and map GOOS/GOARCH/GOARM!"
        __libdl_repo _error_helper
        ;;
    12)
        log_error "Internal Error! Invalid arguments!"
        ;;
    14)
        log_error "Failed to determine system architecture or os."
        __libdl_repo _error_helper
        ;;
    15)
        log_error "Failed to determine verificataion handler."
        __libdl_repo _error_helper
        ;;
    # URL user errors
    16) log_error "File URL specified is invalid. (URL MUST start with http:// or https://)" ;;
    17)
        log_error "Checksum specified is invalid. (URL MUST start with http:// or https://)"
        log_error "If checksum is directly specified, ensure that it matches the algorithm specified."
        ;;
    18)
        log_error "Signature specified is invalid."
        log_error "If GPG signature is URL, it MUST start with http:// or https://"
        log_error "If GPG signature is a local file, it must be readable"
        ;;
    19)
        log_error "GPG Key/keyring specified is invalid."
        log_error "If key is URL, it MUST start with http:// or https://"
        log_error "If keys is specified as KEY ID, make sure to specify LONG key ID."
        log_error "If keys are already in your keyring, skip specifying it manually, or use key ID"
        ;;

    21)
        log_error "This script requires curl or wget, but both of them were not installed or not available."
        # HPC systems with lmod cause issues when matlab is loaded
        if [ -n "$LOADEDMODULES" ] && __libdl_has_command "module"; then
            log_error "If using LMOD & MATLAB, it can interfere with curl libraries(libcurl) on CentOS 7/RHEL-7/macOS"
            log_error "Please unload all modules via - module purge, before running this script."
        fi
        ;;

    22)
        log_error "Cannot find any of: sha256sum, gsha256sum, or shasum, required for SHA256 checksum verification."
        # shellcheck disable=SC2155
        local __libdl_errmap_os="$(libdl_get_GOOS)"
        case $__libdl_errmap_os in
        Linux)
            log_error "sha256sum is provided by package coreutils. Install it via package manager."
            ;;
        Darwin)
            log_error "sha256sum is not available by default, install coreutils via Homebrew"
            ;;
        esac
        ;;

    23)
        log_error "Cannot find any of: sha512sum, gsha512sum or shasum, required for SHA512 checksum verification."
        # shellcheck disable=SC2155
        local __libdl_errmap_os="$(libdl_get_GOOS)"
        case $__libdl_errmap_os in
        Linux)
            log_error "sha512sum is provided by package coreutils. Install it via package manager."
            ;;
        Darwin)
            log_error "sha512sum is not available by default, install coreutils via Homebrew"
            ;;
        esac
        ;;

    24)
        log_error "Cannot any any of: sha1sum, gsha1sum or shasum, Required for SHA1 checksum verification."
        # shellcheck disable=SC2155
        local __libdl_errmap_os="$(libdl_get_GOOS)"
        case $__libdl_errmap_os in
        Linux)
            log_error "sha1sum is provided by package coreutils or busybox. Install it via package manager."
            ;;
        Darwin)
            log_error "sha1sum should be available by default. Alternatively install coreutils via Homebrew"
            ;;
        esac
        ;;

    25)
        log_error "Cannot any any of: md5sum or gmd5sum, Required for MD5 checksum verification."
        # shellcheck disable=SC2155
        local __libdl_errmap_os="$(libdl_get_GOOS)"
        case $__libdl_errmap_os in
        Linux)
            log_error "md5sum is provided by package coreutils or busybox. Install it via package manager."
            ;;
        Darwin)
            log_error "md5sum should be available by default. Alternatively install coreutils via Homebrew"
            ;;
        esac
        ;;

    26)
        log_error "Cannot find command gpg which is required for signature verification."
        # shellcheck disable=SC2155
        local __libdl_errmap_os="$(libdl_get_GOOS)"
        case $__libdl_errmap_os in
        Linux)
            log_error "Command gpg is usually provided by package gnupg or gpg. Install it via package manager."
            ;;
        Darwin)
            log_error "Please install gnupg via Homebrew - brew install gnupg"
            ;;
        esac
        ;;
    # Checksum Errors
    31) log_error "Target file not found or not accesible." ;;
    32) log_error "Checksum file was not found or not accessible." ;;
    33) log_error "Failed to caclulate checksum for unknown reasons" ;;
    34) log_error "Checksum hash is invalid" ;;
    35) log_error "Checksum file is missing hashes for the target specified or is invalid" ;;
    36) log_error "Unsupported hash algorithm. Only md5, sha1, sha256 and sha512 are supported" ;;
    37) log_error "Remote endpoint returned invalid hash!" ;;

    # Signature errors
    41) log_error "Target file not found or not accesible." ;;
    42) log_error "Signature file was not found or not accessible." ;;
    43) log_error "Keyring file specified was not or not accessible" ;;
    44) log_error "Failed to verify signature for unknown reasons" ;;

    # Path errors
    50) log_error "Temp dir is not writable or tempdir creation failed" ;;
    51) log_error "Destination file/directory is not writable" ;;
    52) log_error "Destination directory does not exist" ;;
    53) log_error "Destination file exists but checksum verification is not enabled, Must use --overwrite or --force" ;;

    # Download Errors
    # 61 is internal err, should never be seen by end user as other code handles this
    61) log_error "Failed to fetch remote data after multiple attempts" ;;
    62) log_error "Checksum verification was enabled via remote file, but failed to fetch it after multiple attempts!" ;;
    63) log_error "GPG singature verification was enabled remote key file, but failed to fetch it after multiple attempts!" ;;
    64) log_error "GPG singature verification was enabled remote signature file, but failed to fetch it after multiple attempts!" ;;
    68)
        log_error "Remote endpoint retuned empty response!"
        log_error "If its a bug in the parser please report this error at github.com/tprasadtp/shlibs"
        ;;
    70) log_error "Remote data URL is invalid or not supported!" ;;
    72) log_error "Downloading file failed! Please verify that the URL is accessible with correct credentials." ;;

    # Verification errors
    80) log_error "Checksum verification failed!" ;;
    81) log_error "GPG signature check failed!" ;;

    # IOErrors
    100) log_error "Failed to replace existing file" ;;
    101) log_error "Failed to cleanup temporary files" ;;
    102) log_error "Exsting output path is a directory and cannot be overwritten" ;;
    103) log_error "Output file already exists!" ;;
    111) log_error "Failed to copy file to output destination, Please verify that output is writable." ;;

    # Unknown
    *)
        log_error "Unknown error: error-code=${err_code}"
        return 1
        ;;
    esac

    return "${err_code}"
}

__libdl_report_error_helper() {
    log_error "Please report this error to https://github.com/tprasadtp/shlibs"
    log_error "Please include following details of following commands in your error report."
    local goos goarm goarch uname_m uname_s

    # Following assignments/subshells will mask return values
    # and its okay to ignore them!
    uname_s="$(uname -s)"
    uname_m="$(uname -m)"

    goos="$(__libdl_GOOS)"
    goarch="$(__libdl_GOARCH)"
    goarm="$(__libdl_GOARM)"

    log_error "System Architecture (uname -m) : ${uname_m:-Undefined}"
    log_error "System Type (uname -s)         : ${uname_s:-Undefined}"
    log_error "Detected GOOS value            : ${goos:-Undefined}"
    log_error "Detected GOARCH value          : ${goarch:-Undefined}"
    log_error "Detected GOARM value           : ${goarm:-Undefined}"

}

# convert `uname -m` to GOARCH and output
# By default function will try to map current uname -m to GOARCH.
# You can optionally pass it as an argument (useful in remote mounted filesystems)
# If cannot conve   will return code is 1
__libdl_GOARCH() {
    local arch
    arch="${1:-$(uname -m)}"
    case $arch in
    x86_64)
        printf "amd64"
        return 0
        ;;
    x86 | i686 | i386)
        printf "386"
        return 0
        ;;
    # arm64 is required to handle apple silicon
    aarch64 | arm64)
        printf "arm64"
        return 0
        ;;
    armv5* | armv6* | armv7* | armv8*)
        printf "arm"
        return 0
        ;;
    esac
    # We failed to map architectures to GOARCH
    return 11
}

# convert `uname -m` to GOARM and output
# By default function will try to map current uname -m to GOARM.
# You can optionally pass it as an argument (useful in remote mounted filesystems)
# If cannot conve   will output empty string!
__libdl_GOARM() {
    local arch
    arch="${1:-$(uname -m)}"
    case $arch in
    x86 | i686 | i386 | x86_64 | aarch64 | arm64)
        return 0
        ;;
    armv7*)
        printf "7"
        return 0
        ;;
    # ARM8 CPU in 32 bit mode
    armv8*)
        printf "7"
        return 0
        ;;
    armv6*)
        printf "6"
        return 0
        ;;
    armv5*)
        printf "5"
        return 0
        ;;
    *)
        return 11
        ;;
    esac
}

# Maps os name to GOOS
# By default function will try to map current uname -s to GOARCH.
# You can optionally pass it as an argument (useful in unit tests)
# Returns 0 and printfs GOOS if supported OS was detected
# otherwise returns 1 and nothing
__libdl_GOOS() {
    local os
    os="${1:-$(uname -s)}"
    case "$os" in
    Linux)
        printf "linux"
        return 0
        ;;
    Darwin)
        printf "darwin"
        return 0
        ;;
    CYGWIN_NT* | Windows_NT* | MSYS_NT* | MINGW*)
        printf "windows"
        return 0
        ;;
    FreeBSD)
        printf "freebsd"
        return 0
        ;;
    esac
    return 1
}

# Check if is a function
# Used for checking imported/sourced logging library
# This is not fool proof as cleverly named aliases
# and binaries can evaluate to true.
__libdl_is_function() {
    case "$(type -- "$1" 2>/dev/null)" in
    *function*) return 0 ;;
    esac
    return 1
}

# checks if all dependency functions are avilable
# We do not check functions in this file as its 99.99% of the cases useless
__libdl_has_depfuncs() {
    local missing="0"
    if ! __libdl_is_function "log_trace"; then
        missing="$((missing + 1))"
    fi

    if ! __libdl_is_function "log_debug"; then
        missing="$((missing + 1))"
    fi

    if ! __libdl_is_function "log_info"; then
        missing="$((missing + 1))"
    fi

    if ! __libdl_is_function "log_success"; then
        missing="$((missing + 1))"
    fi

    if ! __libdl_is_function "log_warning"; then
        missing="$((missing + 1))"
    fi

    if ! __libdl_is_function "log_warn"; then
        missing="$((missing + 1))"
    fi

    if ! __libdl_is_function "log_notice"; then
        missing="$((missing + 1))"
    fi

    if ! __libdl_is_function "log_error"; then
        missing="$((missing + 1))"
    fi

    return "$missing"
}

# Checks if command is available
__libdl_has_command() {
    if command -v "$1" >/dev/null; then
        return 0
    else
        return 1
    fi
    return 1
}

# Checks if curl is available
__libdl_has_curl() {
    if __libdl_has_command curl; then
        if curl --version >/dev/null 2>&1; then
            return 0
        else
            return 1
        fi
    fi
    return 1
}

# Checks if wget is available
__libdl_has_wget() {
    if __libdl_has_command wget; then
        return 0
    else
        return 1
    fi
}

# Checks if gpgv is available
__libdl_has_gpgv() {
    if __libdl_has_command gpgv; then
        if gpgv --version >/dev/null 2>&1; then
            return 0
        else
            return 2
        fi
    fi
    return 1
}

# Checks if gpg is available
__libdl_has_gpg() {
    if __libdl_has_command gpg; then
        if gpg --version >/dev/null 2>&1; then
            return 0
        else
            return 2
        fi
    fi
    return 1
}

## File hashers
## -------------------------------------------------------

# MD5 hash a file
# Returns MD5 hash and return code 0 if successful
__libdl_hash_md5() {
    local target="${1}"
    local hasher_exe="${2:-auto}"
    local hash

    if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
        return 12
    fi

    if [ -z "$target" ] || [ "$target" = "" ]; then
        return 12
    fi

    if [ ! -e "$target" ]; then
        return 31
    fi

    # Hash handler
    if [ -z "$hasher_exe" ] || [ "${hasher_exe}" = "auto" ]; then
        # macOS homebrew
        if __libdl_has_command gmd5sum; then
            hasher_exe="gmd5sum"
        # coreutils/busybox
        elif __libdl_has_command md5sum; then
            hasher_exe="md5sum"
        fi
    fi

    # Hasher
    case $hasher_exe in
    gmd5sum) hash="$(gmd5sum "$target")" || return 33 ;;
    md5sum) hash="$(md5sum "$target")" || return 33 ;;
    *) return 22 ;;
    esac

    # Post processor to extract hash
    # Checksum output is usually <HASH><space><binary-indicator|space><File>
    hash="${hash%% *}"

    if __libdl_is_md5hash "${hash}"; then
        printf "%s" "$hash"
    else
        return 33
    fi
}

# MD5 hash a file
# Returns MD5 hash and return code 0 if successful
__libdl_hash_sha1() {
    local target="${1}"
    local hasher_exe="${2:-auto}"
    local hash

    if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
        return 12
    fi

    if [ -z "$target" ] || [ "$target" = "" ]; then
        return 12
    fi

    if [ ! -e "$target" ]; then
        return 31
    fi

    # Hash handler
    if [ -z "$hasher_exe" ] || [ "${hasher_exe}" = "auto" ]; then
        # macOS homebrew
        if __libdl_has_command gsha1sum; then
            hasher_exe="gsha1sum"
        # coreutils/busybox
        elif __libdl_has_command sha1sum; then
            hasher_exe="sha1sum"
        elif __libdl_has_command shasum; then
            # Darwin, freebsd
            hasher_exe="shasum"
        fi
    fi

    # Hasher
    case $hasher_exe in
    gsha1sum) hash="$(gsha1sum "$target")" || return 33 ;;
    sha1sum) hash="$(sha1sum "$target")" || return 33 ;;
    shasum) hash="$(shasum -a 1 "$target" 2>/dev/null)" || return 33 ;;
    *) return 22 ;;
    esac

    # Post processor to extract hash
    # Checksum output is usually <HASH><space><binary-indicator|space><File>
    hash="${hash%% *}"

    if __libdl_is_sha1hash "${hash}"; then
        printf "%s" "$hash"
    else
        return 33
    fi
}

# SHA256 hash a file
# Returns sha256 hash and return code 0 if successful
__libdl_hash_sha256() {
    local target="${1}"
    local hasher_exe="${2:-auto}"
    local hash

    if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
        return 12
    fi

    if [ -z "$target" ] || [ "$target" = "" ]; then
        return 12
    fi

    if [ ! -e "$target" ]; then
        return 31
    fi

    # Hash handler
    if [ -z "$hasher_exe" ] || [ "${hasher_exe}" = "auto" ]; then
        # macOS homebrew
        if __libdl_has_command gsha256sum; then
            hasher_exe="gsha256sum"
        # coreutils/busybox
        elif __libdl_has_command sha256sum; then
            hasher_exe="sha256sum"
        elif __libdl_has_command shasum; then
            # Darwin, freebsd
            hasher_exe="shasum"
        fi
    fi

    # Hasher
    case $hasher_exe in
    gsha256sum) hash="$(gsha256sum "$target")" || return 33 ;;
    sha256sum) hash="$(sha256sum "$target")" || return 33 ;;
    shasum) hash="$(shasum -a 256 "$target" 2>/dev/null)" || return 33 ;;
    *) return 22 ;;
    esac

    # Post processor to extract hash
    # Checksum output is usually <HASH><space><binary-indicator|space><File>
    hash="${hash%% *}"

    if __libdl_is_sha256hash "${hash}"; then
        printf "%s" "$hash"
    else
        return 33
    fi
}

# SHA512 hash a file
# Returns sha512 hash and return code 0 if successful
__libdl_hash_sha512() {
    local target="${1}"
    local hasher_exe="${2:-auto}"
    local hash

    if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
        return 12
    fi

    if [ -z "$target" ] || [ "$target" = "" ]; then
        return 12
    fi

    if [ ! -e "$target" ]; then
        return 31
    fi

    # Hash handler
    if [ -z "$hasher_exe" ] || [ "${hasher_exe}" = "auto" ]; then
        # macOS homebrew
        if __libdl_has_command gsha512sum; then
            hasher_exe="gsha512sum"
        # coreutils/busybox
        elif __libdl_has_command sha512sum; then
            hasher_exe="sha512sum"
        elif __libdl_has_command shasum; then
            # Darwin, freebsd
            hasher_exe="shasum"
        fi
    fi

    # Hasher
    case $hasher_exe in
    gsha512sum) hash="$(gsha512sum "$target")" || return 33 ;;
    sha512sum) hash="$(sha512sum "$target")" || return 33 ;;
    shasum) hash="$(shasum -a 512 "$target" 2>/dev/null)" || return 33 ;;
    *) return 22 ;;
    esac

    # Post processor to extract hash
    # Checksum output is usually <HASH><space><binary-indicator|space><File>
    hash="${hash%% *}"

    if __libdl_is_sha512hash "${hash}"; then
        printf "%s" "$hash"
    else
        return 33
    fi
}

## Hash Validators
## --------------------------------------------

# check if given string is a md5 hash
# return 0 if true 1 otherwise
__libdl_is_md5hash() {
    local hash="${1}"
    if printf "%s" "$hash" | grep -qE '^[a-f0-9]{32}$'; then
        return 0
    else
        return 1
    fi
}

# check if given string is a sha1 hash
# return 0 if true 1 otherwise
__libdl_is_sha1hash() {
    local hash="${1}"
    if printf "%s" "$hash" | grep -qE '^[a-f0-9]{40}$'; then
        return 0
    else
        return 1
    fi
}

# check if given string is a sha256 hash
# return 0 if true 1 otherwise
__libdl_is_sha256hash() {
    local hash="${1}"
    if printf "%s" "$hash" | grep -qE '^[a-f0-9]{64}$'; then
        return 0
    else
        return 1
    fi
}

# check if given string is a sha512 hash
# return 0 if true 1 otherwise
__libdl_is_sha512hash() {
    local hash="${1}"
    if printf "%s" "$hash" | grep -qE '^[a-f0-9]{128}$'; then
        return 0
    else
        return 1
    fi
}

# Verifies a hash by comparing it with checksum file or a raw hash
# This function produces some output which is not machine readable
# Status codes should be used instead of output which is intended for
# console use and logging.
__libdl_hash_verify() {
    local target="$1"
    local hash="$2"
    local algorithm="${3}"

    if [ "$#" -ne 3 ]; then
        return 12
    fi

    log_trace "Target File    : ${target}"
    log_trace "Hash           : ${hash}"
    log_trace "Type           : ${algorithm}"

    # Check if target exists
    if [ -z "$target" ]; then
        log_error "No target file specified!"
        return 31
    fi

    if ! test -f "$target"; then
        log_error "File not found - $target"
        return 31
    fi

    local mode
    local hash_type

    case ${algorithm} in
    sha256 | sha-256 | SHA256 | SHA-256)
        if __libdl_is_sha256hash "$hash"; then
            mode="hash-raw"
        else
            mode="hash-file"
        fi
        hash_type="sha256"
        ;;
    sha512 | sha-512 | SHA512 | SHA-512)
        if __libdl_is_sha512hash "$hash"; then
            mode="hash-raw"
        else
            mode="hash-file"
        fi
        hash_type="sha512"
        ;;
    sha1 | sha-1 | SHA1 | SHA-1)
        if __libdl_is_sha1hash "$hash"; then
            mode="hash-raw"
        else
            mode="hash-file"
        fi
        hash_type="sha1"
        ;;
    md5 | md-5 | MD5 | MD-5)
        if __libdl_is_md5hash "$hash"; then
            mode="hash-raw"
        else
            mode="hash-file"
        fi
        hash_type="md5"
        ;;
    *)
        log_error "Unsupported hash algorithm - ${algorithm}"
        return 36
        ;;
    esac

    local hash_rc
    local target_basename
    local want got

    # If verifier is hash file, check if it exists
    if [ $mode = "hash-file" ]; then
        if [ ! -f "$hash" ]; then
            log_error "Checksum file not found: ${hash}"
            return 32
        fi

        # Check if checksum file contains just the hash, in that case we verify if
        # checksum is valid and do not look for filename to match, if this check fails, we will
        # Assume file is standard checksum file with filenames and stuff.
        log_trace "Checking if file contains only hash value"
        local __checksum_file_contents checksum_file_contents_is_hash

        # Read checksum file contents into a variable
        __checksum_file_contents="$(cat "${hash}")"
        __checksum_file_contents="$(printf "${__checksum_file_contents}" | tr -d '[:space:]')"

        # check if file contents are hashes
        case ${hash_type} in
        md5)
            if __libdl_is_md5hash "${__checksum_file_contents}"; then
                checksum_file_contents_is_hash="1"
            fi
            ;;
        sha1)
            if __libdl_is_sha1hash "${__checksum_file_contents}"; then
                checksum_file_contents_is_hash="1"
            fi
            ;;
        sha256)
            if __libdl_is_sha256hash "${__checksum_file_contents}"; then
                checksum_file_contents_is_hash="1"
            fi
            ;;
        sha512)
            if __libdl_is_sha512hash "${__checksum_file_contents}"; then
                checksum_file_contents_is_hash="1"
            fi
            ;;
        # We should never reach this
        *)
            log_error "Unsupported hash algorithm - ${algorithm}"
            return 36
            ;;
        esac

        if [ "$checksum_file_contents_is_hash" -eq 1 ]; then
            log_trace "Checksum file contains just ${hash_type} hash"
            log_trace "Skipped looking for corresponding filename!"
            want="${__checksum_file_contents}"
        else
            log_trace "Looking for target ${hash_type} hash in ${hash}"
            # http://stackoverflow.com/questions/2664740/extract-file-basename-without-path-and-extension-in-bash
            target_basename=${target##*/}
            want="$(grep "${target_basename}" "${hash}" 2>/dev/null)"

            # we got hash and filename we need to remove extra stuff and just get the hash
            # Checksum output is usually <HASH><space><binary-indicator|space><File>
            want="${want%% *}"

            # if file does not exist $want will be empty
            case ${hash_type} in
            md5)
                if ! __libdl_is_md5hash "$want"; then
                    log_error "Error! Failed to find MD5 hash corresponding to '$target_basename' in file $hash"
                    return 35
                fi
                ;;
            sha1)
                if ! __libdl_is_sha1hash "$want"; then
                    log_error "Error! Failed to find SHA1 hash corresponding to '$target_basename' in file $hash"
                    return 35
                fi
                ;;
            sha256)
                if ! __libdl_is_sha256hash "$want"; then
                    log_error "Error! Failed to find SHA256 hash corresponding to '$target_basename' in file $hash"
                    return 35
                fi
                ;;
            sha512)
                if ! __libdl_is_sha512hash "$want"; then
                    log_error "Error! Failed to find SHA512 hash corresponding to '$target_basename' in file $hash"
                    return 35
                fi
                ;;
            # we should never reach this
            *)
                log_error "Unsupported hash algorithm - ${algorithm}"
                return 36
                ;;
            esac

        fi # checksum_file_contents_is_hash

    else
        # Raw hash string
        want="$hash"
    fi

    # Compute file hashes
    case ${hash_type} in
    md5)
        got=$(__libdl_hash_md5 "$target")
        hash_rc="$?"
        ;;
    sha1)
        got=$(__libdl_hash_sha1 "$target")
        hash_rc="$?"
        ;;
    sha256)
        got=$(__libdl_hash_sha256 "$target")
        hash_rc="$?"
        ;;
    sha512)
        got=$(__libdl_hash_sha512 "$target")
        hash_rc="$?"
        ;;
    # we should never reach this code
    *)
        log_error "Unsupported hash algorithm - ${algorithm}"
        return 36
        ;;
    esac

    if [ "${hash_rc:-33}" -ne 0 ]; then
        log_error "An error occured while caclulating hash(${algorithm}) for file - ${target}"
        return $hash_rc
    else
        if [ "$want" != "$got" ]; then
            log_error "Target Hash   : ${want}"
            log_error "Expected Hash : ${got}"
            log_error "Result        : MISMATCH"
            return 80
        else
            log_trace "Target Hash   : ${got}"
            log_trace "Expected Hash : ${want}"
            log_trace "Result        : VERIFIED"
            return 0
        fi
    fi
}

# Render URL
__libdl_render_template() {
    local url="${1}"
    local goos goarch goarm version uname_s uname_m

    # Template rendering:GOOS
    case $url in
    *++GOOS++*)
        if __libdl_GOOS >/dev/null; then
            goos="$(__libdl_GOOS)"
            # This would have been ideal, with
            # url="${url//++GOOS++/${goos}}",
            # but posix sh lacks // param substititution.
            # It is highly unlikely that printf would fail,
            # avoiding PIPEFAIL issues
            url="$(printf "%s" "${url}" | sed -e "s/++GOOS++/${goos}/g")"
        else
            return 11
        fi
        ;;
    esac

    # Template rendering:GOARCH
    case $url in
    *++GOARCH++*)
        if __libdl_GOARCH >/dev/null; then
            goarch="$(__libdl_GOARCH)"
            url="$(printf "%s" "${url}" | sed -e "s/++GOARCH++/${goarch}/g")"
        else
            return 11
        fi
        ;;
    esac

    # Template rendering:GOARMsed
    case $url in
    *++GOARM++*)
        if __libdl_GOARM >/dev/null; then
            goarm="$(__libdl_GOARM)"
            url="$(printf "%s" "${url}" | sed -e "s/++GOARM++/${goarm}/g")"
        else
            return 11
        fi
        ;;
    esac

    # Template rendering:SYS_ARCH
    case $url in
    *++SYS_ARCH++*)
        uname_m="$(uname -m)"
        if [ -n "$uname_m" ]; then
            url="$(printf "%s" "${url}" | sed -e "s/++UNAME_M++/${uname_m}/g")"
        else
            return 14
        fi
        ;;
    esac

    # Template rendering:SYS_OS
    case $url in
    *++SYS_OS++*)
        uname_s="$(uname -s)"
        if [ -n "$uname_s" ]; then
            url="$(printf "%s" "${url}" | sed -e "s/++UNAME_S++/${uname_s}/g")"
        else
            return 14
        fi
        ;;
    esac

    printf "%s" "${url}"
}

# Verify signature
__libdl_gpg_verify() {
    local signature="${2}"
    local target="${1}"

    # Use custom keyring
    local keyring="${3}"

    # Runtime variables
    local verification_handler

    log_trace "Target File    : ${target}"
    log_trace "Signature File : ${signature}"
    log_trace "Keyring        : ${keyring:-DEFAULT-KEYRING}"

    if [ "$#" -lt 2 ]; then
        return 12
    fi

    # Check if gpg or gpgv is available
    # gpg will take priority
    if __libdl_has_gpg; then
        verification_handler="gpg"
    elif __libdl_has_gpgv; then
        verification_handler="gpgv"
    else
        return 27
    fi

    # Validate correct tool is available
    # gpgv cannot handle ascii armored keyring files
    if ! test -z "${keyring}"; then
        # check if keyring file is readable
        if ! test -r "${keyring}"; then
            log_error "Keyring file not found - ${keyring}"
            return 43
        fi

        if grep -q "BEGIN PGP PUBLIC KEY BLOCK" "${keyring}"; then
            # we need gpg, gpgv wont work
            if __libdl_has_gpg; then
                verification_handler="gpg"
            else
                return 26
            fi
        fi

    fi

    log_debug "Verify Handler : ${verification_handler}"

    # Target verification
    if [ -z "${target}" ]; then
        log_error "Target file not specified!"
        return 12
    fi

    if ! test -f "$target"; then
        log_error "Target File not found - $target"
        return 41
    fi

    # Check if signature exists
    if [ -z "$signature" ]; then
        log_error "No signature file specified!"
        return 12
    fi

    if ! test -f "$signature"; then
        log_error "Signature File not found - $target"
        return 42
    fi

    # Verify
    case ${verification_handler} in
    gpg)
        if test -z "${keyring}"; then
            if gpg --verify "${signature}" "${target}" >/dev/null 2>&1; then
                log_trace "Signature      : VERIFIED"
                return 0
            else
                log_error "Signature      : FAILED"
                return 81
            fi
        else
            if gpg --verify --keyring "${keyring}" "${signature}" "${target}" >/dev/null 2>&1; then
                log_trace "Signature      : VERIFIED"
                return 0
            else
                log_trace "Signature      : FAILED"
                return 81
            fi
        fi
        return 81
        ;;
    gpgv)
        if test -z "${keyring}"; then
            if gpgv "${signature}" "${target}" >/dev/null 2>&1; then
                log_trace "Signature      : VERIFIED"
                return 0
            else
                log_trace "Signature      : FAILED"
                return 81
            fi
        else
            if gpg --keyring "${keyring}" "${signature}" "${target}" >/dev/null 2>&1; then
                log_trace "Signature      : VERIFIED"
                return 0
            else
                log_trace "Signature      : FAILED"
                return 81
            fi
        fi
        return 81
        ;;
    *)
        return 15
        ;;
    esac

}

__libdl_dl_asset() {
    # Takes 2 arguments, url, output path
    # Optionally you can specify additional header and user agent,
    # as 3rd and 4th arguments

    if [ "$#" -lt 2 ]; then
        return 12
    fi

    local url output
    local http_code
    local auth_header
    local user_agent

    url="${1}"
    output="${2}"

    auth_headers="${3}"
    user_agent="${4:-shlib/dl/v1}"

    case ${url} in
    http://* | https://*)
        log_trace "asset url looks valid"
        ;;
    *)
        log_trace "asset url only supports http(s):// urls."
        return 12
        ;;
    esac

    if [ -z "${output}" ]; then
        log_trace "asset output not specified!"
        return 12
    fi

    if [ ! -w "$(dirname "${output}")" ]; then
        log_trace "asset output destination is not writable!"
        return 12
    fi

    log_trace "asset=${url}, output=${output}"

    # Handlers
    if __libdl_has_curl && test -n "${auth_headers}"; then
        if curl --silent --show-error \
            --user-agent "${user_agent}" \
            --header "${auth_headers}" \
            --location --fail \
            --retry 5 --progress-bar \
            --output "${output}" "${url}"; then
            log_trace "asset download successful (with auth)"
            return 0
        else
            log_trace "asset download failed (with auth)"
            return 61
        fi
    elif __libdl_has_curl && test -z "${auth_headers}"; then
        if curl --silent --show-error \
            --user-agent "${user_agent}" \
            --location --fail \
            --retry 5 --progress-bar \
            --output "${output}" "${url}"; then
            log_trace "asset download successful (without auth)"
            return 0
        else
            log_trace "asset download failed (without auth)"
            return 61
        fi

    # TODO: detect if busybox wget is in use
    # we do not add a progress bar and other fancy features.
    # as wget may be from busybox. may be we should detect that,
    # and handle it?
    elif __libdl_has_wget; then
        if wget -q --tries=5 \
            -U "${user_agent}" \
            "${auth_header_args}" \
            --header "${auth_header_args}" \
            --output-document "${output}" "${url}"; then
            log_trace "asset download successful"
            return 0
        else
            return 61
        fi
    else
        # No handlers for remote data/file fetch!
        return 21
    fi
}

__libdl_dl_help() {
    cat <<EOF
shlib/dl (shlib-id: 8a45258c-4346-4cc6-9c98-d2dac5446124)

Usage: shlib_download_file [OPTION]...

Arguments:
  None

Options:
  --url                 URL
  --output              Output filename
  --checksum            Checksum (file|url|raw)
  --checksum-algorithm  Checksum algorithm (md5|sha1|sha256|sha512)
  --gpg-signature       GPG Signature (file|url)
  --gpg-key             GPG Key (file|url|key-id)
  --user-agent          Override default user-agent (shlib/dl/v1)
  --(bearer|auth)-token Bearer token/Auth token to use for downloading assets,
                        checksums and gpg-signature. Tokens headers are never used
                        for fetching gpg keys. Only one of these can be used.
  --force               Overwrite existing file
  --shlib-id            Prints shlib-id to stdout
  --help                Prints this help message

Environment:
  LOG_LVL             Set this to 0 to enable trace logs
  LOG_TO_STDIUT       Set this to 'true' to log to stdout.
  NO_COLOR            Set this to NON-EMPTY to disable all colors.
  CLICOLOR_FORCE      Set this to NON-ZERO to force colored output.
EOF

}

# Main download file handler.
# This will be called recursively if checksum and gpg keys are remote.
# URLs supports placeholders for GOOS, GOARCH, GOARM,
# SYS_ARCH(uname -m) and SYS_OS(uname -r)
shlib_download_file() {
    # shlib-id ignores all other options, this it mus tbe used exclusively
    if [ "$1" = "--shlib-id" ]; then
        printf "8a45258c-4346-4cc6-9c98-d2dac5446124"
        return 0
    elif [ "$1" = "--help" ]; then
        __libdl_dl_help
        return 0
    # at-leaset remote url and local file must be specified
    elif [ "$#" -lt 4 ]; then
        return 3
    fi

    local remote_url local_file

    local checksum
    local checksum_algo

    local gpg_signature

    local gpg_key

    local user_agent="shlib/dl/v1"
    local user_agent_override="0"

    local force="0"

    local auth_token
    local auth_token_enable="0"

    local bearer_token
    local bearer_token_enable="0"

    local extra_headers
    local auth_header

    # Lack of support for short options is intentional
    # developers are expected to wrap this in their own wrapper script
    # and provide short options or overrides.
    while [ "${1}" != "" ]; do
        case ${1} in
        --help)
            __libdl_dl_help
            return
            ;;
        --url)
            shift
            remote_url="${1}"
            ;;
        --output)
            shift
            output_file="${1}"
            ;;
        --checksum)
            shift
            checksum="${1}"
            ;;
        --checksum-algorithm)
            shift
            checksum_algo="${1}"
            ;;
        --gpg-signature)
            shift
            gpg_signature="${1}"
            ;;
        --gpg-key)
            shift
            gpg_key="${1}"
            ;;
        --force)
            shift
            force=1
            ;;
        --auth-token)
            shift
            auth_token_enable="1"
            auth_token="${1}"
            ;;
        --bearer-token)
            shift
            bearer_token_enable="1"
            bearer_token="${1}"
            ;;
        --user-agent)
            shift
            user_agent_override="1"
            user_agent="${1}"
            ;;
        --shlib-id)
            return 4
            ;;
        *)
            log_error "Invalid argumet - ${1}"
            return 12
            ;;
        esac
        shift
    done
    log_debug "File URL              : ${remote_url}"
    log_debug "Output path           : ${output_file}"

    # destination path checks
    if [ -z "${output_file}" ]; then
        log_error "Output file is not specified!"
        return 4
    elif [ ! -w "$(dirname "${output_file}")" ]; then
        log_error "Destination is not writable!"
        return 31
    fi

    # token conflict check
    if [ "${auth_token_enable}" -eq 1 ] && [ "${bearer_token_enable}" -eq 1 ]; then
        log_error "Using --auth-token and --bearer-token at the same time is not supported!"
        return 3
    fi

    # Auth token checks
    # --------------------------------------------------------------------------
    if [ "${auth_token_enable}" -eq 1 ]; then
        # Check for zero length token
        if [ "${#auth_token}" -lt 1 ]; then
            log_error "Authorization token specified is empty!"
            return 5
        fi

        log_debug "Authorization Token   : Enabled"

        # check if token is github refresh token
        case ${auth_token} in
        ghr_*)
            log_error "This token looks like GitHub refresh token, which is unsupported for fetch operations!"
            return 5
            ;;
        ghu_*)
            log_error "This token looks like GitHub user-to-server token, which is unsupported for fetch operations!"
            return 5
            ;;
        ghp_*)
            log_debug "GitHub PAT            : ghp_**********"
            ;;
        ghs_*)
            log_debug "GitHub Server Token   : ghs_**********"
            ;;
        gho_*)
            log_debug "GitHub Oauth Token    : gho_**********"
            ;;
        *)
            log_debug "Authorization Token   : **************"
            ;;
        esac

        # Define extra headers
        auth_header="Authorization: token ${auth_token}"

    fi

    # Bearer token checks
    # --------------------------------------------------------------------------
    if [ "${bearer_token_enable}" -eq 1 ]; then
        # Check for zero length token
        if [ "${#bearer_token}" -lt 1 ]; then
            log_error "Bearer token specified is empty!"
            return 5
        fi
        log_debug "Bearer Token          : Enabled"

        # check if token is github token
        case ${bearer_token} in
        ghp_* | ghu_* | ghs_* | gho_* | ghr_*)
            log_error "Bearer Token (GH)     : **************"
            log_error "This token looks like GitHub token."
            log_error "Use --auth-token option instead!"
            return 5
            ;;
        *)
            log_debug "Bearer Token          : **************"
            ;;
        esac

        # Define extra headers
        auth_header="Authorization: Bearer ${bearer_token}"
    fi

    # User agent overide check
    if [ "${user_agent_override}" -eq 1 ]; then
        if test -z "$user_agent"; then
            log_error "User agent override specified is empty"
            return 3
        else
            log_debug "User Agent will be set to ${user_agent}"
        fi
    else
        log_trace "No user agent override specified, using shlib/dl/v1"
        user_agent="shlib/dl/v1"
    fi

    # Check if we need to download gpg key
    # --------------------------------------------------------------------------
    local gpg_key_download="0"
    local gpg_key_download_url

    if test -n "$gpg_key"; then
        # We will ensure that when a key is specified, so must be signature
        if test -z "${gpg_signature}"; then
            log_error "When GPG Key is specified, Signature MUST be specified"
            return 3
        else
            case ${gpg_key} in
            https://* | http://*)
                log_debug "GPG Key               : ${gpg_key}"
                log_debug "GPG Key Type          : Remote URL"
                gpg_key_download="1"
                gpg_key_download_url="${gpg_key}"
                ;;
            *)
                # Check if gpg key ID was given
                if printf "%s" "$gpg_key" | grep -qE '^[a-fA-F0-9]{40}$'; then
                    # First check if key is available in the default keyring
                    log_debug "GPG Key               : ${gpg_key}"
                    log_debug "GPG Key Type          : Key ID"

                    # If GPG is available
                    if __libdl_has_command gpg; then
                        if gpg --keyid-format LONG --list-keys --with-colons "$gpg_key" >/dev/null 2>&1; then
                            log_debug "Key ${gpg_key} is already present in your keyring"
                            gpg_key_download="0"
                        else
                            gpg_key_download="1"
                            log_debug "Key ID not found in default keyring"
                            log_debug "Key will be downloaded, but NOT added to trusted keyrings"
                            gpg_key_download_url="https://keys.openpgp.org/vks/v1/by-fingerprint/${gpg_key}"
                            log_debug "GPG Key               : ${gpg_key}"
                            log_debug "GPG Key Type          : Remote URL(Override Key not found locally)"
                        fi
                    else
                        # gpg not found!
                        log_error "If using Key ID, gpg command is required!"
                        return 26
                    fi

                # check for local file
                elif [ -f "$gpg_key" ] && [ -r "$gpg_key" ]; then
                    gpg_key_download="0"
                    log_debug "GPG Key             : ${gpg_key}"
                    log_debug "GPG Key Type        : Local File"
                elif [ -L "$gpg_key" ]; then
                    log_error "GPG Key cannot be a symlink - ${gpg_key}"
                else
                    log_error "GPG Key was not found or is not readable - ${gpg_key}"
                    return 43
                fi
                ;;
            esac
        fi
        log_debug "No GPG key specified"
    fi

    # Check if we need to download gpg signature
    # In most cases signature should be remote file, but script does support
    # local gpg signature.
    # --------------------------------------------------------------------------
    local gpg_sig_download="0"
    local gpg_verifiy="0"

    if test -z "$gpg_signature"; then
        log_debug "No signature specified, skipped gpg signature verification"
    else
        case ${gpg_signature} in
        https://* | http://*)
            log_debug "GPG Signature         : ${gpg_signature}"
            log_debug "GPG Signature Type    : Remote URL"
            # Render URL from template
            gpg_signature="$(__libdl_render_template "$gpg_signature")"
            rendered_gpg_sig_url_rc="$?"
            if [ "${rendered_gpg_sig_url_rc}" -ne 0 ]; then
                log_error "Failed to render GPG signature URL - ${gpg_signature}"
                return "${rendered_gpg_sig_url_rc}"
            elif test -z "$gpg_signature"; then
                log_error "Rendered gpg signature URL is empty! Did you specify --gpg-signature parameter correctly?"
                return 3
            fi
            gpg_sig_download="1"
            ;;
        *)
            if [ -f "$gpg_signature" ] && [ -r "$gpg_signature" ]; then
                gpg_sig_download="0"
                "GPG Signature       : ${gpg_signature}"
                log_debug "GPG Signature Type  : Local File"
            else
                log_error "GPG Signature file ${gpg_signature} was not found or not readable!"
                return 42
            fi
            ;;
        esac
    fi

    # Check if we need to download checksum
    # In most cases checksum should be remote file, but script does support
    # local checksum file or just raw checksum
    # --------------------------------------------------------------------------
    local checksum_download="0"
    local checksum_verifiy="0"

    if test -z "$checksum"; then
        log_debug "No checksum specified, skipped checksum verification"
    else
        # Check hash algorithm was specified and normalize
        case ${checksum_algo} in
        sha256 | sha-256 | SHA256 | SHA-256)
            checksum_algo="sha256"
            ;;
        sha512 | sha-512 | SHA512 | SHA-512)
            checksum_algo="sha512"
            ;;
        sha1 | sha-1 | SHA1 | SHA-1)
            checksum_algo="sha1"
            ;;
        md5 | md-5 | MD5 | MD-5)
            checksum_algo="md5"
            ;;
        *)
            log_error "Unsupported hash algorithm - ${algorithm}"
            return 36
            ;;
        esac
        log_debug "Checksum Algoritm     : ${checksum_algo}"

        case ${checksum} in
        https://* | http://*)
            log_debug "Checksum              : ${checksum}"
            log_debug "Checksum              : Remote URL"
            # Render URL from template
            checksum="$(__libdl_render_template "$checksum")"
            rendered_checksum_url_rc="$?"
            if [ "${rendered_checksum_url_rc}" -ne 0 ]; then
                log_error "Failed to render URL - ${checksum}"
                return "${rendered_url_rc}"
            elif test -z "$checksum"; then
                log_error "Rendered checksum URL is empty! Did you specify --checksum parameter correctly?"
                return 3
            fi
            checksum_download="1"
            ;;
        *)
            log_debug "Checksum              : ${checksum}"
            if [ -f "$checksum" ] && [ -r "$checksum" ]; then
                log_debug "Checksum              : Local File"
            elif __libdl_is_md5hash "${checksum}"; then
                log_debug "Checksum              : MD5-Hash"
            elif __libdl_is_sha1hash "${checksum}"; then
                log_debug "Checksum              : SHA1-Hash"
            elif __libdl_is_sha256hash "${checksum}"; then
                log_debug "Checksum              : SHA256-Hash"
            elif __libdl_is_sha512hash "${checksum}"; then
                log_debug "Checksum              : SHA512-Hash"
            else
                log_error "Invalid checksum/checksum file or url - ${checksum}"
                return 32
            fi
            ;;
        esac
    fi

    # create temp folder
    log_debug "Creating temporary working directory"
    local temp_wdir

    temp_wdir="$(mktemp -q -d 2>/dev/null)"
    if [ -d "${temp_wdir}" ]; then
        log_debug "Creating temp dir succeded, artifacts will be downloaded to ${temp_wdir}"
    else
        return 50
    fi

    # download gpg key if required and save it to a temp location
    if [ ${gpg_key_download} -eq 1 ]; then
        log_debug "Downloading GPG key"

        local dl_gpg_key_rc=1
        __libdl_dl_asset "${gpg_key_download_url}" "${temp_wdir}/gpg.keys"
        dl_gpg_key_rc="$?"

        case ${dl_gpg_key_rc} in
        0)
            log_trace "Setting keyring to downloaded key file"
            log_trace "This may not work with old gpg versions"
            # set local keyring
            gpg_keyring="${temp_wdir}/gpg.keys"
            ;;
        61) return 63 ;;
        *) return ${dl_gpg_key_rc}

        esac
    else
        log_debug "Skipped downloading GPG keys"
    fi

    # download signature if required and save it to a temp location
    if [ "${gpg_sig_download}" -eq 1 ]; then
        log_info "Downloading : GPG signature"

        local dl_gpg_sig_rc
        __libdl_dl_asset "${gpg_signature}" "${temp_wdir}/gpg.sig" "${auth_header}" "${user_agent}"
        dl_gpg_sig_rc="$?"

        if [ "${dl_gpg_sig_rc}" -ne 0 ]; then
            return 64
        else
            log_trace "Setting signature to downloaded key file"
            # set local signature file
            gpg_signature="${temp_wdir}/gpg.sig"
        fi
    else
        log_trace "Skipped downloading GPG signature"
    fi

    # download checksum if required and save it to a temp location
    if [ "${checksum_download}" -eq 1 ]; then
        log_info "Downloading : Checksums (${checksum_algo})"

        local dl_checksum_rc
        __libdl_dl_asset "${checksum}" "${temp_wdir}/checksums.txt" "${auth_header}" "${user_agent}"
        dl_checksum_rc="$?"

        if [ "${dl_checksum_rc}" -ne 0 ]; then
            return 62
        else
            log_trace "Setting checksum to downloaded file"
            # set local checksums file
            checksum="${temp_wdir}/checksums.txt"
        fi
    else
        log_trace "Skipped downloading checksms"
    fi

    # download file
    local dl_asset_rc dl_asset_basename rendered_url rendered_url_rc

    # Render URL from template
    rendered_url="$(__libdl_render_template "$remote_url")"
    rendered_url_rc="$?"
    if [ "${rendered_url_rc}" -ne 0 ]; then
        log_error "Failed to render URL - ${remote_url}"
        return "${rendered_url_rc}"
    elif test -z "$rendered_url"; then
        log_error "Rendered URL is empty! Did you specify --url parameter correctly?"
        return 3
    fi

    # TODO: Strip query parameters from if present
    dl_asset_basename="$(basename "$rendered_url")"

    log_info "Downloading : ${dl_asset_basename}"
    __libdl_dl_asset "${rendered_url}" "${temp_wdir}/${dl_asset_basename}" "${auth_header}" "${user_agent}"
    dl_asset_rc="$?"

    # Abort if dl failed
    if [ "${dl_asset_rc}" != "0" ]; then
        return 72
    fi

    # gpg verification
    local gpg_verifiy_rc
    if test -n "${gpg_signature}"; then
        # check if checksum is specified, if so, gpg signature is verified for checksum file
        if test -n "${checksum}"; then
            log_info "Verifying : GPG signature of checksum file"
            __libdl_gpg_verify "${gpg_signature}" "${checksum}" "${gpg_keyring}"
            gpg_verifiy_rc="$?"
            log_trace "GPG verify returned - ${gpg_verifiy_rc}"
            if [ "${gpg_verify_rc}" != "0" ]; then
                return ${gpg_verify_rc}
            fi
        else
            log_info "Verifying : GPG signature of asset file"
            __libdl_gpg_verify "${gpg_signature}" "${temp_wdir}/${dl_asset_basename}" "${gpg_keyring}"
            gpg_verifiy_rc="$?"
            if [ "${gpg_verify_rc}" != "0" ]; then
                return "${gpg_verify_rc}"
            fi
        fi
    else
        log_debug "Skipped verifying GPG signature"
    fi

    # Checksum verification
    local hash_rc
    if test -n "${checksum}"; then
        log_info "Verifying : Checksums"
        __libdl_hash_verify "${temp_wdir}/${dl_asset_basename}" "${checksum}" "${checksum_algo}"
        hash_rc="$?"
        if [ "${hash_rc}" -ne 0 ]; then
            return "${hash_rc}"
        fi
    else
        log_debug "Skipping checksum verification"
    fi

    # check if destinaton file exists
    if [ -e "${output_file}" ]; then
        if [ "${force}" -eq 1 ]; then
            if [ -f "${output}" || -L "${output_file}" ]; then
                log_debug "Removing existing file -${output_file}"
                if rm "${output_file}"; then
                    log_debug "Unlinked ${output_file}"
                else
                    return 100
                fi
            else
                log_error "--force can only overwrite files and symnlinks!"
                return 3
            fi
        else
            log_error "${output} already exists, use --force to overwrite it"
            return 103
        fi
    else
        if mv "${temp_wdir}/${dl_asset_basename}" "${output_file}"; then
            log_debug "Copied downloaded file to ${output_file}"
        else
            return 111
        fi
    fi

    log_trace "Cleanup temporary files"
    if rm -rf /tmp/"$(dirname "${temp_wdir}")"; then
        log_debug "Cleanup complete"
    else
        return 101
    fi
}
