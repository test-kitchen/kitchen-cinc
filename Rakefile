require "bundler/gem_tasks"

require "rake/testtask"
Rake::TestTask.new(:unit) do |t|
  t.libs.push "lib"
  t.test_files = FileList["spec/**/*_spec.rb"]
  t.verbose = true
end

desc "Run all test suites"
task test: %i{unit}

begin
  require "cookstyle/chefstyle"
  require "rubocop/rake_task"
  RuboCop::RakeTask.new(:style) do |task|
    task.options += ["--display-cop-names", "--no-color"]
  end
rescue LoadError
  puts "cookstyle/chefstyle is not available. (sudo) gem install cookstyle to do style checking."
end

begin
  require "yard"

  # Options and the file list live in .yardopts so that a bare `yard` from the
  # command line produces exactly what `rake doc` does.
  YARD::Rake::YardocTask.new(:doc)

  desc "List anything in lib/ that is still undocumented"
  task :doc_coverage do
    sh "yard stats --list-undoc"
  end
rescue LoadError
  desc "Generate YARD documentation (not installed)"
  task :doc do
    abort "YARD is not installed. Run: bundle install"
  end
end

desc "Run all quality tasks"
task quality: %i{style}

task default: %i{test quality}
