# phony TCPSocket for testing purposes
class MockTCPSocket
  attr_reader :client_output
  attr_accessor :server_responses

  def initialize(*)
    @server_responses  = []
    @client_output     = ''
  end

  def gets
    fail 'No response from server' if @server_responses.empty?
    @server_responses.shift + "\r\n"
  end

  def print(output)
    @client_output << output
  end
end
