# Synthetic.new API Client Module

const url_base = "https://api.synthetic.new"
const usage_route = "/v2/quotas"
const models_route = "/openai/v1/models"
const tokens_route = "/anthropic/v1/messages/count_tokens"
const search_route = "/v2/search"
const chat_route = "/openai/v1/chat/completions"
const completions_route = "/openai/v1/completions"
const embeddings_route = "/openai/v1/embeddings"
const messages_route = "/anthropic/v1/messages"

# Gets API key from opencode storage location
def api_key [] {
  open ~/.local/share/opencode/auth.json | get synthetic.key
}

# Completer that fetches live model IDs from the API
def model-completer [] {
  models | get id
}

# Get subscription usage and quota information
export def usage [
  --raw (-r) # Return unmodified API response
] {
  http get --headers {Authorization: $"Bearer (api_key)"} $"($url_base)($usage_route)"
  | if $raw { $in } else {
    $in
    | update subscription.renewsAt { date humanize }
    | update search.hourly.renewsAt { date humanize }
    | update planWeeklyLimit.nextRegenAt { date humanize }
    | table -e
  }
}

# List available models
export def models [] {
  http get --headers {Authorization: $"Bearer (api_key)"} $"($url_base)($models_route)"
  | get data
}

# Web search API
export def search [
  query: string # Search terms
  --raw (-r) # unmodified API output
] {
  let query = {query: $query} | to json
  http post --headers {Authorization: $"Bearer (api_key)"} $"($url_base)($search_route)" $query
  | if $raw { $in } else {
    get results
  }
}

# Count tokens for a message (subscriber feature)
export def tokens [
  iotype: string@[input output] # Token type
  model: string@model-completer  # Model ID (e.g. hf:zai-org/GLM-4.7)
  content: string # Text to analyze
] {
  let role = match $iotype {
    input => "user"
    output => "assistant"
    _ => (error make {
        msg: $"io-type `($iotype)` not supported."
        help: $"Use one of: [input output]."
        label: {
          text: "unknown type"
          span: (metadata $iotype | get span)
        }
      }
    )
  }
  let body = {
    model: $model
    messages: [
      {role: $role, content: $content}
    ]
  } | to json
  http post --headers {Authorization: $"Bearer (api_key)"} $"($url_base)($tokens_route)" $body
}

# OpenAI-compatible chat completions
# Takes messages with role+content pairs; supports system prompts via --system
export def chat [
  model: string@model-completer    # Model ID (e.g. hf:zai-org/GLM-4.7)
  content: string                  # User message
  --system (-s): string            # System prompt
  --temperature (-t): float        # Sampling randomness (0.0-2.0)
  --max-tokens (-m): int           # Maximum tokens to generate
  --top-p: float                   # Nucleus sampling threshold (0.0-1.0)
  --stop: string                   # Stop sequence
  --raw (-r)                       # Return unmodified API response
] {
  let messages = if $system != null {
    [
      {role: "system", content: $system}
      {role: "user", content: $content}
    ]
  } else {
    [
      {role: "user", content: $content}
    ]
  }
  let body = {model: $model, messages: $messages}
  let body = if $temperature != null {
    $body | insert temperature $temperature
  } else { $body }
  let body = if $max_tokens != null {
    $body | insert max_tokens $max_tokens
  } else { $body }
  let body = if $top_p != null {
    $body | insert top_p $top_p
  } else { $body }
  let body = if $stop != null {
    $body | insert stop $stop
  } else { $body }
  let body = $body | to json

  http post --headers {Authorization: $"Bearer (api_key)"} $"($url_base)($chat_route)" $body
  | if $raw { $in } else {
    {
      model: ($in.model)
      content: ($in.choices.0.message.content)
      usage: {
        prompt_tokens: ($in.usage.prompt_tokens)
        completion_tokens: ($in.usage.completion_tokens)
        total_tokens: ($in.usage.total_tokens)
      }
    }
  }
}

