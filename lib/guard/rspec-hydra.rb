require 'guard'
require 'guard/guard'
require 'guard/rspec'

module Guard
  class RSpecHydra < Guard::RSpec
    def initialize(watchers = [], options = {})
      super

      @options = {
        :rails_env => 'test',
        :rake_task => 'hydra:spec',
        :runner_log => 'hydra-runner.log',
        :show_runner_log => true
      }.merge(@options)
    end

    def start
      UI.info "Guard::Hydra is giving Guard::RSpec super run_all powers. Whoa!"
      super
    end

    def run_all
      File.unlink(@options[:runner_log]) if runner_log?

      system %{rake RAILS_ENV=#{@options[:rails_env]} #{@options[:rake_task]}}

      puts File.read(@options[:runner_log]) if runner_log? && @options[:show_runner_log]
    end

    private
    def runner_log?
      File.exist?(@options[:runner_log])
    end
  end
end
