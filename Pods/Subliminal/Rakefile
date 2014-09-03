#  For details and documentation:
#  http://github.com/inkling/Subliminal
#
#  Copyright 2013-2014 Inkling Systems, Inc.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.


# Subliminal's Rakefile.
# Defines tasks to install, uninstall, and test Subliminal.
# Invoke "rake" with no arguments to print usage.


PROJECT_DIR = File.dirname(__FILE__)
SCRIPT_DIR = "#{PROJECT_DIR}/Supporting Files/CI"

FILE_TEMPLATE_DIR = "#{ENV['HOME']}/Library/Developer/Xcode/Templates/File Templates/Subliminal"
TRACE_TEMPLATE_DIR = "#{ENV['HOME']}/Library/Application Support/Instruments/Templates/Subliminal"
TRACE_TEMPLATE_NAME = "Subliminal.tracetemplate"
SCHEMES_DIR = "Subliminal.xcodeproj/xcuserdata/#{ENV['USER']}.xcuserdatad/xcschemes"

DOCSET_DIR = "#{ENV['HOME']}/Library/Developer/Shared/Documentation/DocSets"
DOCSET_NAME = "com.inkling.Subliminal.docset"
DOCSET_VERSION = "1.1.0"

SUPPORTED_SDKS = [ "6.1", "7.1" ]
TEST_SDK = ENV["TEST_SDK"]
if TEST_SDK
  raise "Test SDK #{TEST_SDK} is not supported." unless SUPPORTED_SDKS.include?(TEST_SDK)
  TEST_SDKS = [ TEST_SDK ]
else
  TEST_SDKS = SUPPORTED_SDKS
end


task :default => :usage


### Usage

desc "Prints usage statement for people unfamiliar with Rake or this particular Rakefile"
task :usage, [:task_name] do |t, args|
  task_name = args[:task_name] || ""

  if !task_name.empty?
    case task_name

    when "usage"
      puts """
rake usage\tPrints usage statement for people unfamiliar with Rake or this particular Rakefile

rake usage[[<task>]]

Arguments:
  task\tThe name of the task to describe.\n\n"""

    when "uninstall"
      puts "rake uninstall\tUninstalls supporting files"

    when "install"
      puts """
rake install\tInstalls supporting files

rake install [DOCS=no] [DEV=yes]

Options:
  DOCS=no\tSkips the download and installation of Subliminal's documentation.
  DEV=yes\tInstalls files supporting the development of Subliminal.\n\n"""

    when "test", "test:unit", "test:integration", "test:integration:iphone", "test:integration:ipad"
      puts """
rake test\tRuns Subliminal's tests

rake test
rake test:unit
rake test:CI_unit
rake test:integration
rake test:integration[:iphone, :ipad]
rake test:integration:device           UDID=<udid>

Sub-tasks:
  :unit\t\tRuns the unit tests
  :CI_unit\tRuns the unit tests of Subliminal's CI infrastructure
  :integration\tRuns the integration tests
    :iphone\tFor the iPhone Simulator
    :ipad\tFor the iPad Simulator
    :device\tFor a device

\`test\` invokes \`test:unit\`, \`test:CI_unit\`, and \`test:integration\`.
\`test:integration\` invokes \`test:integration:iphone\` and \`test:integration:ipad\`.
\`test:integration:device\` must be explicitly invoked.

To run the integration tests un-attended, you must have \"pre-authorized\" \`instruments\`
as described here: https://github.com/inkling/Subliminal/wiki/Continuous-Integration#faq.

To run the integration tests on a device, you will need a valid developer identity 
and provisioning profile. If you have a wildcard profile you will be able to run 
the tests without creating a profile specifically for the \"Subliminal Integration Tests\" app.

Subliminal's integration tests are currently configured to use the automatically-selected 
iPhone Developer identity with the wildcard \"iOS Team Provisioning Profile\" managed 
by Xcode.

\`test\` options:
  TEST_SDK=<sdk>            Selects the iPhone Simulator SDK version against which to run the tests.
                            Supported values are '6.1' and '7.1'.
                            If not specified, the tests will be run against all supported SDKs.
 
\`test:integration:device\` options:
  UDID=<udid>               The UDID of the device to target.\n\n"""

    when "build_docs"
      puts """
rake build_docs\tBuilds Subliminal's documentation

rake build_docs [RELEASE=yes]

This command will also install the built documentation into Xcode
unless \`RELEASE=yes\` is specified.

Options:
  RELEASE=yes\tPrepares HTML and archived docsets for upload to the \`gh_pages\` branch.\n\n"""

    else
      fail "Unrecognized task name."

    end
  else
    puts """
rake <task>[[arg[, arg2...]]] [<opt>=<value>[ <opt2>=<value2>...]]

Tasks:
  uninstall\tUninstalls supporting files
  install\tInstalls supporting files
  test\t\tRuns Subliminal's tests
  build_docs\tBuilds Subliminal's documentation

See 'rake usage[<task>]' for more information on a specific task.\n\n"""
  end
