require 'pry'
# represents an IRC Command received from the server
class IRCCommand
  attr_reader :prefix, :command, :params, :last_param

  # IRC message format:
  # :<prefix> <command> <params> :<trailing>
  # info on parsing commands:
  # http://goo.gl/N3YGLq
  def initialize(command_string)
    fail 'Bad IRC command format' if (command_string =~
      / \A (?::([^\040]+)\040)? # prefix
      ([A-Za-z]+|\d{3})                         # command
      ((?:\040[^:][^\040]+)*)                   # params, minus last
      (?:\040:?(.*))?                           # last param
      \Z /x).nil?

    @prefix  = Regexp.last_match(1)
    @command = Regexp.last_match(2)
    parse_params(Regexp.last_match(3), Regexp.last_match(4))
  end

  private

  def parse_params(param, param_last)
    if param.empty?
      @params = []
    else
      @params = param.split
      @params << param_last unless param_last.nil?
    end
    @last_param = @params.last
  end
end
