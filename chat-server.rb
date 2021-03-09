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
                when "/Prueba"
                    socket.puts "Hola mundo"

            else
                socket.puts "INVALID COMMAND"
            end
        end
    end
end