end

# Restarts Xcode (with the user's permission) if it's running, as required by several of the tasks below
# If a block is passed, it will be executed between quitting Xcode and restarting it
# Returns false if Xcode needed to be restarted and the user chose not to, true otherwise
def restart_xcode?(reason, cancel_button_title)
  frontmost_app = `osascript <<-EOT
    tell application "System Events"
      set app_name to name of first process whose frontmost is true
    end tell
EOT`.chomp

  reply=`osascript <<-EOT
    if application "Xcode" is not running then
      set reply to "Not Running"
    else
      tell application "System Events"
        activate
        set reply to button returned of (display dialog "#{reason}" \
                        buttons {"#{cancel_button_title}", "Restart Xcode"} \
                        default button "#{cancel_button_title}")
      end tell
    end if
EOT`.chomp
    
  return false if reply == "#{cancel_button_title}"

  # The block may require that Xcode has fully quit--wait before proceeding
  `osascript -e 'tell application "Xcode" to quit' -e 'delay 1.0'` if reply == "Restart Xcode"

  yield if block_given?

  if reply == "Restart Xcode"
    # once to restart, twice to come forward
    `osascript -e 'tell application "Xcode" to activate'`
    `osascript -e 'tell application "Xcode" to activate'`
    # but leave previously frontmost app up
    `osascript -e 'tell application "#{frontmost_app}" to activate'`
  end

  true
end


### Uninstallation

desc "Uninstalls supporting files"
task :uninstall do
  puts "\nUninstalling old supporting files..."

  uninstall_file_templates
  uninstall_trace_templates
  # This setting may cascade from the tests;
  # respecting it allows us to avoid restarting Xcode when running tests locally.
  if ENV["DOCS"] != "no"
    fail "Could not uninstall docs" if !uninstall_docs?
  end
  # Note that we don't need to uninstall the schemes here, 
  # as they're contained within the project

  puts "Uninstallation complete.\n\n"
end

def uninstall_file_templates
  puts "- Uninstalling file templates..."

  `rm -rf "#{FILE_TEMPLATE_DIR}"`
end

def uninstall_trace_templates
  puts "- Uninstalling trace templates..."

  `rm -rf "#{TRACE_TEMPLATE_DIR}"`
end

def uninstall_docs?
  puts "- Uninstalling docs..."

  docset_file = "#{DOCSET_DIR}/#{DOCSET_NAME}"
  
  if File.exists?(docset_file)
    # Xcode will crash if a docset is deleted while the app's open
    restart_reason = "Subliminal will need to restart Xcode to uninstall Subliminal's documentation."
    return false if !restart_xcode?(restart_reason, "Uninstall Later") { `rm -rf #{docset_file}` }
  end

  true
end

def uninstall_schemes
  puts "- Uninstalling Subliminal's schemes..."

  # Though Xcode continues to show the schemes until restarted (it appears to cache working copies), 
  # it won't wig out if the schemes are deleted while open, so we don't need to restart it here
  `rm -f "#{SCHEMES_DIR}/"*.xcscheme`
end


### Installation

