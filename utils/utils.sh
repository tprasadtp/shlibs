# Checks if given input is systemd invocation id
is_invocation_id(){
    if printf "%s" "$1" | grep -qE '^[A-Za-f0-9]{16}$'; then
        return 0
    else
        return 1
    fi
}
