# frozen_string_literal: true

# Exercises the publish half of continuous_translations.rb (push, skip, close, open a PR) against a throwaway local
# "origin" repo and a fake GitHub that records every call. Needs `git`, nothing else.
# Run directly: `ruby fastlane/lanes/continuous_translations_test.rb`.
require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'
require 'open3'
require 'json'

DEFAULT_BRANCH = 'trunk'
GITHUB_REPO = 'example/repo'

# rubocop:disable Style/OneClassPerFile, Naming/PredicateMethod, Naming/PredicatePrefix -- stand-ins for fastlane's API

# Stand-ins for the fastlane actions the lane file calls. `platform` skips the lane definitions: only the helper
# methods are under test.
def platform(*); end
def is_ci = true
def get_required_env(_key) = 'token'
def buildkite_annotate(**); end

def sh(*args, log: true) # rubocop:disable Lint/UnusedMethodArgument -- same signature as fastlane's `sh`
  out, err, status = Open3.capture3(*args)
  raise "#{args.join(' ')} failed: #{err}" unless status.success?

  out
end

# Records what the lane logs, so tests can check a failure was reported rather than raised.
module UI
  LOG = [] # rubocop:disable Style/MutableConstant -- appended to by the stubs below
  %i[message success important error].each { |level| define_singleton_method(level) { |text| LOG << [level, text] } }
  def self.user_error!(text) = raise(text)
end

module Fastlane
  module Helper
    # A fake of the release toolkit's GithubHelper. It holds at most one open PR and records every call.
    class GithubHelper
      class << self
        attr_accessor :open_pr, :calls
      end

      FakePullRequest = Struct.new(:number, :html_url, :node_id)

      # The Octokit methods the lane uses.
      class FakeClient
        def create_pull_request(repo, base, head, title, _body)
          GithubHelper.calls << [:create, repo, base, head, title]
          GithubHelper.open_pr = FakePullRequest.new(1, 'https://example/pr/1', 'PR_1')
        end

        def add_labels_to_an_issue(_repo, number, labels) = GithubHelper.calls << [:labels, number, labels]
        def add_comment(_repo, number, _body) = GithubHelper.calls << [:comment, number]

        def close_pull_request(_repo, number)
          GithubHelper.calls << [:close, number]
          GithubHelper.open_pr = nil
        end

        # Real Octokit takes a Hash body's `query:` key as URL parameters, so the lane must send a JSON string.
        def post(path, body)
          raise ArgumentError, "GraphQL body must be a JSON string, got #{body.class}" unless body.is_a?(String)

          GithubHelper.calls << [:graphql, path, JSON.parse(body).dig('variables', 'id')]
          { errors: [{ message: 'Pull request is in clean status' }] } # exercises the error-reading path
        end
      end

      attr_reader :client

      def initialize(*)
        @client = FakeClient.new
      end

      def find_pull_request(repository:, head:, base:)
        GithubHelper.calls << [:find, repository, head, base]
        GithubHelper.open_pr
      end
    end
  end
end

# rubocop:enable Style/OneClassPerFile, Naming/PredicateMethod, Naming/PredicatePrefix

load File.join(__dir__, 'continuous_translations.rb')

