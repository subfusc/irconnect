require 'socket'
require './lib/irc_command'

# Simple wrapper around common IRC commands
class IRCConnector
  DEFAULT_OPTIONS = { port: 6667, socket_class: TCPSocket }

  attr_reader :socket, :port, :connected, :nick, :server, :command_buffer

  LOGIN_COMMANDS = {
    '001' => 'RPL_WELCOME',
    '431' => 'ERR_NONICKNAMEGIVEN',
    '432' => 'ERR_ERRONEUSNICKNAME',
    '433' => 'ERR_NICKNAMEINUSE',
    '436' => 'ERR_NICKCOLLISION',
    '461' => 'ERR_NEEDMOREPARAMS',
    '462' => 'ERR_ALREADYREGISTERED'
  }

  def initialize(server, options = {})
    options         = DEFAULT_OPTIONS.merge(options)
    @server         = server
    @port           = options[:port]
    @nick           = options[:nick]
    @socket         = options[:socket_class].new(@server, @port)
    @command_buffer = []
  end

  def nick(name)
    fail 'Invalid NICK' unless
      name =~ /\A[a-z_\-\[\]\\^{}|`][a-z0-9_\-\[\]\\^{}|`]+\z/i
    send("NICK #{name}")
  end

  # host and server are typically ignored by servers
  # for security reasons
  def user(nickname, hostname, servername, fullname)
    send("USER #{nickname} #{hostname} #{servername} :#{fullname}")
  end

  def login(nickname, hostname, servername, fullname)
    nick(nickname)
    user(nickname, hostname, servername, fullname)
    reply = receive_until { |c| LOGIN_COMMANDS.include?(c.command) }
    fail 'Login error, no response from server' if reply.nil?
    fail "Login error: #{reply.last_param}" unless reply.command == '001'
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
    return nil if command.nil?
    if command =~ /\APING (.*?)\r\n\Z/
      send("PONG #{Regexp.last_match(1)}")
      receive_command
    else
      command.sub(/\r\n\Z/, '')
    end
  end

  def send(cmd)
    socket.print("#{cmd}\r\n")
  rescue IOError
    raise
  end
end
