require 'socket'
require './lib/command'

module IRConnect
  # Simple wrapper around common IRC commands
  class Connection
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

    JOIN_COMMANDS = {
      '461' => 'ERR_NEEDMOREPARAMS',
      '471' => 'ERR_CHANNELISFULL',
      '473' => 'ERR_INVITEONLYCHAN',
      '474' => 'ERR_BANNEDFROMCHAN',
      '475' => 'ERR_BADCHANNELKEY',
      '476' => 'ERR_BADCHANMASK',
      '403' => 'ERR_NOSUCHCHANNEL',
      '405' => 'ERR_TOOMANYCHANNELS',
      '332' => 'RPL_TOPIC',
      '353' => 'RPL_NAMREPLY'
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
      unless name =~ /\A[a-z_\-\[\]\\^{}|`][a-z0-9_\-\[\]\\^{}|`]+\z/i
        fail 'Invalid NICK'
      end
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
      if reply.command != '001'
        fail "Login error: #{reply.last_param}\n" \
          "Received: #{reply.command} -> #{LOGIN_COMMANDS[reply.command]}"
      end
    end

    def join_channel(chan)
      send("JOIN #{chan}")
      reply = receive_until { |c| JOIN_COMMANDS.include?(c.command) }

      fail 'Unable to join channel, unknown error' if reply.nil?
      unless reply.command == '332' || reply.command == '353'
        fail "Error joining #{chan}: #{reply.last_param} \n" \
          "Received: #{reply.command} -> #{JOIN_COMMANDS[reply.command]}"
      end
    end

    def privmsg(target, message)
      send("PRIVMSG #{target} :#{message}")
    end

    def receive(ignore_ping: true)
      return command_buffer.shift unless command_buffer.empty?

      command = receive_command(ignore_ping: ignore_ping)
      command.nil? ? nil : IRConnect::Command.new(command)
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

    def receive_command(ignore_ping: true)
      loop do
        command = socket.gets
        return nil if command.nil?

        if command =~ /\APING (.*?)\r\n\Z/ && ignore_ping
          send("PONG #{Regexp.last_match(1)}")
        else
          return command.sub(/\r\n\Z/, '')
        end
      end
    end

    def send(cmd)
      socket.print("#{cmd}\r\n")
    rescue IOError
      raise
    end
  end
end
