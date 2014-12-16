require 'rspec'
require './lib/irc_wrapper.rb'
require './spec/mock/mock_tcp_socket.rb'

describe 'IRCWrapper' do
  before(:each) do
    @connection = IRCWrapper.new('irc.fake.net', socket_class: MockTCPSocket)
  end

  it 'establishes a connection' do
    expect(@connection.nil?).to be(false)
    expect(@connection).to be_a(IRCWrapper)
  end
end
