require 'io/console'

module Flumtter
  class Keyboard
    extend Util

    class Command
      attr_reader :name, :command, :help
      def initialize(command, help="", &blk)
        @name = command.is_a?(Regexp) ? command.inspect : command
        @command = command.is_a?(String) ? command.to_reg : command
        @help = help
        @blk = blk
      end

      def call(*args)
        @blk.call(*args)
      end
    end

    class << self
      @@commands = []

      def input(twitter)
        loop do
          input = STDIN.noecho(&:gets)
          next if input.nil?
          twitter.pause
          callback(input.chomp, twitter)
          twitter.resume
        end
      rescue Interrupt
      end

      def command_list
        char_len = @@commands.max_by{|c|c.name.size}.name.size + 1
        @@commands.map do |c|
          c.name.ljust(char_len) + c.help
        end.join("\n")
      end

      def callback(input, twitter)
        if input == "?"
          Window::Popup.new("Command List", <<~EOF).show
            #{command_list}

            For more information, please see the following Home page.
            http://github.com/flum1025/flumtter3
            This software is released under the MIT License
            Copyright © @flum_ 2016
          EOF
        else
          @@commands.each do |command|
            if m = input.match(command.command)
              return command.call(m, twitter)
            end
          end
          puts "Command not found".color
        end
      end

      def add(command, help, &blk)
        @@commands << Command.new(command, help) do |*args|
          begin
            blk.call(*args)
          rescue SystemExit => e
            raise e
          rescue Exception => e
            error e
          end
        end
      end
    end
  end
end
