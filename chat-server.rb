require 'socket'

port = 2000
@users = {}

server = TCPServer.new(port)

loop do
    clientSocket = server.accept

    Thread.new(clientSocket) do |socket|
        loop do
            command = socket.gets.chomp

            if command.index(" ") != nil
                commands = command.split(" ",2)
                key_command = commands[0]
            else
                key_command = command
            end

            case key_command
                when "/ID"

                when "/CHAT"

                when "/LIST"
                    list(socket)

                when "/CLOSE"

            else
                socket.puts "INVALID COMMAND"
            end
        end
    end
end

def list(socket)
    sender_key = @users.key(socket)
    if (@users.length > 1)
        users_list = @users.select { |key, value| key != sender_key}
        socket.puts "#{users_list.keys}"
    else
        socket.puts "EMPTY"
    end
end