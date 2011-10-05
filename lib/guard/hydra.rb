require 'guard'

require 'guard/guard'

require 'hydra'
require 'hydra/master'

class Guard::Hydra < Guard::Guard
  MATCHERS = {
    :rspec => '**/*_spec.rb',
    :cucumber => '**/**/*{.feature}'
  }

  def initialize(watchers = [], options = {})
    super
    @options = {
      :runner_log => 'hydra-runner.log',
      :clear_runner_log => true,
      :show_runner_log => true,
      :hydra_config => 'config/hydra.yml',
      :test_matchers => [ :rspec ],
      :all_on_start => false,
      :env => 'test',
      :verbose => false
    }.merge(@options)
  end

  def start
    super
    Guard::UI.info "Guard::Hydra is waiting to run tests..."

    begin
      ENV['RAILS_ENV'] = @options[:env]
      require rails_application
    rescue LoadError
      Guard::UI.info "Not a Rails app, using default environment settings"
    end

    @did_fail = false

    run_all if @options[:all_on_start]
  end

  def run_on_change(files = [])
    if !(files = ensure_files(files)).empty?
      Guard::UI.info "Running Hydra on #{files.join(', ')}"
      if run_hydra(files)
        run_all if @did_fail
        @did_fail = false
      else
        @did_fail = true
      end
    end
  end

  def run_all
    Guard::UI.info "Running Hydra on all matching tests..."
    run_hydra(ensure_files(matching_tests))
  end

  private
  def run_hydra(files = [])
    if !files.empty?
      File.unlink @options[:runner_log] if runner_log? && @options[:clear_runner_log]

      start = Time.now

      hydra = Hydra::Master.new(
        :listeners => [ Hydra::Listener::ProgressBar.new ],
        :files => files,
        :environment => @options[:env],
        :config => @options[:hydra_config],
        :verbose => @options[:verbose]
      )

      Guard::UI.info sprintf("Tests completed in %.6f seconds", Time.now - start)

      puts File.read(@options[:runner_log]) if runner_log? && @options[:show_runner_log]
      hydra.failed_files.empty?
    else
      Guard::UI.info "No files matched!"
      false
    end
  end

  def runner_log?
    File.exist?(@options[:runner_log])
  end

  def rails_application
    File.expand_path('config/application')
  end

  def matching_tests
    Guard::Watcher.match_files(self, match_test_matchers).uniq
  end

  def match_test_matchers(source = nil)
    @options[:test_matchers].collect do |match| 
      path = MATCHERS[match]
      path = File.join(source, path) if source
      Dir[path] 
    end.flatten
  end

  def ensure_files(files = [])
    files.collect do |file|
      if File.directory?(file)
        match_test_matchers(file)
      else
        file
      end
    end.flatten.find_all { |file| File.file?(file) }.uniq
  end
end
