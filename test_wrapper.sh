_translate_impl() {
    local text=""
    local use_clipboard=0
    for arg in "$@"; do
        if [[ "$arg" == "--clipboard" || "$arg" == "-c" ]]; then
            use_clipboard=1
        else
            text="$text $arg"
        fi
    done
    text=$(echo "$text" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    echo "DEBUG: use_clipboard=$use_clipboard, text='$text'"
}
_translate_impl 어제 작업했던 내용이 뭐가 있었어? -c
