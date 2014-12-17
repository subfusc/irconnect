require 'rspec'
require './lib/irc_connector.rb'
require './spec/mock/mock_tcp_socket.rb'

describe 'IRCConnector' do
  before(:each) do
    @connection = IRCConnector.new('irc.fake.net', socket_class: MockTCPSocket)
  end

  it 'establishes a connection' do
    expect(@connection.nil?).to be(false)
    expect(@connection).to be_a(IRCConnector)
    expect(@connection.socket).to respond_to(:client_output)
    expect(@connection.socket).to respond_to(:server_responses)
  end

  it 'sets the NICK' do
    expect { @connection.nick('fakename') }.to_not raise_error
    expect(@connection.socket.client_output).to eq("NICK fakename\r\n")
  end

  it 'sets the USER' do
    expect { @connection.user('nick', 'h', 's', 'bot') }.to_not raise_error
    expect(@connection.socket.client_output).to eq("USER nick h s :bot\r\n")
  end

  it 'receives commands' do
    @connection.socket.server_responses << ':irc.fakenode.net 001 bot ' \
      ':Welcome to fakenode IRC bot'

    cmd = @connection.receive

    expect(cmd.nil?).to be(false)
    expect(cmd).to be_an_instance_of(IRCCommand)
  end
end
