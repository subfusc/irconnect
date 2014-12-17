require 'socket'
require './lib/irc_command'

# Simple wrapper around common IRC commands
class IRCConnector
  DEFAULT_OPTIONS = { port: 6667, socket_class: TCPSocket }

  attr_reader :socket, :port, :connected, :nick, :server, :command_buffer

  def initialize(server, options = {})
    options         = DEFAULT_OPTIONS.merge(options)
    @server         = server
    @port           = options[:port]
    @nick           = options[:nick]
    @socket         = options[:socket_class].new(@server, @port)
    @command_buffer = []
  end

  def nick(name)
    send("NICK #{name}")
  end

  # host and server are typically ignored by servers
  # for security reasons
  def user(nick, host, server, full_name)
    send("USER #{nick} #{host} #{server} :#{full_name}")
  end

  def receive
    return command_buffer.shift unless command_buffer.empty?
    command = receive_command
    command.nil? ? nil : IRCCommand.new(command)
  end

  def receive_until
    skip_commands = []
    while (command = receive)
      if yield(command)
        command_buffer.unshift(*skip_commands)
        return command
      else
        skip_commands << command
      end
    end
  end

  private

  def receive_command
    command = socket.gets
    command.nil? ? nil : command.sub(/\r\n\Z/, '')
  end

  def send(cmd)
    socket.print("#{cmd}\r\n")
  rescue IOError
    raise
  end
end
