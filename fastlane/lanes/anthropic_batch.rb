# frozen_string_literal: true

require 'json'

# SDK glue for the Anthropic Ruby client: the message create-params shape, response-text extraction, and the
# Message Batches submit/poll/collect cycle. Isolated here so `AITranslator` stays pure prompt-building +
# validation, and all knowledge of the SDK's request/response shape lives in ONE place — the synchronous path
# (`AITranslator.with_anthropic`) and the async batch path share `message_params` / `text_of`, so the request
# shape can't drift between them.
#
# The batch path is the cost/throughput lever for a full backfill: one async job covering many (locale, chunk)
# requests at ~50% the per-token price. Flow: `AITranslator#prepare_batch` → `submit` → poll `ready?` →
# `results` → `AITranslator#collect_batch`.
module AnthropicBatch
  MAX_TOKENS = 8192 # generous so a batch's JSON object can't truncate (a truncated reply fails the JSON parse)

  module_function

  # `messages.create` params for one request; adds output_config (structured outputs) when a schema is given.
  def message_params(model:, system:, user:, schema: nil)
    params = {
      model: model.to_sym,
      max_tokens: MAX_TOKENS,
      system_: [{ type: 'text', text: system, cache_control: { type: 'ephemeral' } }],
      messages: [{ role: 'user', content: user }]
    }
    params[:output_config] = { format: { type: :json_schema, schema: schema } } unless schema.nil?
    params
  end

  # Concatenate the text blocks of a Message response.
  def text_of(message)
    message.content.select { |block| block.type == :text }.map(&:text).join("\n")
  end

  # Submit jobs ({ custom_id:, system:, user:, schema: }) as one Message Batch; returns the batch id.
  def submit(jobs, client:, model:)
    requests = jobs.map do |job|
      { custom_id: job[:custom_id], params: message_params(model: model, system: job[:system], user: job[:user], schema: job[:schema]) }
    end
    client.messages.batches.create(requests: requests).id
  end

  # True once the batch has finished processing (results are available to stream).
  def ready?(batch_id, client:)
    client.messages.batches.retrieve(batch_id).processing_status.to_s == 'ended'
  end

  # { custom_id => reply text } for the succeeded requests. `results_streaming` yields raw JSONL lines (one per
  # request) — the SDK's lenient coercion passes the line through as a String — so each is parsed here.
  # Errored/expired/canceled entries (and any unparseable line) are skipped, so the strings they covered fall
  # back to human/English at collect time.
  def results(batch_id, client:)
    client.messages.batches.results_streaming(batch_id).each_with_object({}) do |line, out|
      record = parse_line(line)
      result = record['result'] || {}
      out[record['custom_id']] = content_text(result.dig('message', 'content')) if result['type'] == 'succeeded'
    end
  end

  # Parse a JSONL result line into a Hash; {} on anything unparseable. Tolerates a Hash (already parsed).
  def parse_line(line)
    line.is_a?(String) ? JSON.parse(line) : line
  rescue JSON::ParserError
    {}
  end

  # Join the text blocks of a parsed message-content array (Hash blocks, not the typed objects `text_of` takes).
  def content_text(content)
    Array(content).select { |block| block['type'] == 'text' }.map { |block| block['text'] }.join("\n")
  end

  # Poll until the batch finishes, then return its results (same shape as `results`); returns nil if it hasn't
  # finished within `timeout`. `interval`/`timeout` are seconds; `sleeper` is injected so tests run instantly.
  # Yields elapsed seconds after each not-ready check (progress reporting). Timeout is approximate (summed
  # intervals, not wall clock).
  #
  # This is the simple synchronous "submit and wait" mechanism. For a huge backfill that may run for a long
  # time, prefer submitting, persisting the batch id, and collecting in a later step over blocking on this —
  # `submit` returns the id immediately, and `ready?` / `results` let a separate step pick it up.
  def await(batch_id, client:, interval: 30, timeout: 3600, sleeper: ->(seconds) { sleep(seconds) })
    waited = 0
    loop do
      return results(batch_id, client: client) if ready?(batch_id, client: client)
      return nil if waited >= timeout

      yield waited if block_given?
      sleeper.call(interval)
      waited += interval
    end
  end

  # A raw Anthropic client for the batch calls (needs the `anthropic` gem + ANTHROPIC_API_KEY).
  def client(api_key: ENV.fetch('ANTHROPIC_API_KEY', nil))
    require 'anthropic'
    Anthropic::Client.new(api_key: api_key)
  end
end
