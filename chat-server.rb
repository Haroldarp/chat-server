require 'socket'

port = 2000
@users = {}
@rooms = {}
@invites = {}
@requests = {}

server = TCPServer.new(port)
puts "El servidor esta en modo listening!"

def chat(socket, params)

    if params.length() == 1
        message = params[0][3..-1]
        broadcast(socket, message)

    elsif params.length() == 2
        name = params[0][3..-1]
        message = params[1]

        if @users[name] != nil && params[0][1] == 'u'
            privateMessage(socket, name, message)
        elsif @rooms[name] != nil && params[0][1] == 'g'
            groupBroadcast(socket, name, message)
        else
            socket.puts "NotFound"
        end
    else
        socket.puts "Error"
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
    socket.puts "Ok"
    sender_key = @users.key(socket)
    @rooms[groupname].each do |username|
        if @users[username] != socket
            @users[username].puts "/MESSAGE #{groupname}_#{sender_key} #{message}"
        end
    end
end

def privateMessage(socket, username, message)
    socket.puts "Ok"
    sender_key = @users.key(socket)
    socket_receiver = @users[username]
    socket_receiver.puts "/MESSAGE #{sender_key} #{message}"
end

def list(socket)
    if !@users.empty?
        socket.puts "#{@users.keys}"
    else
        socket.puts "Empty"
    end
end

def createRoom(socket, groupName)
    search_key = @users.key(socket)
    group = []
    group << search_key
    if  @rooms[groupName] == nil
        @rooms[groupName] = group
        socket.puts "Ok"
    else
        socket.puts "Taken"
    end

end

def acceptRequest(groupname, newMember)
    # Accept request (owner)
    if @rooms[groupname].kind_of?(Array)
        @rooms[groupname].push(newMember)
    else
        (@rooms[groupname] ||= []).push(newMember)
    end
    @requests[groupname].delete(newMember)

    if @invites.has_key?(newMember)
        if @invites[newMember].include?(groupname)
            @invites[newMember].delete(groupname)
        end
    end
end

def makeRequest(socket, groupname, newMember)
      # Make request (invite user)
    inviteList = []
    requestList = []
    if @requests.has_key?(groupname)
        requestList = @requests[groupname]
    end

    if @users.has_key?(newMember)
        if @requests[groupname].kind_of?(Array)
            @requests[groupname].push(newMember)
        else
            (@requests[groupname] ||= requestList).push(newMember)
        end

        if @invites.has_key?(newMember)
            inviteList = @invites[newMember]
        end

        if @invites[newMember].kind_of?(Array)
            @invites[newMember].push(groupname)
        else
            (@invites[newMember] ||= inviteList).push(groupname)
        end
    else
        socket.puts "Error"
    end
end

#Hay que probar
def addRoom(socket, params)
    if params[0] == "-f"
        groupName = params[1]

        if @rooms[groupName] != nil
            sender_key = @users.key(socket)
            room_members = @rooms[groupName]

            if params.length > 2 && sender_key == room_members[0]
                $i = 2
                while $i < params.length do
                    if @users.has_key?(params[$i])
                        room_members << params[$i]
                        $i +=1
                    end
                end
                @rooms[groupName] = room_members
                puts "#{@rooms[groupName]}"
                socket.puts "Ok"
            else
                socket.puts "Error"
            end

        else
            socket.puts "NotFound"
        end
    else
        groupname = params[0]
        sender_key = @users.key(socket)
        room_members = @rooms[groupname]

        if params.length > 1 && sender_key == room_members[0]
            $i = 1
            while $i < params.length do
                newMember = params[$i]
                socket.puts "#{newMember}"

                if @requests.has_key?(groupname)
                    if @requests[groupname].include?(newMember)
                        acceptRequest(groupname, newMember)
                    else
                        makeRequest(socket, groupname, newMember)
                    end
                else
                  makeRequest(socket, groupname, newMember)
                end
                $i+=1
            end

            puts "#{@requests[groupname]}"
            socket.puts "Ok"

        else
            socket.puts "Error"
        end
    end
end

def inviteList(socket)
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

def requestList(socket, groupname)
    sender_key = @users.key(socket)

    if @rooms.has_key?(groupname)
        room_members = @rooms[groupname]
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
    sender_key = @users.key(socket)

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

def join(socket, groupname)
    sender_key = @users.key(socket)

    if @rooms.has_key?(groupname)
        room_members = @rooms[groupname]
        owner = room_members[0]

        if @requests.has_key?(groupname)
            if @requests[groupname].include?(sender_key)
                room_members << sender_key
                @rooms[groupname] = room_members
    
                @rooms[groupname].each do |username|
                    if @users[username] != socket
                        @users[username].puts "/ROOMJOIN #{sender_key} joined #{groupname}"
                    end
                end
                @requests[groupname].delete(sender_key)
                @invites[sender_key].delete(groupname)
            else
                @users[owner].puts "/ROOMJOIN #{sender_key} request-to-join #{groupname}"
                @requests[groupname].push(sender_key)
            end

            socket.puts "Ok"
        else
            requestList = []
            requestList << sender_key
            @requests[groupname] = requestList
            @users[owner].puts "/ROOMJOIN #{sender_key} request-to-join #{groupname}"
        end
    else
        socket.puts "NotFound"
    end
end

def reject(socket, groupname)
    sender_key = @users.key(socket)
    if rooms.has_key?(groupname) && @requests[groupname].include?(sender_key)
        @requests[groupname].delete(sender_key)

        owner = rooms[groupname][0]
        @users[owner].puts "/ROOMREJECT #{sender_key} reject"

        @requests[groupname].delete(sender_key)
        @invites[sender_key].delete(groupname)
        socket.puts "Ok"
    else
        socket.puts "Error"
    end
end

def roomList(socket)
    if @rooms.length >= 1
        socket.puts "#{@rooms.keys}"
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
                    params = commands[1].split(" -m ", 2)
                    chat(socket, params)

                when "/USERLIST"
                    list(socket)

                when "/ROOM"
                    groupname = commands[1]
                    createRoom(socket, groupname)

                when "/ROOMLIST"
                    roomList(socket)

                when "/INVITELIST"
                    inviteList(socket)

                when "/REQUESTLIST"
                    groupname = commands[1]
                    requestList(socket, groupname)

                when "/ADD"
                    params = commands[1].split(" ")
                    addRoom(socket, params)

                when "/QUIT"
                    groupname = commands[1]
                    quitRoom(socket, groupname)

                when "/JOIN"
                    groupname = commands[1]
                    join(socket, groupname)

                when "/REJECT"
                    groupname = commands[1]
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

