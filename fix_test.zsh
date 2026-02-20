source src/core/smart_execute_v2.zsh
zle() { echo "zle called with: $@" }
BUFFER="@list files"

# We deliberately fail _check_session_timeout by echo'ing a warning and returning 1
# This simulates the user's issue.
smart_accept_line