desc "Installs supporting files"
task :install => :uninstall do
  puts "\nInstalling supporting files..."

  install_file_templates(ENV["DEV"] == "yes")
  install_trace_templates
  unless ENV["DOCS"] == "no"
    fail "Could not install Subliminal's documentation. You can retry, or invoke \`install\` with \`DOCS=no\`." if !install_docs?
  end
  if ENV["DEV"] == "yes"
    fail "Could not install Subliminal's schemes." if !install_schemes?
  end

  puts "Installation complete.\n\n"
end

def install_file_templates(install_dev_templates)
  puts "- Installing file templates..."

  local_template_dir = "#{PROJECT_DIR}/Supporting Files/Xcode/File Templates/"

  `mkdir -p "#{FILE_TEMPLATE_DIR}" && \
  cp -r "#{local_template_dir}/Integration test class.xctemplate" "#{FILE_TEMPLATE_DIR}"`

  # install developer templates
  if $? == 0 && install_dev_templates
    `cp -r "#{local_template_dir}/Subliminal integration test class.xctemplate" "#{FILE_TEMPLATE_DIR}"`
  end
end

def install_trace_templates
  puts "- Installing trace templates..."

  `mkdir -p "#{TRACE_TEMPLATE_DIR}" && \
  cp -R "#{PROJECT_DIR}/Supporting Files/Instruments/"* "#{TRACE_TEMPLATE_DIR}"`

  # Update the template to reference its script and icon correctly
  # (as the user's home directory isn't known until now)
  `cd "#{TRACE_TEMPLATE_DIR}" &&\
  plutil -convert xml1 #{TRACE_TEMPLATE_NAME} &&\
  perl -pi -e "s|~|#{ENV['HOME']}|" #{TRACE_TEMPLATE_NAME} &&\
  plutil -convert binary1 #{TRACE_TEMPLATE_NAME}`
end

def install_docs?
  puts "- Installing docs..."

  # download the latest docs
  docset_xar_name = "com.inkling.Subliminal-#{DOCSET_VERSION}.xar"

  docset_download_dir = `mktemp -d /tmp/subliminal-install.docset.XXXXXX`.chomp
  if $? != 0
    puts "Could not create temporary directory to download docs."
    return false
  end
  docset_xar_file = "#{docset_download_dir}/#{docset_xar_name}"

  docset_xar_URL_root = "http://inkling.github.io/Subliminal/Documentation"
  `curl --progress-bar --output "#{docset_xar_file}" "#{docset_xar_URL_root}/#{docset_xar_name}"`
  if $? != 0
    puts "Could not download docset."
    return false
  end

  # uncompress them
  `xar -C "#{docset_download_dir}" -xf "#{docset_xar_file}"`

  # move them to the documentation directory
  downloaded_docset_file = "#{docset_download_dir}/#{DOCSET_NAME}"
  installed_docset_file = "#{DOCSET_DIR}/#{DOCSET_NAME}"
  `mv "#{downloaded_docset_file}" "#{installed_docset_file}"`

  # load them
  `osascript -e 'tell application "Xcode" to load documentation set with path "#{installed_docset_file}"'`

  # clean up temporary directory
  `rm -rf "#{docset_download_dir}"`

  return true
end

# If Subliminal's schemes were shared, they'd show up in projects that used Subliminal
# so we instead add them (as non-shared schemes, within the project's `.xcuserdata` 
# directory) only when Subliminal itself is to be built, by the tests or a developer
def install_schemes?
  puts "- Installing Subliminal's schemes..."

  # Xcode will not show the schemes until restarted,
  # but we don't want to have to restart Xcode every time we run the tests locally,
  # so we only (re)install if any schemes are missing or out-of-date.
  schemes_need_reinstall = Dir["#{PROJECT_DIR}/Supporting Files/Xcode/Schemes/*"].any? { |file|
    installed_file = "#{SCHEMES_DIR}/#{File.basename(file)}"
    Dir[installed_file].empty? || !FileUtils.compare_file(installed_file, file)
  }
  if schemes_need_reinstall
    restart_reason = "Subliminal will need to restart Xcode to install Subliminal's schemes."
    return restart_xcode?(restart_reason, "Install Later") {
      `mkdir -p "#{SCHEMES_DIR}" && \
      cp "#{PROJECT_DIR}/Supporting Files/Xcode/Schemes/"* "#{SCHEMES_DIR}"`
    }
  end
  return true
