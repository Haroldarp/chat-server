require 'socket'

port = 2000
@users = {}
@roomList = {}
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

        if @users[username] != nil && params[0][1] == 'u'
            privateMessage(socket, username, message)
        elsif params[0][1] == 'g'
            broadcast(socket, message)
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
    if (@users.length >= 1)
        socket.puts "#{@users.keys}"
    else
        socket.puts "Empty"
    end
end

def createRoom(socket, groupName)
    search_key = @users.key(socket)
    grupo = [search_key]
    if  @roomList[groupName] == nil
        @roomList[groupName] = grupo
        socket.puts "Ok"

    else
        socket.puts "Taken" 
    end
    
end

#Hay que probar
def addRoom(groupName, username, params)
    if @roomList[groupName] != nil
        if params.length < 2
            newGroup = @roomList[groupName]
            newGroup << username
            @roomList[groupName] = newGroup
            socket.puts "Ok"
        else
            sock = @users[username]
            @invites[username] = groupName
            newGroup = @roomList[groupName]
            if sock.gets.chomp = "y"
                newGroup << username
                socket.puts "Ok"
            end
        end
    end
end

#Hay que probar
def join(socket, groupName)
    user = @users.key(socket)
    newGroup = @roomList[groupName]
    newGroup << user
    @roomList[groupName] = newGroup
    socket.puts "Ok"
end

#Hay que probar
def reject(socket, groupName)
    user = @users.key(socket)
    @invites.delete(user)
end

def roomList (socket)
    if @roomList.length > 1
        socket.puts "#{@roomList.keys}"
        socket.puts "Ok"
    else
        socket.puts "Error"
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
                    params = commands[1].split("-m ", 2)
                    chat(socket, params)

                when "/USERLIST"
                    list(socket)

                when "/ROOM"
                    groupname = commands[1]
                    createRoom(socket, groupname)

                when "/ROOMLIST"
                    roomList(socket)

                when "/ADD"
                    params = commands.split("-f")
                    addRoom(groupName, username, params)

                when "/JOIN"
                    join(socket, groupName)

                when "/REJECT"
                    reject(socket, groupName)

                when "/CLOSE"
                    logout(socket)
                    break

            else
                socket.puts "INVALID COMMAND"
            end
        end
    end
end

