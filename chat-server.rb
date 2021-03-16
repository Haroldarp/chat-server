require 'socket'

port = 2000
@users = {}
@grouplist = {}
@invites = {}


server = TCPServer.new(port)
puts "El servidor esta en modo listening!"

def chat(socket, params)

    if params.length() == 1
        message = params[0][3..-1]
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
    socket.puts "Ok"
    sender_key = @users.key(socket)
    @users.each_value do |socket_value|
        if socket_value != socket
            socket_value.puts "#{sender_key}: #{message}"
        end
    end
end

def privateMessage(socket, username, message)
    socket.puts "Ok"
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

def createRoom (socket, groupName)

    search_key = @user.keys(socket)
    grupo = []
    grupo << search_key
    if @grouplist[groupName] == nil
        @grouplist[groupName] = grupo
        socket.puts "Ok"
    else
        socket.puts "Taken"
    end

end

def roomList (socket)

    if @grouplist.length >= 1
        socket.puts "#{@grouplist.keys}"
    else
        socket.puts "Empty"
    end

end

def inviteList (socket)
    sender_key = @users.key(socket)

    if @invites.has_key?(sender_key)
        if @invite[sender_key].empty?
            socket.puts "Empty"
        
        else
        socket.puts "#{@invites[sender_key]}"
        end
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
    puts "Se conecto un nuevo cliente!"

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
                    params = commands[1].split("_-m ", 2)
                    chat(socket, params)

                when "/ROOM"
                    groupName = commands[1]
                    createRoom(socket, groupName)

                when "/ROOMLIST" 
                       roomList(socket)

                when "/USERLIST"
                    list(socket)

                when "/INVITELIST"
                    inviteList(socket)

                when "/CLOSE"
                    logout(socket)
                    break

            else
                socket.puts "INVALID COMMAND"
            end
        end
    end
end

