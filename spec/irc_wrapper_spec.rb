require 'rspec'
require './lib/irc_wrapper.rb'
require './spec/mock/mock_tcp_socket.rb'

describe 'IRCWrapper' do
  it "establishes a connection" do
    @connection = IRCWrapper.new(
      'test.server.irc.net',
      socket_class: MockTCPSocket
    )

    expect(@connection.nil?).to be(false)
    expect(@connection).to be_a(IRCWrapper)
  end
end
