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

  it 'waits for a specific command' do
    login_commands = {
      '001' => 'RPL_WELCOME',
      '431' => 'ERR_NONICKNAMEGIVEN',
      '432' => 'ERR_ERRONEUSNICKNAME',
      '433' => 'ERR_NICKNAMEINUSE',
      '436' => 'ERR_NICKCOLLISION',
      '461' => 'ERR_NEEDMOREPARAMS',
      '462' => 'ERR_ALREADYREGISTERED'
    }

    resp = [
      'NOTICE AUTH :*** Looking up your hostname...',
      'NOTICE AUTH :*** Found your hostname, welcome back',
      'NOTICE AUTH :*** Checking ident',
      'NOTICE AUTH :*** No identd (auth) response',
      ':irc.fakenode.net 001 bot :Welcome to the fakenode IRC Network bot'
    ]

    @connection.socket.server_responses += resp

    cmd = @connection.receive_until { |c| login_commands.include?(c.command) }
    expect(cmd).to_not be(nil)
    expect(cmd).to be_an_instance_of(IRCCommand)
    expect(cmd.prefix).to eq('irc.fakenode.net')
    expect(cmd.command).to eq('001')
    expect(cmd.params).to eq([
      'bot', 'Welcome to the fakenode IRC Network bot'
    ])
    expect(cmd.last_param).to eq('Welcome to the fakenode IRC Network bot')

    cmd = @connection.receive_until { |c| c.last_param.include?('welcome') }
    expect(cmd).to_not be(nil)
    expect(cmd).to be_an_instance_of(IRCCommand)
    expect(cmd.prefix).to be(nil)
    expect(cmd.command).to eq('NOTICE')
    expect(cmd.params).to eq(
      ['AUTH', '*** Found your hostname, welcome back']
    )
    expect(cmd.last_param).to eq('*** Found your hostname, welcome back')

    [
      'NOTICE AUTH :*** Looking up your hostname...',
      'NOTICE AUTH :*** Checking ident',
      'NOTICE AUTH :*** No identd (auth) response'
    ].each do |r|
      expect(@connection.receive).to eq(IRCCommand.new(r))
    end
    expect { @connection.receive }.to raise_error(RuntimeError)
  end
end
# prefix cmd params last
