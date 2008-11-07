if RUBY_PLATFORM =~ /mswin|mingw/
  begin
    require 'win32/open3'
  rescue LoadError
    warn "You must 'gem install win32-open3' to use the github command on Windows"
    exit 1
  end
else
  require 'open3'
end

module GitHub
  class Command
    def initialize(block)
      (class << self;self end).send :define_method, :command, &block
    end

    def call(*args)
      arity = method(:command).arity
      args << nil while args.size < arity
      send :command, *args
    end
    
    def helper
      @helper ||= Helper.new
    end

    def options
      GitHub.options
    end

    def pgit(*command)
      puts git(*command)
    end

    def git(*command)
      sh ['git', command].flatten.join(' ')
    end

    def git_exec(*command)
      cmdstr = ['git', command].flatten.join(' ')
      GitHub.debug "exec: #{cmdstr}"
      exec cmdstr
    end

    def sh(*command)
      Shell.new(*command).run
    end

    def get_network_data(user)
      data = JSON.parse(open(helper.network_meta_for(user)).read)
    end
    
    def die(message)
      puts "=> #{message}"
      exit!
    end

    class Shell < String
      def initialize(*command)
        @command = command
      end

      def run
        GitHub.debug "sh: #{command}"
        _, out, err = Open3.popen3(*@command)

        out = out.read.strip
        err = err.read.strip

        if out.any?
          replace @out = out
        elsif err.any?
          replace @error = err
        end
      end

      def command
        @command.join(' ')
      end

      def error?
        !!@error
      end

      def out?
        !!@out
      end
    end
  end
end