end

### Testing

desc "Runs Subliminal's tests"
task :test => 'test:prepare' do
  puts "\nRunning tests...\n\n"

  # The unit tests guarantee the integrity of the integration tests
  # So no point in running the latter if the unit tests break the build
  Rake::Task['test:unit'].invoke
  Rake::Task['test:CI_unit'].invoke
  Rake::Task['test:integration'].invoke

  puts "Tests passed.\n\n"
end

namespace :test do
  desc "Prepares to run Subliminal's tests"
  task :prepare do
    # We need to install Subliminal's trace template and its schemes
    # but can't declare install as a dependency because we have to set its env vars
    ENV['DEV'] = "yes"; ENV['DOCS'] = "no"
    Rake::Task['install'].invoke

    # Ensure that we use the default Xcode toolchain unless the developer
    # has specified otherwise (`DEVELOPER_DIR` should always be specified one way
    # or the other to be sure of the version we use--when preview versions are
    # installed, they may change the response of `xcode-select`).
    #
    # Note that we can't properly `export` an environment variable from a Ruby script,
    # But adding it to ENV works because `subliminal-test` is run in a subshell
    ENV['DEVELOPER_DIR'] ||= "/Applications/Xcode.app/Contents/Developer"
  end

  desc "Runs the unit tests"
  task :unit => :prepare do    
    puts "- Running unit tests...\n\n"

    base_command = 'xctool -project Subliminal.xcodeproj/ -scheme "Subliminal Unit Tests" -sdk iphonesimulator'

    # Use system so we see the tests' output
    fail "Unit tests failed to build." unless system("#{base_command} clean build-tests")

    tests_succeeded = true
    test_on_sdk = lambda { |sdk|
      puts "-- Running unit tests on iOS #{sdk}..."
      if system("#{base_command} run-tests -test-sdk iphonesimulator#{sdk}")
        puts "Unit tests succeeded on iOS #{sdk}.\n\n"
      else
        puts "Unit tests failed on iOS #{sdk}.\n\n"
        tests_succeeded = false
      end
    }
    TEST_SDKS.each { |sdk| test_on_sdk.call(sdk) }

    if tests_succeeded
      puts "\nUnit tests passed.\n\n"
    else
      fail "\nUnit tests failed.\n\n"
    end
  end

  desc "Runs the CI unit tests"
  task :CI_unit do
    puts "- Running CI unit tests...\n\n"

    test_command = "xctool -project subliminal-instrument.xcodeproj -scheme 'subliminal-instrument Tests' test"

    # Use system so we see the tests' output
    if system("cd 'Supporting Files/CI/subliminal-instrument/' && #{test_command}")
      puts "CI unit tests passed.\n\n"
    else
      fail "CI unit tests failed.\n\n"
    end
  end

  desc "Runs the integration tests"
  task :integration => :prepare do    
    puts "- Running integration tests...\n\n"

    # When the tests are running separately, 
    # we want them to (individually) fail rake
    # But here we want to run them both
    tests_succeeded = true
    begin
      Rake::Task['test:integration:iphone'].invoke
    rescue Exception => e
      puts e
      tests_succeeded = false
    end

    begin
      Rake::Task['test:integration:ipad'].invoke      
    rescue Exception => e
      puts e
      tests_succeeded = false
    end

    # test:integration:device must be explicitly invoked
    # by a developer with a valid identity/provisioning profile
    # and device attached

    if tests_succeeded
      puts "\nIntegration tests passed.\n\n"
    else
      fail "\nIntegration tests failed.\n\n"
    end
  end

  namespace :integration do
    def base_test_command
      "\"#{SCRIPT_DIR}/subliminal-test\"\
        -project Subliminal.xcodeproj\
        -scheme 'Subliminal Integration Tests'\
        --quiet_build"
    end

    # ! because this clears old results
    def fresh_results_dir!(device, sdk = nil)
      results_dir = "#{SCRIPT_DIR}/results/#{device}"
      results_dir << "/#{sdk}" if sdk
      `rm -rf "#{results_dir}" && mkdir -p "#{results_dir}"`
      results_dir
    end

    desc "Runs the integration tests on iPhone"
    task :iphone => :prepare do
      puts "-- Running iPhone integration tests..."

      tests_succeeded = true
      test_on_sdk = lambda { |sdk|
        puts "\n--- Running iPhone integration tests on iOS #{sdk}..."

        # Use system so we see the tests' output
        results_dir = fresh_results_dir!("iphone", sdk)
        # Use the 3.5" iPhone Retina because that can support both our target SDKs
        if system("#{base_test_command} -output \"#{results_dir}\" -sim_device 'iPhone Retina (3.5-inch)' -sim_version #{sdk}")
          puts "iPhone integration tests succeeded on iOS #{sdk}.\n\n"
        else
          puts "iPhone integration tests failed on iOS #{sdk}.\n\n"
          tests_succeeded = false
        end
      }
      TEST_SDKS.each { |sdk| test_on_sdk.call(sdk) }

      if tests_succeeded
        puts "\niPhone integration tests passed.\n\n"
      else
        fail "\niPhone integration tests failed.\n\n"
      end
    end

    desc "Runs the integration tests on iPad"
    task :ipad => :prepare do
      puts "-- Running iPad integration tests..."

      tests_succeeded = true
      test_on_sdk = lambda { |sdk|
        puts "\n--- Running iPad integration tests on iOS #{sdk}..."

        # Use system so we see the tests' output
        results_dir = fresh_results_dir!("ipad", sdk)
        if system("#{base_test_command} -output \"#{results_dir}\" -sim_device 'iPad' -sim_version #{sdk}")
          puts "iPad integration tests succeeded on iOS #{sdk}.\n\n"
        else
          puts "iPad integration tests failed on iOS #{sdk}.\n\n"
          tests_succeeded = false
        end
      }
      TEST_SDKS.each { |sdk| test_on_sdk.call(sdk) }

      if tests_succeeded
        puts "\niPad integration tests passed.\n\n"
      else
        fail "\niPad integration tests failed.\n\n"
      end
    end

    desc "Runs the integration tests on a device"
    task :device => :prepare do
      puts "-- Running the integration tests on a device"

      udid = ENV["UDID"]
      if !udid || udid.length == 0
        fail "Device UDID not specified. See 'rake usage[test]'.\n\n" 
      end

      # Use system so we see the tests' output
      results_dir = fresh_results_dir!("device")
      if system("#{base_test_command} -output \"#{results_dir}\" -hw_id #{udid}")
        puts "\nDevice integration tests passed.\n\n"
      else
        fail "\nDevice integration tests failed.\n\n"
      end
    end
  end
