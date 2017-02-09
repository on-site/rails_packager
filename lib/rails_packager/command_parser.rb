module RailsPackager
  class CommandParser
    attr_reader :env, :name, :args

    def self.parse(command)
      new(command).tap(&:parse)
    end

    def initialize(command)
      @parsed = false
      @unparsed = command
    end

    def parse
      return if @parsed
      @parsed = true

      result =
        if @unparsed.is_a?(Array)
          @env = parse_env(@unparsed.last)
          parse_command(@unparsed.first)
        else
          @env = {}
          parse_command(@unparsed)
        end

      raise ArgumentError, "Empty command is not allowed" if result.empty?
      @name = result.shift
      @args = result
    end

    private

    def parse_env(options)
      {}.tap do |result|
        if options.include?("unsetenv")
          options["unsetenv"].each do |var|
            result[var] = nil
          end
        end

        if options.include?("env")
          result.merge!(options["env"])
        end
      end
    end

    def parse_command(command, result = [])
      command = command.strip
      return result if command.empty?

      if command[0] == "'"
        value, remaining = command[1..-1].split("'", 2)
        raise ArgumentError, "Mismatched single quote" unless remaining
      elsif command[0] == '"'
        value, remaining = command[1..-1].split('"', 2)
        raise ArgumentError, "Mismatched single quote" unless remaining
      else
        value, remaining = command.split(" ", 2)
      end

      result << value
      parse_command(remaining || "", result)
    end
  end
end
