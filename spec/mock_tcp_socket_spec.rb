require 'rspec'
require './spec/mock/mock_tcp_socket'

describe 'MockTCPSocket' do
  before(:each) do
    @mock_socket = MockTCPSocket.new
  end

  it 'creates an instance of MockTCPSocket' do
    expect(@mock_socket).to_not be(nil)
    expect(@mock_socket).to be_an_instance_of(MockTCPSocket)
  end

  it 'responds like a server' do
    expect(@mock_socket).to respond_to(:server_responses)
  end

  it 'provides fake client output' do
    expect(@mock_socket).to respond_to(:client_output)
  end

  describe 'gets' do
    it 'responds to requests' do
      expect(@mock_socket).to respond_to(:gets)
    end

    it 'returns fake server messages' do
      @mock_socket.server_responses << 'Test Message'
      expect(@mock_socket.gets).to eq("Test Message\r\n")
    end

    it 'fails when out of server responses' do
      expect { @mock_socket.gets }.to raise_error
    end
  end

  describe 'print' do
    it 'exists' do
      expect(@mock_socket).to respond_to(:print)
    end

    it 'adds a message to fake client output' do
      @mock_socket.print('Test Message')
      expect(@mock_socket.client_output).to eq('Test Message')
    end

  end
end
