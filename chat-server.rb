require 'socket'

port = 5000
@debug = false
runServer = false
@users = {}
@grouplist = {}
@invites = {}
@requests = {}

while !runServer
    command = gets.chomp()
    params = command.split(" ")

    if params.length == 1 && params[0] == "Run-Server"
        runServer = !runServer

    elsif params.length == 2 && params[0] == "Run-Server" && (params[1] == "-v" || params[1] == "--verbose")
        @debug = true
        runServer = !runServer

    elsif params.length == 3 && params[0] == "Run-Server" && 
        (params[1] == "-p" || params[1] == "--port") && params[2] != nil
        port = params[2]
        runServer = !runServer

    elsif params.length == 4 && params[0] == "Run-Server" && 
        (params[1] == "-p" || params[1] == "--port") && params[2] != nil &&
        (params[3] == "-v" || params[3] == "--verbose")
        port = params[2]
        @debug = true
        runServer = !runServer

    else
        puts "INVALID RUN COMMAD"
    end
end

puts "Running in debug mode" if @debug
server = TCPServer.new(port)
puts "El servidor esta en modo listening!"

def chat(socket, params)

    if params.length() == 1
        message = params[0][3..-1]
        broadcast(socket, message)

    elsif params.length() == 2
        name = params[0][3..-1]
        message = params[1]

        if @users[name] != nil && params[0][1] == "u"
            privateMessage(socket, name, message)
        elsif @grouplist[name] != nil && params[0][1] == "g"
            groupBroadcast(socket, name, message)
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
            socket_value.puts "/MESSAGE #{sender_key} #{message}"
        end
    end
end

def groupBroadcast(socket, groupname, message)
    sender_key = @users.key(socket)
    @grouplist[groupname].each do |username|
        if @users[username] != socket
            @users[username].puts "/MESSAGE #{groupname}_#{sender_key} #{message}"
        end
    end
end

def join(socket, groupname)
    sender_key =  @users.key(socket)

    if @grouplist.has_key?(groupname)
        room_members = @grouplist[groupname]
        owner = room_members[0]

        if @requests.has_key?(groupname)
            if @requests[groupname].include?(sender_key)
                room_members << sender_key
                @grouplist[groupname] = room_members

                @grouplist[groupname].each do |username|
                    if @users[username] != socket
                        @users[username].puts "/ROOMJOIN #{sender_key} joined #{groupname}"
                    end
                end
                @requests[groupname].delete(sender_key)
                @invites[sender_key].delete(groupname)
            else
                @users[owner].puts "/ROOMJOIN #{sender_key} joined #{groupname}"
                @requests[groupname].push(sender_key)
            end
            socket.puts "Ok"
        else
            requestlist = []
            requestlist << sender_key
            @requests[groupname] = requestlist
            @users[owner].puts "/ROOMJOIN #{sender_key} request-to-join #{groupname}"
        end
    else
        socket.puts "NotFound"
    end
end

def reject(socket, groupname)
    sender_key =@users.key(socket)
    if @grouplist.has_key?(groupname) && @requests[groupname].include?(sender_key)
        @requests[groupname].delete(sender_key)

        owner = @grouplist[groupname][0]
        @users[owner].puts "/ROOMREJECT #{sender_key} reject"

        @requests[groupname].delete(sender_key)
        @invites[sender_key].delete(groupname)
        socket.puts "Ok"
    else
        socket.puts "Error"
    end
end

def requestlist(socket, groupname)
    sender_key = @users.key(socket)

    if @grouplist.has_key?(groupname)
        room_members = @grouplist[groupname]
        if sender_key == room_members[0]
            if @requests.has_key?(groupname)
                if (!@requests[groupname].empty?)
                    socket.puts "#{@requests[groupname].inspect}"
                else
                    socket.puts "Error"
                end
            else
                socket.puts "Error"
            end
        else
            socket.puts "NoOwner"
        end
    else
        socket.puts "Error"
    end
end

