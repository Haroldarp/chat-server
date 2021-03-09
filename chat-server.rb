require 'socket'

port = 2000
@users = {}

server = TCPServer.new(port)

def chat(socket, params)

    if params.length() == 1
        message = params[0]
        broadcast(socket, message)
    
    elsif params.length() == 2
        username = params[0]
        message = params[1]

        if @users[username] != nil
            privateMessage(socket, username, message)
        else
            socket.puts "INVALID USER"
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
        socket.puts "EMPTY"
    end
end
def login (socket, username)
    if @users[username] == nil
        @users[username] = socket
        socket.puts "OK"
    else
        socket.puts "TAKEN"
    end
end

def logout (socket)
    search_key = @users.key(socket)
    delete = @users.delete(search_key)

    if delete == nil
        socket.puts "ERROR"
    else
        socket.puts "OK"
        socket.close
    end
end

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
                    username = commands[1]
                    login(socket, username)

                when "/CHAT"
                    params = commands.split("_", 2)
                    chat(socket, params)

                when "/LIST"
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

