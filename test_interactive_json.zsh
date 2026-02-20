source src/core/smart_execute_v2.zsh

# Real Ollama returns the LLM's raw text inside a "response" field
_call_llm_provider() {
    echo '{"response": "{\"command\": \"ls -la\"}"}'
}

# we test `_call_llm_with_fallback` instead to see parsing
res=$(_call_llm_with_fallback "list files" "command")
echo "FINAL RES: $res"
