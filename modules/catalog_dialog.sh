#!/bin/bash

_build_checklist_tsv() {
    local category="$1"
    local catalog_path="$2"

    yq -o=json "$catalog_path" | jq -r --arg cat "$category" '
      . as $root |
      if $cat == "all" then
        # Flatten all categories packages and keep only defaults
        ( ($root.categories // [])
          | map(.packages // [])
          | add // [] )
        | map(select((.default // .enabled // false) == true))
      else
        (
          ( ($root.categories // []) | map(select((.id==$cat) or (.name==$cat))) | .[0]?.packages ) //
          ( $root[$cat].packages // $root[$cat] // $root.packages // [] )
        )
      end
      | map({
          id: (.id // .name // .slug),
          label: ((.brew_type // .type // "cli") + " — " + (.description // "")),
          status: (if (.default // .enabled // false) then "on" else "off" end)
        })
      | .[] | [ .id, .label, .status ] | @tsv
    '
}

select_packages_from_catalog() {
    local category="$1"
    local catalog_path="$2"

    if [[ -z "$category" ]]; then
        log_error "Category is required"
        return 1
    fi

    if [[ -z "$catalog_path" ]]; then
        catalog_path="./catalog.yaml"
    fi

    if [[ ! -f "$catalog_path" ]]; then
        log_error "Catalog file not found: $catalog_path"
        return 1
    fi

    require_tool dialog || return 1
    require_tool yq || return 1
    require_tool jq || return 1

    local tsv tmpfile args status
    tsv=$(_build_checklist_tsv "$category" "$catalog_path") || return 1

    if [[ -z "$tsv" ]]; then
        log_warn "No packages found in category: $category"
        return 0
    fi

    args=()
    echo "$tsv" | while IFS=$'\t' read -r tag item def; do
        printf '%s\n' "$tag" "$item" "$def"
    done > /tmp/.catalog_args_$$

    while IFS= read -r line; do
        args+=("$line")
    done < /tmp/.catalog_args_$$
    rm -f /tmp/.catalog_args_$$

    tmpfile=$(mktemp -t catalog_selection.XXXXXX)

    local title
    if [[ "$category" == "all" ]]; then
        title="Default Packages"
    else
        title="${category} Packages"
    fi

    dialog --clear \
           --title "$title" \
           --ok-label "OK" \
           --cancel-label "Cancel" \
           --checklist "Select packages:" 20 75 12 \
           "${args[@]}" 2>"$tmpfile"
    status=$?

    clear

    if [[ $status -ne 0 ]]; then
        rm -f "$tmpfile"
        log_info "Selection cancelled. No packages will be installed."
        return 0
    fi

    local selection
    selection=$(cat "$tmpfile")
    rm -f "$tmpfile"

    selection=${selection//\"/}

    if [[ -z "$selection" ]]; then
        log_info "No packages selected."
        return 0
    fi

    local packages
    packages="$selection"

    log_info "Selected packages: $packages"
    install_brew_packages $packages
}

export -f select_packages_from_catalog
