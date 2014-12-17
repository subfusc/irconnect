require 'socket'
require './lib/irc_command'

# Simple wrapper around common IRC commands
class IRCConnector
  DEFAULT_OPTIONS = { port: 6667, socket_class: TCPSocket }

  attr_reader :socket, :port, :connected, :nick, :server

  def initialize(server, options = {})
    @server     = server

    options     = DEFAULT_OPTIONS.merge(options)
    @port       = options[:port]
    @nick       = options[:nick]
    @socket     = options[:socket_class].new(@server, @port)
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
    command = receive_command
    return nil if command.nil?
    IRCCommand.new(command)
  end

  private

  def receive_command
    command = @socket.gets
    command.nil? ? command : command.sub(/\r\n\Z/, '')
  end

  def send(cmd)
    @socket.print("#{cmd}\r\n")
  rescue IOError
    raise
  end
end
