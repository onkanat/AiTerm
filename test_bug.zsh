source src/core/smart_execute_v2.zsh

result=$(_call_llm_with_fallback "list files" "command")
echo "RESULT: $result"
