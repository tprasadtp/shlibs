# shellcheck shell=bash
#shellcheck disable=SC2164

set -e

SCRIPTPATH="$(
  cd -- "$(dirname "$0")" >/dev/null 2>&1
  pwd -P
)"

if [ -e $SCRIPTPATH/logger.sh ]; then
  #shellcheck source=/dev/null
  . "$SCRIPTPATH"/logger.sh
else
  echo "$SCRIPTPATH/logger.sh not found"
  exit 1
fi

log_trace "This is trace level"
log_trace "This is trace level"
log_trace "This is trace level"

log_debug "This is debug level"
log_debug "This is debug level"

log_info "This is info level"
log_info "This is info level"
log_info "This is info level"
log_info "This is info level"
log_info "This is info level"
log_info "This is info level"
log_info "This is info level"

log_success "This is success level"
log_notice "This is notice level"
log_warning "This is warning level"
log_warning "This is warn level"
log_error "This is error level"
log_critical "This is critical level"

__logger_core_event_handler "unknown" "This is internal log handler and should not be called, but is here for unit testing only."


printf "Multi line: LINE 1 (no-prefix)\n Multi line: LINE 2 (no-prefix)\n" | log_tail
printf "Multi line: LINE 1 (with-prefix)\n Multi line: LINE 2 (with-prefix)\n" | log_tail "printf"
