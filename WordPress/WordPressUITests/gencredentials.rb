def create_static_let(key, value)
  "    static let #{key} = \"#{value}\""
end

def create_class()
"public class WPUITestCredentials {
#{yield}
}
"
end

def get_file()
  # rawpath = ENV['WPUITEST_CONFIG']  
  rawpath = "~/.wpcom_test_credentials" # Since we use buddybuild_prebuild.sh to cp these files
  path = File.expand_path(rawpath)
  unless File.exist?(path)
    $stderr.puts "error: file #{path} not found"
    exit 1
  end
  File.read(path)
end

def extract_variables()
  variables = {}
  get_file().each_line do |l|
    k, v = l.split("=")

    if k == nil or k.strip.empty?
        next
    end

    if v != nil
        variables[k] = v.chomp
    else
        variables[k] = ""
    end
  end
  variables
end

print create_class() {
  extract_variables().map {|k, v| create_static_let(k, v)}.join("\n")
}


