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
    expect(@connection.socket).to respond_to(:client_output)
  end

  it 'sets the NICK' do
    expect { @connection.nick('fakename') }.to_not raise_error
    expect(@connection.socket.client_output).to eq("NICK fakename\r\n")
  end

  it 'sets the USER' do
    expect { @connection.user('nick', 'h', 's', 'bot') }.to_not raise_error
    expect(@connection.socket.client_output).to eq("USER nick h s :bot\r\n")
  end
end
