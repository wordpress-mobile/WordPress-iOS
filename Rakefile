# frozen_string_literal: true

PROJECT_DIR = __dir__
abort('Project directory contains one or more spaces – unable to continue.') if PROJECT_DIR.include?(' ')

desc 'Checks the source for style errors. Lints the whole project, or only the given paths: rake lint[path1,path2]'
task :lint, [:paths] do |_task, args|
  run_swiftlint(paths: [args[:paths], *args.extras].compact)
end

desc 'Automatically fix linting errors where possible. Fixes the whole project, or only the given paths: rake lintfix[path1,path2]'
task :lintfix, [:paths] do |_task, args|
  run_swiftlint(paths: [args[:paths], *args.extras].compact, extra_args: ['--fix'])
end

# See Scripts/swiftlint.sh, which the SwiftLint build phase also calls.
def run_swiftlint(paths: [], extra_args: [])
  sh(File.join(PROJECT_DIR, 'Scripts', 'swiftlint.sh'), *extra_args, *paths.map { |path| File.expand_path(path) })
end
