# IRC SPESIFICATION
# <message> ::=
#     [':' <prefix> <SPACE> ] <command> <params> <crlf>
# <prefix> ::=
#     <servername> | <nick> [ '!' <user> ] [ '@' <host> ]
# <command> ::=
#     <letter> { <letter> } | <number> <number> <number>
# <SPACE> ::=
#     ' ' { ' ' }
# <params> ::=
#     <SPACE> [ ':' <trailing> | <middle> <params> ]
# <middle> ::=
#     <Any *non-empty* sequence of octets not including SPACE or NUL or CR or LF, the first of which may not be ':'>
# <trailing> ::=
#     <Any, possibly *empty*, sequence of octets not including NUL or CR or LF>
# <crlf> ::=
#     CR LF

module IRConnect
  # represents an IRC Command received from the server
  class Command
    attr_reader :sender, :ident, :host, :prefix, :command, :params, :last_param

    @@irc_command_regex = %r{
      \A (:(?<prefix>                                          # Start Prefix group
      (?<sender>[^!@\s]+)(!(?<ident>[^@\s]+))?(@(?<host>\S+))? # server | nick!user@host
      )\s)?                                                    # SPACE, End Prefix group
      (?<command>[A-Za-z]+|\d{3})                              # Command group
      \s                                                       # Separating space
      (?<params>[^\n\r]+)                                      # Get all params
      \Z
    }x

    def initialize(command_string)
      match = @@irc_command_regex.match(command_string)
      fail 'Bad IRC command format' unless match

      @prefix, @command = match['prefix'], match['command']
      @sender, @ident, @host = match['sender'], match['ident'], match['host']
      parse_params(match['params'])
    end

    def ==(other)
      prefix == other.prefix &&
        command == other.command &&
        params == other.params
    end

    private

    def parse_params(params)
      @params = params.split(' :')
      @last_param = @params.last
    end
  end
end