# The publish half of both continuous-translation lanes, run against a local origin and a fake GitHub.
class ContinuousTranslationsPublishTest < Minitest::Test # rubocop:disable Metrics/ClassLength, Style/OneClassPerFile
  BRANCH = 'bot/strings-for-translation'
  EN = 'WordPress/Resources/en.lproj/Localizable.strings'
  PR_TEXT = { title: 'Update strings for localization', body: 'body' }.freeze
  STRINGS_AB = %("a" = "A";\n"b" = "B";)
  STRINGS_ABC = %("a" = "A";\n"b" = "B";\n"c" = "C";)

  def setup
    @tmp = Dir.mktmpdir
    @origin = File.join(@tmp, 'origin.git')
    @work = File.join(@tmp, 'work')
    git(@tmp, 'init', '-q', '--bare', '-b', DEFAULT_BRANCH, @origin)
    git(@tmp, 'clone', '-q', @origin, @work)
    git(@work, 'config', 'user.email', 'test@example.com')
    git(@work, 'config', 'user.name', 'Test')
    write_file(EN, '"a" = "A";')
    commit('initial')
    git(@work, 'push', '-q', 'origin', "HEAD:#{DEFAULT_BRANCH}")
    Fastlane::Helper::GithubHelper.open_pr = nil
    Fastlane::Helper::GithubHelper.calls = []
    UI::LOG.clear
  end

  def teardown
    FileUtils.rm_rf(@tmp)
  end

  def test_first_change_pushes_and_opens_a_labelled_pr_with_auto_merge
    run_job(strings: STRINGS_AB)

    refute_nil remote_branch, 'the bot branch should be pushed'
    assert_equal 1, calls(:create).size
    assert_equal [[:labels, 1, ['i18n']]], calls(:labels)
    assert_equal [[:graphql, '/graphql', 'PR_1']], calls(:graphql)
    assert(UI::LOG.any? { |level, text| level == :important && text.include?("Couldn't turn on auto-merge") },
           'an auto-merge error should be logged, not raised')
  end

  def test_unrelated_trunk_commit_with_same_changes_does_not_push_or_reopen
    run_job(strings: STRINGS_AB)
    pushed = remote_branch
    advance_trunk('Other.swift', 'unrelated')

    run_job(strings: STRINGS_AB)

    assert_equal pushed, remote_branch, 'identical changes should not restart the PR'
    assert_empty calls(:create), 'the open PR should be reused'
  end

  def test_new_strings_change_pushes_again
    run_job(strings: STRINGS_AB)
    first = remote_branch

    run_job(strings: STRINGS_ABC)

    refute_equal first, remote_branch
    assert_empty calls(:create)
  end

  def test_build_of_an_older_commit_skips_when_trunk_moved_on
    old_base = git(@work, 'rev-parse', "origin/#{DEFAULT_BRANCH}")
    advance_trunk('Other.swift', 'newer')

    run_job(strings: STRINGS_AB, base: old_base)

    assert_nil remote_branch, 'an older build must not push'
    assert_empty Fastlane::Helper::GithubHelper.calls
  end

  def test_nothing_to_change_closes_the_out_of_date_pr
    run_job(strings: STRINGS_AB)
    advance_trunk(EN, "#{STRINGS_AB}\n") # the same strings reach trunk another way, e.g. a release merge-back

    run_job(strings: nil)

    assert_equal [[:close, 1]], calls(:close)
    assert_equal 1, calls(:comment).size
  end

  def test_nothing_to_change_without_an_open_pr_does_nothing
    run_job(strings: nil)

    assert_empty calls(:close)
    assert_empty calls(:create)
  end

  def test_remote_branch_with_a_file_this_run_does_not_touch_is_overwritten
    run_job(strings: STRINGS_AB)
    git(@work, 'checkout', '-q', BRANCH)
    write_file('Extra.strings', 'x')
    commit('extra')
    git(@work, 'push', '-q', '--force', 'origin', "HEAD:refs/heads/#{BRANCH}")
    with_extra = remote_branch

    run_job(strings: STRINGS_AB)

    refute_equal with_extra, remote_branch, 'the branch should be pushed to drop the extra file'
  end

  def test_dry_run_touches_nothing
    base = git(@work, 'rev-parse', "origin/#{DEFAULT_BRANCH}")
    git(@work, 'checkout', '-q', '-B', BRANCH)
    write_file(EN, STRINGS_AB)
    commit('Update strings for localization')

    Dir.chdir(@work) do
      publish_continuous_translation_pr(publish: false, base_sha: base, branch: BRANCH,
                                        superseded_by_newer_builds: true, pr_text: PR_TEXT)
    end

    assert_nil remote_branch
    assert_empty Fastlane::Helper::GithubHelper.calls
  end

  private

  # One CI run: start at trunk's tip (or `base`), make the bot commit if `strings` is given, then publish.
  def run_job(strings:, base: nil)
    git(@work, 'fetch', '-q', 'origin', DEFAULT_BRANCH)
    git(@work, 'checkout', '-q', '--detach', base || "origin/#{DEFAULT_BRANCH}")
    base_sha = git(@work, 'rev-parse', 'HEAD')
    git(@work, 'checkout', '-q', '-B', BRANCH)
    if strings
      write_file(EN, strings)
      commit('Update strings for localization')
    end
    Fastlane::Helper::GithubHelper.calls = []
    Dir.chdir(@work) do
      publish_continuous_translation_pr(publish: true, base_sha: base_sha, branch: BRANCH,
                                        superseded_by_newer_builds: true, pr_text: PR_TEXT)
    end
  end

  def advance_trunk(path, content)
    git(@work, 'fetch', '-q', 'origin', DEFAULT_BRANCH)
    git(@work, 'checkout', '-q', '--detach', "origin/#{DEFAULT_BRANCH}")
    write_file(path, content)
    commit("trunk: #{path}")
    git(@work, 'push', '-q', 'origin', "HEAD:#{DEFAULT_BRANCH}")
  end

  def git(dir, *args)
    out, err, status = Open3.capture3('git', '-C', dir, *args)
    raise "git #{args.join(' ')}: #{err}" unless status.success?

    out.strip
  end

  def write_file(path, content)
    full_path = File.join(@work, path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, "#{content}\n")
  end

  def commit(message)
    git(@work, 'add', '-A')
    git(@work, 'commit', '-q', '-m', message)
  end

  def remote_branch
    out, _err, status = Open3.capture3('git', '-C', @origin, 'rev-parse', '--verify', '--quiet', "refs/heads/#{BRANCH}")
    status.success? ? out.strip : nil
  end

  def calls(kind)
    Fastlane::Helper::GithubHelper.calls.select { |call| call.first == kind }
  end
end
