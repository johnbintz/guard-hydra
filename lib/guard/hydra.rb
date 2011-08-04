require 'guard'
require 'guard/guard'

require 'hydra'
require 'hydra/master'

class Guard::Hydra < Guard::Guard
  MATCHERS = {
    :rspec => '**/*_spec.rb'
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
      :env => 'test'
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

    run_all if @options[:all_on_start]
  end

  def run_on_change(files = [])
    files.uniq!
    Guard::UI.info "Running Hydra on #{files.join(', ')}"
    run_all if run_hydra(files)
  end

  def run_all
    Guard::UI.info "Running Hydra on all matching tests..."
    run_hydra(matching_tests)
  end

  private
  def run_hydra(files = [])
    File.unlink @options[:runner_log] if runner_log? && @options[:clear_runner_log]

    start = Time.now

    hydra = Hydra::Master.new(
      :listeners => [ Hydra::Listener::ProgressBar.new ],
      :files => files.uniq,
      :environment => @options[:env],
      :config => @options[:hydra_config]
    )

    Guard::UI.info sprintf("Tests completed in %.6f seconds", Time.now - start)

    puts File.read(@options[:runner_log]) if runner_log? && @options[:show_runner_log]
    hydra.failed_files.empty?
  end

  def runner_log?
    File.exist?(@options[:runner_log])
  end

  def rails_application
    File.expand_path('config/application')
  end

  def matching_tests
    Guard::Watcher.match_files(self, @options[:test_matchers].collect { |match| Dir[MATCHERS[match]] }.flatten).uniq
  end
end
