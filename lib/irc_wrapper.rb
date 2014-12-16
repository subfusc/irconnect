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
end