end


### Building documentation

desc "Builds the documentation"
task :build_docs => 'test:prepare' do
  if ENV["RELEASE"] == "yes"
    puts "Do you want to build the #{DOCSET_VERSION} documentation for release?"
    puts "(You might want to update \`DOCSET_VERSION\` at the top of the Rakefile.)"
    puts "Y to continue, anything else to abort."

    input = STDIN.gets.chomp
    fail "Documentation release build aborted." unless input.upcase == "Y"
  end

  puts "\nBuilding documentation...\n\n"

  # Use system so we see the build's output
  if system('xctool -project Subliminal.xcodeproj/ -scheme "Subliminal Documentation" build')
    # If `RELEASE` was set, the build script will have left artifacts for us to post-process below
    if ENV["RELEASE"] == "yes"
      puts "#{DOCSET_VERSION} documentation built successfully."

      # Inject our README, processed by GitHub into the class hierarchy, and fix it up.
      # Injection is done by Appledoc in Debug but we can do a better (albeit more heavyweight) job here.
      index_html_path = "#{PROJECT_DIR}/Documentation/html/index.html"
      fail "Could not fix index html." unless fix_index_html_at_path!(index_html_path)
      `cp "#{index_html_path}" "#{PROJECT_DIR}"/Documentation/docset/Contents/Resources/Documents/index.html`

      # Rename the docset to the post-unarchiving target (see `install_docs`) before archiving
      `mv "#{PROJECT_DIR}"/Documentation/docset "#{PROJECT_DIR}"/Documentation/#{DOCSET_NAME}`
      # Archive
      `xcrun docsetutil package "#{PROJECT_DIR}"/Documentation/#{DOCSET_NAME}`
      # Rename for upload
      docset_xar_name = DOCSET_NAME.chomp(File.extname(DOCSET_NAME)) + ".xar"
      upload_xar_name = "com.inkling.Subliminal-#{DOCSET_VERSION}.xar"
      `mv "#{PROJECT_DIR}"/Documentation/#{docset_xar_name} "#{PROJECT_DIR}"/Documentation/#{upload_xar_name}`

      puts "Upload \`#{PROJECT_DIR}/Documentation/#{upload_xar_name}\`"
      puts "and the contents of \`#{PROJECT_DIR}/Documentation/html\`"
      puts "to the \"Documentation\" folder on the \`gh_pages\` branch.\n\n"
    else
      puts "Documentation built successfully.\n\n"
    end
  else
    fail "Documentation failed to build."
  end
