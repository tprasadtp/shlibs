# Checks if given input is an integer
math__is_integer(){
    case "$1" in
    ("" | *[!0-9]*)
    return 1
    ;;
    *)
    return 0
    ;;
    esac
}