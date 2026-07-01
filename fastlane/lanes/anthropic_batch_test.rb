# frozen_string_literal: true

# Pure-Ruby unit suite for AnthropicBatch. Run: `ruby fastlane/lanes/anthropic_batch_test.rb`.
# Drives the submit / poll / results glue against a fake client that mimics the SDK's shape (no gem, no network).
require 'minitest/autorun'
require 'json'
require_relative 'anthropic_batch'

# Exercises the submit / poll / results glue via a fake client that mimics the SDK shape. `create`/`retrieve`
# return typed-ish objects (a Batch struct); `results_streaming` yields raw JSONL strings, as the real SDK does.
class AnthropicBatchTest < Minitest::Test
  Batch = Struct.new(:id, :processing_status)

  # Mimics client.messages.batches.{create,retrieve,results_streaming}.
  class FakeBatches
    attr_reader :created_requests

    def initialize(status:, entries:, ready_after: nil)
      @status = status
      @entries = entries
      @ready_after = ready_after # report :ended only once `retrieve` has been called this many times
      @retrieve_calls = 0
    end

    def create(requests:)
      @created_requests = requests
      Batch.new('batch_1', :in_progress)
    end

    def retrieve(_id)
      @retrieve_calls += 1
      Batch.new('batch_1', effective_status)
    end

    def results_streaming(_id)
      @entries
    end

    private

    def effective_status
      return @status if @ready_after.nil?

      @retrieve_calls >= @ready_after ? :ended : :in_progress
    end
  end

  def fake_client(status: :ended, entries: [], ready_after: nil)
    batches = FakeBatches.new(status: status, entries: entries, ready_after: ready_after)
    Struct.new(:messages).new(Struct.new(:batches).new(batches))
  end

  # Build a raw JSONL result line, the way results_streaming yields them.
  def succeeded_line(custom_id, json)
    JSON.generate('custom_id' => custom_id,
                  'result' => { 'type' => 'succeeded', 'message' => { 'content' => [{ 'type' => 'text', 'text' => json }] } })
  end

  def errored_line(custom_id)
    JSON.generate('custom_id' => custom_id, 'result' => { 'type' => 'errored' })
  end

  def test_message_params_adds_output_config_only_with_a_schema
    bare = AnthropicBatch.message_params(model: 'claude-opus-4-8', system: 's', user: 'u')
    refute bare.key?(:output_config)
    assert_equal :'claude-opus-4-8', bare[:model]

    with_schema = AnthropicBatch.message_params(model: 'claude-opus-4-8', system: 's', user: 'u', schema: { 'type' => 'object' })
    assert_equal({ format: { type: :json_schema, schema: { 'type' => 'object' } } }, with_schema[:output_config])
  end

  def test_submit_builds_requests_and_returns_the_id
    client = fake_client
    jobs = [{ custom_id: 'fr_0', system: 'sys', user: 'usr', schema: { 'type' => 'object' } }]
    id = AnthropicBatch.submit(jobs, client: client, model: 'claude-opus-4-8')

    assert_equal 'batch_1', id
    request = client.messages.batches.created_requests.first
    assert_equal 'fr_0', request[:custom_id]
    assert_equal :'claude-opus-4-8', request[:params][:model]
  end

  def test_ready_reflects_processing_status
    refute AnthropicBatch.ready?('b', client: fake_client(status: :in_progress))
    assert AnthropicBatch.ready?('b', client: fake_client(status: :ended))
  end

  def test_results_returns_text_for_succeeded_requests_only
    entries = [succeeded_line('fr_0', '{"1":"Bonjour"}'), errored_line('fr_1')]
    out = AnthropicBatch.results('b', client: fake_client(entries: entries))
    assert_equal({ 'fr_0' => '{"1":"Bonjour"}' }, out)
  end

  def test_await_polls_until_ready_then_returns_results
    client = fake_client(ready_after: 3, entries: [succeeded_line('fr_0', '{"1":"Bonjour"}')])
    out = AnthropicBatch.await('b', client: client, interval: 1, sleeper: ->(_seconds) {})
    assert_equal({ 'fr_0' => '{"1":"Bonjour"}' }, out)
  end

  def test_await_returns_nil_on_timeout
    client = fake_client(status: :in_progress)
    assert_nil AnthropicBatch.await('b', client: client, interval: 30, timeout: 60, sleeper: ->(_seconds) {})
  end
end
