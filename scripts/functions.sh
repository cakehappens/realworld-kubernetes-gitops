#! /usr/bin/env bash

set -Eeuo pipefail

functions_sourced=0
(return 0 2>/dev/null) && functions_sourced=1

functions_file_previously_sourced=${functions_file_previously_sourced:-0}

if [ "${functions_file_previously_sourced}" = "1" ]; then
    debug "functions already loaded..."
    return 0
fi

log() {
    printf "%b\n" "$*" 1>&2
}

debug() {
    if [ "${DEBUG:-0}" != "0" ]; then
        log "DEBUG: $*"
    fi
}

warn() {
    log "WARN: $*"
}

###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
#
# FUNCTION: BACKTRACE
#
###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##

backtrace() {
    local _start_from_=0

    local params=( "$@" )
    if (( "${#params[@]}" >= "1" ))
        then
            _start_from_="$1"
    fi

    local i=0
    local first=false
    while caller $i > /dev/null
    do
        if test -n "$_start_from_" && (( "$i" + 1   >= "$_start_from_" ))
            then
                if test "$first" == false
                    then
                        log "BACKTRACE IS:"
                        first=true
                fi
                caller $i
        fi
        let "i=i+1"
    done
}

exit_handler() {
    local rc=$?
    debug "performing cleanup"
    debug "will exit with ${rc} after cleanup"
    if [ "${SKIP_TEMP_DIR_CREATION}" = "0" ] && [ -d "${my_temp_dir}" ]; then
        log "🧹 Cleaning up other temp files..."
        rm -rf "${my_temp_dir}"
    fi
    debug "exiting with code: ${rc}"
    exit "${rc}"
}

error_handler() {
    local rc=$?
    local func="${FUNCNAME[1]}"
    local line="${BASH_LINENO[0]}"
    local src="${BASH_SOURCE[0]}"

    log "  called from: $func(), $src, line $line"

    #
    # GETTING BACKTRACE:
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
    _backtrace=$( backtrace 2 )

    log "\n$_backtrace\n"

    log "❌ Something went wrong, and we can't recover. A bug report might be needed..."

    debug "exiting with code: ${rc}"
    exit "${rc}"
}

trap exit_handler EXIT
trap error_handler ERR

debug "Running $0"

SKIP_TEMP_DIR_CREATION=${SKIP_TEMP_DIR_CREATION:-0}
if [ "${SKIP_TEMP_DIR_CREATION}" = "0" ]; then
    my_temp_dir="$(mktemp -d "${TMPDIR:-/tmp/}$(basename "${0}").XXXXXXXXXXXX")"
    debug "Created temp dir: ${my_temp_dir}"
fi

# if script is not sourced (called directly)
if [ "${functions_sourced}" = "0" ]; then
    log "❌ functions.sh was not sourced. It should only be called using 'source path/to/functions.sh'"
    exit 1
fi

green="\e[32m"
reset="\e[00m"
bold="\e[1m"

test_binary() {
    local binary_name="${1}"
    local variable_name="${2}"
    local try_help_message="${3}"
    local print_success="${4-0}"

    if binary_location=$(command -v "${binary_name}" 2>&1); then
        export "${variable_name}=${binary_name}"
        if [ "$print_success" = "1" ]; then
            log "${green}✔${reset} ${binary_name} located [${binary_location}]"
        fi
    else
        log "Could not find ${binary_name} (${try_help_message})"
        exit 1
    fi
}

ensure_gnu_binary() {
    local binary_name="${1}"
    local variable_name="${2}"
    local try_help_message="${3}"
    local print_success="${4-0}"

    local gbinary_name="g${binary_name}"

    #sed_help="$(LANG=C sed --help 2>&1)"
    #if echo "${sed_help}" | grep -q "GNU\|BusyBox"; then
    if LANG=C ${binary_name} --version 2>&1 | grep -q "GNU\|BusyBox"; then
        binary_location=$(command -v "${binary_name}")
        if [ "$print_success" = "1" ]; then
            log "${green}✔${reset} Located ${binary_name} and verified it is gnu/busybox [${binary_location}]"
        fi
        export "${variable_name}=${binary_location}"
    elif command -v "${gbinary_name}" &>/dev/null; then
        binary_location=$(command -v "${gbinary_name}")
        if [ "$print_success" = "1" ]; then
            log "${green}✔${reset} Located ${gbinary_name} [${binary_location}]"
        fi
        export "${variable_name}=${binary_location}"
    else
        log "❌ Failed to find GNU ${binary_name} as ${binary_name} or ${gbinary_name}. ${try_help_message}." >&2
        exit 1
    fi
}

test_sed() {
    ensure_gnu_binary sed SED "If you are on Mac: brew install gnu-sed" "$@"
}

test_grep() {
    ensure_gnu_binary grep GREP "If you are on Mac: brew install grep" "$@"
}

test_sort() {
    ensure_gnu_binary sort SORT "If you are on Mac: brew install coreutils" "$@"
}

test_awk() {
    ensure_gnu_binary awk AWK "If you are on Mac: brew install gawk" "$@"
}

test_date() {
    ensure_gnu_binary date DATE "If you are on Mac: brew install coreutils" "$@"
}

test_tar() {
    ensure_gnu_binary tar TAR "If you are on Mac: brew install gnu-tar" "$@"
}

test_jq() {
    test_binary jq JQ "If you are on Mac: brew install jq" "$@"
}

test_yq() {
    test_binary yq YQ "If you are on Mac: brew install yq" "$@"
}

test_kubeseal() {
    test_binary kubeseal KUBESEAL "If you are on Mac: brew install kubeseal" "$@"
}

test_aws() {
    test_binary aws AWS "If you are on Mac: brew install awscli" "$@"
}

test_http() {
    test_binary http HTTP "If you are on Mac: brew install httpie" "$@"
}

test_jsonnet() {
    test_binary jsonnet JSONNET "Try make dependences.dev.install" "$@"
}

test_circleci() {
    test_binary circleci CIRCLECI "If you are on Mac: brew install circleci" "$@"
}

test_git() {
    test_binary git GIT "If you are on Mac: brew install git && brew link --overwrite git. Then reopen your terminal." "$@"
}

test_terraform() {
    test_binary terraform TERRAFORM "Check out ASDF-VM!" "$@"
}

test_bash() {
    local print_success="${1-0}"

    if LANG=C /usr/bin/env bash --version 2>&1 | grep -q "version 5"; then
      if [ "$print_success" = "1" ]; then
        log "${green}✔${reset} Located bash and verified it is major version 5"
      fi
    else
      log "❌ Failed to find bash major version 5. If you are on Mac: brew install bash. Then reopen your terminal."
      exit 1
    fi
}

test_bash

repo_dir="$(dirname "${scripts_dir}")"

functions_file_previously_sourced=1
