require 'rspec'
require './lib/irc_connector.rb'
require './spec/mock/mock_tcp_socket.rb'

describe 'IRCConnector' do
  before(:each) do
    @connection = IRCConnector.new('irc.fake.net', socket_class: MockTCPSocket)
  end

  it 'creates an instance of IRCConnector' do
    expect(@connection.nil?).to be(false)
    expect(@connection).to be_a(IRCConnector)
  end

  describe 'nick' do
    it 'sets the NICK' do
      expect { @connection.nick('fakename') }.to_not raise_error
      expect(@connection.socket.client_output).to eq("NICK fakename\r\n")
    end

    it 'raises an error when given an invalid IRC nick or < 2 characters' do
      expect { @connection.nick('X') }.to raise_error(RuntimeError)
      expect { @connection.nick('$$$$') }.to raise_error(RuntimeError)
    end
  end

  describe 'user' do
    it 'sets the USER' do
      expect { @connection.user('nick', 'h', 's', 'bot') }.to_not raise_error
      expect(@connection.socket.client_output).to eq("USER nick h s :bot\r\n")
    end
  end

  describe 'receiving commands' do
    it 'receives and parses commands' do
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

      @connection.socket.server_responses += [
        'NOTICE AUTH :*** Looking up your hostname...',
        'NOTICE AUTH :*** Found your hostname, welcome back',
        'NOTICE AUTH :*** Checking ident',
        'NOTICE AUTH :*** No identd (auth) response',
        ':irc.fakenode.net 001 bot :Welcome to the fakenode IRC Network bot'
      ]

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
      ].each { |r| expect(@connection.receive).to eq(IRCCommand.new(r)) }

      expect { @connection.receive }.to raise_error(RuntimeError)
    end
  end

  describe 'logging in' do
    it 'logs in to a server' do
      @connection.socket.server_responses += [
        'NOTICE AUTH :*** Looking up your hostname...',
        'NOTICE AUTH :*** Found your hostname, welcome back',
        'NOTICE AUTH :*** Checking ident',
        'NOTICE AUTH :*** No identd (auth) response',
        ':irc.fakenode.net 001 bot :Welcome to the fakenode IRC Network bot'
      ]

      expect { @connection.login('bot', '127.0.0.1', '127.0.0.1', 'IRC bot') }
        .to_not raise_error

      expect("NICK bot\r\nUSER bot 127.0.0.1 127.0.0.1 :IRC bot\r\n")
        .to eq(@connection.socket.client_output)

      [
        'NOTICE AUTH :*** Looking up your hostname...',
        'NOTICE AUTH :*** Found your hostname, welcome back',
        'NOTICE AUTH :*** Checking ident',
        'NOTICE AUTH :*** No identd (auth) response'
      ].each { |r| expect(@connection.receive).to eq(IRCCommand.new(r)) }

      expect { @connection.receive }.to raise_error(RuntimeError)

      @connection.socket.server_responses += [
        'NOTICE AUTH :*** Looking up your hostname...',
        'NOTICE AUTH :*** Found your hostname, welcome back',
        'NOTICE AUTH :*** Checking ident',
        'NOTICE AUTH :*** No identd (auth) response',
        ':irc.fakenode.net 001 bot :Welcome to the fakenode IRC Network bot',
        ':irc.fakenode.net 431 :No nickname given'
      ]
    end
  end

  describe 'ping / pong' do
    it 'responds to server pings with pong to keep connection alive' do
      commands = [
        'NOTICE AUTH :*** Looking up your hostname...',
        'NOTICE AUTH :*** Found your hostname, welcome back',
        'NOTICE AUTH :*** Checking ident',
        'NOTICE AUTH :*** No identd (auth) response'
      ]
      commands.each do |cmd|
        @connection.socket.server_responses << "NOTICE AUTH :#{cmd}"
      end

      response_size = @connection.socket.server_responses.size
      @connection.socket.server_responses.insert(
        rand(response_size), 'PING :irc.fakenode.net'
      )

      commands.each do |c|
        command = @connection.receive
        expect(command).to_not be(nil)
        expect(command).to be_an_instance_of(IRCCommand)
        expect(command.prefix).to be(nil)
        expect(command.command).to eq('NOTICE')
        expect(command.params).to eq(['AUTH', c])
      end

      expect { @connection.receive }.to raise_error(RuntimeError)
      expect(@connection.socket.client_output)
        .to eq("PONG :irc.fakenode.net\r\n")
    end
  end

  describe 'joining channels' do
    it 'raises an error when attempting to join an invalid channel' do
      @connection.socket.server_responses <<
        ":irc.fakenode.net 403 bot imaginary :That channel doesn't exist"
      expect { @connection.join_channel('imaginary') }
        .to raise_error(RuntimeError)
    end

  end
end
