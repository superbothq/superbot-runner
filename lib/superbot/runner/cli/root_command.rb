module Superbot
  module Runner
    module CLI
      class RootCommand < Clamp::Command
        include Superbot::Validations
        include Superbot::Cloud::Validations

        parameter "PATH", "path to test suite"

        option ['--browser'], 'BROWSER', "Browser type to use. Can be either local or cloud", default: 'local' do |browser|
          validates_browser_type browser
          require_login unless browser == 'cloud'
          browser
        end
        option ['--region'], 'REGION', 'Region for remote webdriver'
        option ['--no-teleport'], :flag, 'Do not start teleport before running'

        def execute
          open_teleport unless no_teleport?
          sorted_files.each(&method(:run_test_file))
        ensure
          close_teleport unless no_teleport?
        end

        private

        def open_teleport
          @teleport = Thread.new do
            Superbot::Web.run!(webdriver_type: browser, region: region)
          end

          if browser == 'local'
            chromedriver_path = Chromedriver::Helper.new.binary_path
            @chromedriver = Kommando.new "#{chromedriver_path} --silent --port=9515 --url-base=wd/hub"
            @chromedriver.run_async
          end
        end

        def sorted_files
          if File.directory?(path)
            Dir.glob(File.join(path, '*'))
               .map! { |f| [f.gsub(path, ''), f] }
               .sort
               .map(&:last)
          else
            [path]
          end
        end

        def run_test_file(test_file)
          file_extension = File.extname(test_file)
          puts "Running #{test_file}"
          case file_extension
          when '.side' then Superbot::Runner::Side.run(test_file)
          else puts "#{file_extension} scripts are not supported yet"
          end
        end

        def close_teleport
          sleep 1
          @chromedriver&.kill
          @teleport&.kill
        end
      end
    end
  end
end
