# phony TCPSocket for testing purposes
class MockTCPSocket
  @@server_responses  = []
  @@client_output     = String.new
  
  # take the same parameters as the TCPSocket constructor
  # for the sake of consistency; they are not used
  def initialize(host, port)
  end

  def gets
    raise "No response from server" if @@server_responses.empty?
    @@server_responses.shift + "\r\n"
  end

  def print(output)
    @@client_output << output
  end

end
