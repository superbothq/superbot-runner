module Superbot
  module Runner
    module CLI
      class RootCommand < Clamp::Command
        include Superbot::Validations
        include Superbot::Cloud::Validations

        parameter "PATH", "path to test suite"

        option ['--browser'], 'BROWSER', "Browser type to use. Can be either local or cloud", default: 'local'
        option ['--region'], 'REGION', 'Region for remote webdriver'
        option ['--no-teleport'], :flag, 'Do not start teleport before running'
        option ['--org'], 'ORGANIZATION', 'Name of organization to take action', attribute_name: :organization

        def execute
          open_teleport
          sorted_files.each(&method(:run_test_file))
        ensure
          close_teleport
        end

        private

        def open_teleport
          return if no_teleport?

          @teleport = Thread.new do
            Superbot::Teleport::CLI::RootCommand.new('teleport').run(teleport_options)
          rescue StandardError => e
            abort "Teleport error: #{e.message}"
          end

          sleep 0.1 until @teleport.stop?
        end

        def teleport_options
          {
            '--browser' => browser,
            '--region' => region,
            '--org' => organization
          }.compact.to_a.flatten
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
          @teleport&.kill
        end
      end
    end
  end
end
