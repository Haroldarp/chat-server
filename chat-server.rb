require 'socket'

port = 2000
@users = {}

server = TCPServer.new(port)
puts "El servidor esta en modo listening!"

def chat(socket, params)

    if params.length() == 1
        message = params[0]
        broadcast(socket, message)

    elsif params.length() == 2
        username = params[0][3..-1]
        puts "#{username}"
        message = params[1]

        if @users[username] != nil
            privateMessage(socket, username, message)
        else
            socket.puts "NotFound"
        end
    end
end

def broadcast(socket, message)
    sender_key = @users.key(socket)
    @users.each_value do |socket_value|
        if socket_value != socket
            socket_value.puts "#{sender_key}: #{message}"
        end
    end
end

def privateMessage(socket, username, message)
    sender_key = @users.key(socket)
    socket_receiver = @users[username]
    socket_receiver.puts "#{sender_key}: #{message}"
end

def list(socket)
    sender_key = @users.key(socket)
    if (@users.length > 1)
        users_list = @users.select { |key, value| key != sender_key}
        socket.puts "#{users_list.keys}"
    else
        socket.puts "Empty"
    end
end

def login (socket, username)
    if @users[username] == nil
        @users[username] = socket
        socket.puts "Ok"
    else
        socket.puts "Taken"
    end
end

def logout (socket)
    search_key = @users.key(socket)
    delete = @users.delete(search_key)

    if delete == nil
        socket.puts "Error"
    else
        socket.puts "Ok"
        socket.close
    end
end

loop do
    clientSocket = server.accept

    Thread.new(clientSocket) do |socket|
        loop do
            puts "Se conecto un nuevo cliente!"
            command = socket.gets.chomp

            if command.index(" ") != nil
                commands = command.split(" ",2)
                key_command = commands[0]
            else
                key_command = command
            end

            case key_command
                when "/ID"
                    username = commands[1]
                    login(socket, username)

                when "/CHAT"
                    params = commands[1].split("_-m ", 2)
                    chat(socket, params)

                when "/USERLIST"
                    list(socket)

                when "/CLOSE"
                    logout(socket)
                    break

            else
                socket.puts "INVALID COMMAND"
            end
        end
    end
end

