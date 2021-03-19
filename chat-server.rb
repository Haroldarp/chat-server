require 'socket'

port = 5000
@debug = false
runServer = false
@users = {}
@rooms = {}
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
        elsif @rooms[name] != nil && params[0][1] == "g"
            groupBroadcast(socket, name, message)
        else
            socket.puts "NotFound"
        end
    end
end

def privateMessage(socket, username, message)
    socket.puts "Ok"
    sender_key = @users.key(socket)
    socket_receiver = @users[username]
    socket_receiver.puts "/MESSAGE #{sender_key} #{message}"
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

    if @rooms[groupname].include?(sender_key)
        @rooms[groupname].each do |username|
            if @users[username] != socket
                @users[username].puts "/MESSAGE #{groupname}_#{sender_key} #{message}"
            end
        end
    else
        socket.puts "Error"
    end
end

def createRoom (socket, groupName)
    search_key = @users.key(socket)
    grupo = []
    grupo << search_key
    if @rooms[groupName] == nil && @users[groupName] == nil 
        @rooms[groupName] = grupo
        socket.puts "Ok"
    else
        socket.puts "Taken"
    end
end

def acceptRequest(socket, groupName, newMember)
    # Accept request (owner)
    if @rooms[groupName].kind_of?(Array)
        @rooms[groupName].push(newMember)
        @users[newMember].puts "/ADDED #{groupName}"
        
    else
        (@rooms[groupName] ||= []).push(newMember)
        @users[newMember].puts "/ADDED #{groupName}"

    end

    @requests[groupName].delete(newMember)

    if @invites.has_key?(newMember)
        if @invites[newMember].include?(groupName)
            @invites[newMember].delete(groupName)
        end
    end
end

def makeInvitation(socket, groupName, newMember)
    # Make request (invite user)
    invitelist = []

    if @users.has_key?(newMember)

        if @invites.has_key?(newMember)
            invitelist = @invites[newMember]
        end

        if @invites[newMember].kind_of?(Array)
            @invites[newMember].push(groupName)
            @users[newMember].puts "/INVITED #{groupName}"

        else
            (@invites[newMember] ||= invitelist).push(groupName)
            @users[newMember].puts "/INVITED #{groupName}"
        end

    end
end

def addRoom(socket, params)

    if params[0] == "-f"
        groupName = params[1]

        if @rooms.has_key?(groupName)
            sender_key = @users.key(socket)
            room_members = @rooms[groupName]

            if params.length > 2 && sender_key == room_members[0]
                $i = 2
                while $i < params.length do
                    newMember = params[$i]
                    if @users.has_key?(newMember)
                        room_members << newMember
                        @users[newMember].puts "/ADDED #{groupName}"
                    end
                    $i+=1
                end
                @rooms[groupName] = room_members
                socket.puts "Ok"

            else
                socket.puts "NoOwner"
            end
        else 
            socket.puts "RoomNotFound"
        end
    
    else
        groupName = params[0]
        sender_key = @users.key(socket)
        room_members = @rooms[groupName]

        if params.length > 1 && sender_key == room_members[0]
            $i = 1
            while $i < params.length do
                newMember = params[$i]

                if @requests.has_key?(groupName)
                    if @requests[groupName].include?(newMember)
                        acceptRequest(socket, groupName, newMember)
                    else
                        makeInvitation(socket, groupName, newMember)
                    end
                else
                    makeInvitation(socket, groupName, newMember)
                end
                $i += 1
            end

            socket.puts "Ok"
        else
            socket.puts "Error"
        end
    end

end

def join(socket, groupname)
    sender_key =  @users.key(socket)

    if @rooms.has_key?(groupname)
        room_members = @rooms[groupname]
        owner = room_members[0]

        if !@rooms[groupname].include?(sender_key)

            if @invites.has_key?(sender_key)
                if @invites[sender_key].include?(groupname)
                    room_members << sender_key
                    @rooms[groupname] = room_members

                    @rooms[groupname].each do |username|
                        if @users[username] != socket
                            @users[username].puts "/ROOMJOIN #{sender_key} joined #{groupname}"
                        end
                    end
                    @invites[sender_key].delete(groupname)
                    
                else
                    @users[owner].puts "/ROOMJOIN #{sender_key} request-to-join #{groupname}"
                   
                    requestlist = []
                    if @requests.has_key?(groupname)
                        requestlist = @requests[groupname]
                    end

                    if @requests[groupname].kind_of?(Array)
                        @requests[groupname].push(sender_key)
                    else
                        (@requests[groupname] ||= requestlist).push(sender_key)
                    end
                end

                socket.puts "Ok"
            else
                requestlist = []
                requestlist << sender_key
                @requests[groupname] = requestlist
                @users[owner].puts "/ROOMJOIN #{sender_key} request-to-join #{groupname}"
            end

        else
            socket.puts "Already"
        end

    else
        socket.puts "NotFound"
    end
end

def reject(socket, groupname)
    sender_key = @users.key(socket)
    if @rooms.has_key?(groupname) && @invites[sender_key].include?(groupname)
        # @requests[groupname].delete(sender_key)

        owner = @rooms[groupname][0]
        @users[owner].puts "/ROOMREJECT #{sender_key} reject"

        # @requests[groupname].delete(sender_key)
        @invites[sender_key].delete(groupname)
        socket.puts "Ok"
    else
        socket.puts "Error"
    end
end

def quitRoom(socket, groupname)
    sender_key = @users.key(socket);

    if @rooms[groupname] != nil
        if sender_key == @rooms[groupname][0]
            @rooms[groupname].each do |username|
                if @users[username] != socket
                    @users[username].puts "/ROOMQUIT #{sender_key} deleted #{groupname}"
                end
            end
            @rooms.delete(groupname)
            socket.puts "Ok"

        elsif @rooms[groupname].include?(sender_key)
            @rooms[groupname].each do |username|
                if @users[username] != socket
                    @users[username].puts "/ROOMQUIT #{sender_key} left #{groupname}"
                end
            end
            @rooms[groupname].delete(sender_key)
            socket.puts "Ok"
        else
            socket.puts "NotInRoom"
        end
    else
        socket.puts "Error"
    end
end

def requestList(socket, groupname)
    sender_key = @users.key(socket)

    if @rooms.has_key?(groupname)
        room_members = @rooms[groupname]
        if sender_key == room_members[0]
            if @requests.has_key?(groupname)
                if (!@requests[groupname].empty?)
                    socket.puts "#{@requests[groupname].inspect}"
                else
                    socket.puts "Empty"
                end
            else
                socket.puts "Empty"
            end
        else
            socket.puts "NoOwner"
        end
    else
        socket.puts "Error"
    end
end

def userList(socket)
    if (@users.length > 1)
        socket.puts "#{@users.keys}"
    else
        socket.puts "Empty"
    end
end

def roomList (socket)
    if @rooms.length >= 1
        socket.puts "#{@rooms.keys}"
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
                    requestList(socket, groupname)

                when "/USERLIST"
                    userList(socket)

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

