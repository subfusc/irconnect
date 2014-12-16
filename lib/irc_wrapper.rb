require 'socket'

# Simple wrapper around common IRC commands
class IRCWrapper
  DEFAULT_OPTIONS = { port: 6667, socket_class: TCPSocket }.freeze

  attr_reader :socket, :port, :connected, :nick, :server
  alias_method :connected?, :connected

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
  
  private

  def send(cmd)
    @socket.print("#{cmd}\r\n")
  rescue IOError
    raise
  end
end
