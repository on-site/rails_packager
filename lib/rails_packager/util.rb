module RailsPackager
  module Util
    module_function

    def deep_freeze(object)
      case object
      when Hash
        object.freeze
        object.each { |k, v| deep_freeze(k); deep_freeze(v) }
      when Array
        object.freeze
        object.each { |y| deep_freeze(y) }
      when Symbol
      # Unneeded
      else
        object.freeze
      end
    end

    TERMINAL_FILES = deep_freeze([".", "/", ""])

    def glob_match?(glob, file)
      if File.fnmatch(glob, file, File::FNM_PATHNAME | File::FNM_DOTMATCH)
        true
      elsif !TERMINAL_FILES.include?(file)
        glob_match?(glob, File.dirname(file))
      end
    end
  end
end
