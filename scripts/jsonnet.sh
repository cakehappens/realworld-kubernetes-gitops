#! /usr/bin/env bash
set -Eeuo pipefail

scripts_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "${scripts_dir}/functions.sh"

test_jsonnet
test_yq
test_grep
test_awk

log "🎵 Jsonneting things..."

jsonnet_input_file_path="$1"

jsonnet_tla_strs=()
if tla_str_vars=$(env | $GREP "^JSONNET_TLA_STR__"); then
    debug "found JSONNET_TLA_STR__ vars"
    debug "$tla_str_vars"
    while IFS='' read -r line; do jsonnet_tla_strs+=("$line"); done < <(echo "${tla_str_vars}" | $AWK -F'__' '{print $2}')
fi

jsonnet_tla_codes=()
if tla_code_vars=$(env | $GREP "^JSONNET_TLA_CODE__"); then
    debug "found JSONNET_TLA_CODE__ vars"
    debug "$tla_code_vars"
    while IFS='' read -r line; do jsonnet_tla_codes+=("$line"); done < <(echo "${tla_code_vars}" | $AWK -F'__' '{print $2}')
fi

tmp_files_list_file="${my_temp_dir}/jsonnet_files_list.txt"
# I have to wordsplit below
# as it passes option name and option values (that must be separate) to jsonnet
# shellcheck disable=SC2068
$JSONNET \
    ${jsonnet_tla_strs[@]/#/--tla-str } \
    ${jsonnet_tla_codes[@]/#/--tla-code } \
    -J vendor \
    -m "${repo_dir}" "${jsonnet_input_file_path}" \
    > "${tmp_files_list_file}"

files=()
while IFS='' read -r line; do files+=("$line"); done < "${tmp_files_list_file}"

output_files=()
for i in "${files[@]}"
do
    :
    output_file="${i}.yml"
    yq r -P "${i}" | cat "${repo_dir}/.do-not-edit-header" - > "${output_file}"
    
    output_file_short="${output_file/$repo_dir\//}"
    output_files+=("${output_file_short}")
    rm -f "${i}"
done

log "✍️  Created files:"
log "${output_files[@]}"

# two spaces here is not a mistake. Not all emojis have
# the correct spacing to make it show up correct
log "${green}✔${reset}  Jsonneting Things Complete!"