def quitRoom(socket, groupname)
    sender_key = @users.key(socket);

    if @grouplist[groupname] != nil
        if sender_key == @grouplist[groupname][0]
            @grouplist[groupname].each do |username|
                if @users[username] != socket
                    @users[username].puts "/ROOMQUIT #{sender_key} deleted #{groupname}"
                end
            end
            @grouplist.delete(groupname)
            socket.puts "ok"

        elsif @grouplist[groupname].include?(sender_key)
            @grouplist[groupname].each do |username|
                if @users[username] != socket
                    @users[username].puts "/ROOMQUIT #{sender_key} left #{groupname}"
                end
            end
            @grouplist[groupname].delete(groupname)
            socket.puts "ok"
        else
            socket.puts "NotInRoom"
        end
    else
        socket.puts "Error"
    end
end

def privateMessage(socket, username, message)
    socket.puts "Ok"
    sender_key = @users.key(socket)
    socket_receiver = @users[username]
    socket_receiver.puts "/MESSAGE #{sender_key} #{message}"
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
    search_key = @users.key(socket)
    grupo = []
    grupo << search_key
    if @grouplist[groupName] == nil
        @grouplist[groupName] = grupo
        socket.puts "Ok"
    else
        socket.puts "Taken"
    end

end

def acceptRequest(socket, groupName, newMember)
    # Accept request (owner)
    if @grouplist[groupName].kind_of?(Array)
        @grouplist[groupName].push(newMember)
    else
        (@grouplist[groupName] ||= []).push(newMember)
    end

    @requests[groupName].delete(newMember)

    if @invites.has_key?(newMember)
        if @invites[newMember].include?(groupName)
            @invites[newMember].delete(groupName)
        end
    end
end

def makeRequest(socket, groupName, newMember)
    # Make request (invite user)
    invitelist = []
    requestlist = []

    if @requests.has_key?(groupName)
        requestlist = @requests[groupName]
    end

    if @users.has_key?(newMember)
        if @requests[groupName].kind_of?(Array)
            @requests[groupName].push(newMember)
        else
            (@requests[groupName] ||= requestlist).push(newMember)
        end

        if @invites.has_key?(newMember)
            invitelist = @invites[newMember]
        end

        if @invites[newMember].kind_of?(Array)
            @invites[newMember].push(groupName)
        else
            (@invites[newMember] ||= invitelist).push(groupName)
        end

    end
end

def addRoom(socket, params)

    if params[0] == "-f"
        groupName = params[1]

        if @grouplist.has_key?(groupName)
            sender_key = @users.key(socket)
            room_members = @grouplist[groupName]

            if params.length > 2 && sender_key == room_members[0]
                $i = 2
                while $i < params.length do
                    newMember = params[$i]
                    if @users.has_key?(newMember)
                        room_members << newMember
                    end
                    $i+=1
                end
                @grouplist[groupName] = room_members
                socket.puts "Ok"

            else
                socket.puts "Error"
            end
        else 
            socket.puts "NotFound"
        end
    
    else
        groupName = params[0]
        sender_key = @users.key(socket)
        room_members = @grouplist[groupName]

        if params.length > 1 && sender_key == room_members[0]
            $i = 1
            while $i < params.length do
                newMember = params[$i]

                if @requests.has_key?(groupName)
                    if @requests[groupName].include?(newMember)
                        acceptRequest(socket, groupName, newMember)
                    else
                        makeRequest(socket, groupName, newMember)
                    end
                else
                    makeRequest(socket, groupName, newMember)
                end
                $i += 1
            end

            socket.puts "Ok"
        else
            socket.puts "Error"
        end
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
        if @invites[sender_key].empty?
            socket.puts "Empty"

        else
            socket.puts "#{@invites[sender_key].inspect}"
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
                    params = commands[1].split(" -m ", 2)
                    chat(socket, params)

                when "/ROOM"
                    groupName = commands[1]
                    createRoom(socket, groupName)

                when "/ADD"
                    params = commands[1].split(" ")
                    addRoom(socket, params)

                when "/ROOMLIST" 
                       roomList(socket)

                when "/JOIN"
                    groupname = commands[1]
                    join(socket, groupname)

                when "/REJECT"
                    groupname = commands[1]
                    reject(socket, groupname)

                when "/QUIT"
                    groupname = commands[1]
                    quitRoom(socket, groupname)

                when "/REQUESTLIST"
                    groupname = commands[1]
                    requestlist(socket, groupname)

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