end

# ! because this overwrites `index.html`
def fix_index_html_at_path!(html_path)
  # By requiring Nokogiri here, only developers wishing to build the docs for release need install it.
  require "nokogiri"

  html_file = File.open(html_path, "r")
  html_doc = Nokogiri::HTML(html_file)
  html_file.close

  # 1. Appledoc can't handle fenced code blocks and some links,
  #    so get GitHub to format our README and then inject it into the index html.
  
  # "data-binary" is essential to preserve line breaks
  gfm_README = `curl -sSX POST --data-binary @"#{PROJECT_DIR}"/README.md https://api.github.com/markdown/raw --header "Content-Type:text/x-markdown"`
  gfm_README_fragment = Nokogiri::HTML::DocumentFragment.parse(gfm_README)

  section_node = Nokogiri::XML::Node.new("div", html_doc)
  section_node["class"] = "section section-overview index-overview"
  section_node.add_child(gfm_README_fragment)

  # The section node must be the container's first child to force the class hierarchy
  # to occupy only one column at left
  container_node = html_doc.at_css("div#container")
  container_node.children.before(section_node)

  # 2. Polish the README display.
  style_node = Nokogiri::XML::Node.new("style", html_doc)
  style_node.content = <<-EOSTYLE
/* Float the class hierarchy to the left of the README. */
.index-column {
  float: left;
  width: 20%;
  min-width: 100px;
}
.section {
  margin-top: 0px;
  float: right;
  width: 78%;
}

/* Make the README text easier to read. */
.section p, .section li, .section pre {
  max-width: 800px;
  line-height: 18px;
  font-size: 13px;
}

/* Enable scrolling of README code blocks on small displays. */
pre {
  overflow: auto;
}
EOSTYLE

  # As the last style node, the attributes above will override Appledoc's stylesheet.
  head_node = html_doc.at_css("head")
  head_node.add_child(style_node)

  # 3. Fix all anchor links by looking for the links that GitHub uses to mark headers,
  #    and giving them appropriate ids (the anchor link minus the starting "#").
  #    I don't know how the anchors work on GitHub itself without names or IDs
  #    --perhaps they have JS or server-side routing.
  anchor_links = html_doc.css("a[href^='#'][class='anchor']")
  return false if !anchor_links.length # In case GitHub changes the way they format headers

  anchor_links.each do |link|
    link["id"] = link["href"][1..-1]
  end
  
  # 4. Add the version number to the library title as shown on the web,
  #    to clarify when it's updated. (We don't add this in a place that's seen
  #    in the docset when in Xcode 'cause it's obvious when that's updated.)
  html_doc.at_css("#libraryTitle").content += DOCSET_VERSION


  html_file = File.open(html_path, "w")
  html_file.write(html_doc.to_html)
  html_file.close

  return true
end