# OpenAI-compatible text completions (legacy single-prompt API)
# No native system prompt support; accepts a single prompt string only
export def complete [
  model: string@model-completer    # Model ID (e.g. hf:zai-org/GLM-4.7)
  prompt: string                   # Text prompt
  --temperature (-t): float        # Sampling randomness (0.0-2.0)
  --max-tokens (-m): int           # Maximum tokens to generate
  --top-p: float                   # Nucleus sampling threshold (0.0-1.0)
  --stop: string                   # Stop sequence
  --raw (-r)                       # Return unmodified API response
] {
  let body = {model: $model, prompt: $prompt}
  let body = if $temperature != null {
    $body | insert temperature $temperature
  } else { $body }
  let body = if $max_tokens != null {
    $body | insert max_tokens $max_tokens
  } else { $body }
  let body = if $top_p != null {
    $body | insert top_p $top_p
  } else { $body }
  let body = if $stop != null {
    $body | insert stop $stop
  } else { $body }
  let body = $body | to json

  http post --headers {Authorization: $"Bearer (api_key)"} $"($url_base)($completions_route)" $body
  | if $raw { $in } else {
    {
      model: ($in.model)
      content: ($in.choices.0.text)
      usage: {
        prompt_tokens: ($in.usage.prompt_tokens)
        completion_tokens: ($in.usage.completion_tokens)
        total_tokens: ($in.usage.total_tokens)
      }
    }
  }
}

# Create text embeddings (does not count against subscription limits)
export def embed [
  model: string@model-completer    # Model ID (e.g. hf:BAAI/bge-large-en-v1.5)
  input: string                    # Text to embed
  --dimensions: int                # Output embedding dimensions
  --raw (-r)                       # Return unmodified API response
] {
  let body = {model: $model, input: $input}
  let body = if $dimensions != null {
    $body | insert dimensions $dimensions
  } else { $body }
  let body = $body | to json

  http post --headers {Authorization: $"Bearer (api_key)"} $"($url_base)($embeddings_route)" $body
  | if $raw { $in } else {
    {
      model: ($in.model)
      dimensions: ($in.data.0.embedding | length)
      embedding: ($in.data.0.embedding)
      usage: {
        prompt_tokens: ($in.usage.prompt_tokens)
        total_tokens: ($in.usage.total_tokens)
      }
    }
  }
}

# Anthropic-compatible messages API
# System prompt passed as a top-level field (not in messages array); max_tokens required
export def message [
  model: string@model-completer    # Model ID (e.g. hf:zai-org/GLM-4.7)
  content: string                  # User message
  --max-tokens (-m): int = 1024    # Maximum tokens to generate (required by Anthropic API)
  --system (-s): string            # System prompt (top-level field, not a message)
  --temperature (-t): float        # Sampling temperature
  --top-p: float                   # Nucleus sampling parameter
  --top-k: int                     # Top-K sampling limit
  --stop: list<string>             # Stop sequences
  --raw (-r)                       # Return unmodified API response
] {
  let body = {
    model: $model
    messages: [
      {role: "user", content: $content}
    ]
    max_tokens: $max_tokens
  }
  let body = if $system != null {
    $body | insert system $system
  } else { $body }
  let body = if $temperature != null {
    $body | insert temperature $temperature
  } else { $body }
  let body = if $top_p != null {
    $body | insert top_p $top_p
  } else { $body }
  let body = if $top_k != null {
    $body | insert top_k $top_k
  } else { $body }
  let body = if $stop != null {
    $body | insert stop_sequences $stop
  } else { $body }
  let body = $body | to json

  http post --headers {Authorization: $"Bearer (api_key)"} $"($url_base)($messages_route)" $body
  | if $raw { $in } else {
    {
      model: ($in.model)
      stop_reason: ($in.stop_reason)
      content: ($in.content.0.text)
      usage: {
        input_tokens: ($in.usage.input_tokens)
        output_tokens: ($in.usage.output_tokens)
      }
    }
  }
}

# Synthetic.new API Client
export def main [] {
  scope commands
  | where name starts-with "synthetic " and name != "synthetic main"
  | update name { $in | str replace "synthetic " "" }
  | select name description
  | rename command description
  | table -e
}
