task default: %w[test]

desc "Install dependencies"
task :dependencies do
  sh './Scripts/install.sh'
end

desc "Build and test"
task :test => [:dependencies] do
  sh './Scripts/build.sh'
end
