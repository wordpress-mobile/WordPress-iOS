# frozen_string_literal: true

# Unit tests for ScreenshotContentHelper, which translates the UI test fixtures' content for the App
# Store screenshots. Run directly: `ruby fastlane/lanes/screenshot_content_helper_test.rb`.
require 'minitest/autorun'
require 'tmpdir'
require_relative 'screenshot_content_helper'

# Covers which text is translated and where, notification ranges, and string bodies.
class ScreenshotContentHelperTest < Minitest::Test # rubocop:disable Metrics/ClassLength -- one scenario per rule
  # Writes `mappings` (path => mapping hash) as fixtures, runs the helper, and returns the overlay's
  # mappings (path => mapping hash).
  def overlay(mappings, english, translated)
    Dir.mktmpdir do |directory|
      fixtures = File.join(directory, 'fixtures')
      mappings.each do |path, mapping|
        file = File.join(fixtures, 'mappings', path)
        FileUtils.mkdir_p(File.dirname(file))
        File.write(file, JSON.generate(mapping))
      end
      output = File.join(directory, 'overlay')
      written = ScreenshotContentHelper.write_overlay(fixtures: fixtures, english: english, translated: translated, output: output)
      written.to_h { |path| [path, JSON.parse(File.read(File.join(output, 'mappings', path)))] }
    end
  end

  def utf16_slice(text, range)
    text.encode('UTF-16LE').unpack('v*')[range].pack('v*').force_encoding('UTF-16LE').encode('UTF-8')
  end

  def mapping(body)
    { 'request' => { 'urlPath' => '/x' }, 'response' => { 'status' => 200, 'jsonBody' => body } }
  end

  def test_translates_a_phrase_inside_html
    result = overlay(
      { 'posts.json' => mapping({ 'content' => '<p>Blue skies and warm weather.</p>' }) },
      { 'p' => 'Blue skies and warm weather.' },
      { 'p' => '青空と暖かい天気。' }
    )

    assert_equal '<p>青空と暖かい天気。</p>', result['posts.json'].dig('response', 'jsonBody', 'content')
  end

  def test_translates_a_short_entry_only_as_a_whole_value
    result = overlay(
      { 'stats.json' => mapping({ 'title' => 'Home', 'label' => 'Home page views' }) },
      { 'home' => 'Home' },
      { 'home' => 'ホーム' }
    )

    body = result['stats.json'].dig('response', 'jsonBody')
    assert_equal 'ホーム', body['title']
    assert_equal 'Home page views', body['label']
  end

  def test_leaves_out_files_with_nothing_to_translate
    result = overlay(
      { 'a.json' => mapping({ 'title' => 'Home' }), 'b.json' => mapping({ 'title' => 'Other' }) },
      { 'home' => 'Home' },
      { 'home' => 'ホーム' }
    )

    assert_equal ['a.json'], result.keys
  end

  def test_keeps_english_for_an_untranslated_key
    result = overlay(
      { 'a.json' => mapping({ 'one' => 'Home', 'two' => 'Our Story' }) },
      { 'home' => 'Home', 'story' => 'Our Story' },
      { 'home' => 'ホーム' }
    )

    assert_equal({ 'one' => 'ホーム', 'two' => 'Our Story' }, result['a.json'].dig('response', 'jsonBody'))
  end

  def test_translates_a_sentence_before_a_title_in_it
    english = { 'title' => 'My Top 10 Pastry Recipes', 'sentence' => 'Reyansh Pawar commented on My Top 10 Pastry Recipes' }
    translated = { 'title' => 'ペストリーレシピ10選', 'sentence' => 'Reyansh Pawarさんが「ペストリーレシピ10選」にコメントしました' }
    result = overlay({ 'n.json' => mapping({ 'a' => english['sentence'], 'b' => english['title'] }) }, english, translated)

    assert_equal({ 'a' => translated['sentence'], 'b' => translated['title'] }, result['n.json'].dig('response', 'jsonBody'))
  end

  def test_moves_notification_ranges_to_the_translated_parts
    note = {
      'text' => 'Reyansh Pawar commented on My Top 10 Pastry Recipes',
      'ranges' => [
        { 'type' => 'user', 'indices' => [0, 13] },
        { 'type' => 'post', 'indices' => [27, 51] }
      ]
    }
    result = overlay(
      { 'n.json' => mapping({ 'subject' => [note] }) },
      { 'title' => 'My Top 10 Pastry Recipes', 'sentence' => note['text'] },
      { 'title' => 'ペストリーレシピ10選', 'sentence' => 'Reyansh Pawarさんが「ペストリーレシピ10選」にコメントしました' }
    )

    block = result['n.json'].dig('response', 'jsonBody', 'subject', 0)
    indices = block['ranges'].map { |range| range['indices'] }
    assert_equal [[0, 13], [17, 28]], indices
    assert_equal 'ペストリーレシピ10選', utf16_slice(block['text'], 17...28)
  end

  def test_counts_ranges_in_utf16_units
    note = { 'text' => 'Liked by Amy', 'ranges' => [{ 'type' => 'user', 'indices' => [9, 12] }] }
    result = overlay(
      { 'n.json' => mapping({ 'subject' => [note] }) },
      { 'sentence' => 'Liked by Amy' },
      { 'sentence' => '😀 Amy liked it' }
    )

    # The emoji is two UTF-16 units, so "Amy" starts at 3.
    assert_equal [3, 6], result['n.json'].dig('response', 'jsonBody', 'subject', 0, 'ranges', 0, 'indices')
  end

  def test_rejects_a_translation_that_drops_a_marked_part
    note = { 'text' => 'Reyansh Pawar commented on your post', 'ranges' => [{ 'type' => 'user', 'indices' => [0, 13] }] }

    error = assert_raises(ScreenshotContentHelper::MissingRangeError) do
      overlay(
        { 'n.json' => mapping({ 'subject' => [note] }) },
        { 'sentence' => note['text'] },
        { 'sentence' => 'Someone commented on your post, in another language' }
      )
    end
    assert_includes error.message, 'Reyansh Pawar'
  end

  def test_translates_a_body_written_as_a_json_string
    mapping = { 'request' => { 'urlPath' => '/x' }, 'response' => { 'status' => 200, 'body' => JSON.generate({ 'title' => 'Our "Story"' }) } }
    result = overlay({ 'a.json' => mapping }, { 'story' => 'Our "Story"' }, { 'story' => '私たちの「物語」' })

    assert_equal({ 'title' => '私たちの「物語」' }, JSON.parse(result['a.json'].dig('response', 'body')))
  end

  def test_reports_missing_and_unknown_keys
    assert_equal(
      { missing: ['b'], unknown: ['c'] },
      ScreenshotContentHelper.mismatched_keys(english: { 'a' => 'A', 'b' => 'B' }, translated: { 'a' => 'あ', 'c' => 'し' })
    )
  end
end
