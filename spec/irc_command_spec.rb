require 'rspec'

describe 'IRCCommand' do
  it 'parses commands' do
    fake_response = ':irc.fakenode.net 001 bot :Welcome to fakenode IRC bot'
    cmd = IRCCommand.new(fake_response)

    expect(cmd.nil?).to be(false)
    expect(cmd).to be_an_instance_of(IRCCommand)
    expect(cmd.prefix).to eq('irc.fakenode.net')
    expect(cmd.command).to eq('001')
    expect(cmd.params).to eq(['bot', 'Welcome to fakenode IRC bot'])
    expect(cmd.last_param).to eq('Welcome to fakenode IRC bot')
  end
  it 'sets values to nil when appropriate' do
    cmd = IRCCommand.new('PING')

    expect(cmd.nil?).to be(false)
    expect(cmd).to be_an_instance_of(IRCCommand)
    expect(cmd.prefix).to be(nil)
    expect(cmd.command).to eq('PING')
    expect(cmd.params).to eq([])
    expect(cmd.last_param).to be(nil)
  end
end
