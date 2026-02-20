source src/core/smart_execute_v2.zsh

# Mock zle functionality for a script test
zle() { echo "zle called with: $@" }
BUFFER="@list files"

smart_accept_line
