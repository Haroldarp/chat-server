# chat-server
 Chat TCP server made in Ruby Language.
 
## How to execute:
First, you must install ruby: [ruby installer](https://rubyinstaller.org/downloads/)
- On a terminal write: `ruby chat-server.rb` to run the chat server.

On another terminal run a client using **[telnet](https://social.technet.microsoft.com/wiki/contents/articles/38433.windows-10-enabling-telnet-client.aspx)** or **nc** on port **2000**.

Youtube link: [Chat Server v0.0.1 in Ruby](https://www.youtube.com/playlist?list=PLmb6gm2Z5Kv_o2cBcOW1U9IKhLttkPer_)

Commands:
- **To login:** `/ID {username}`
- **To list connected users:** `/LIST`
- **To send a message to a user:** `/CHAT {username}_{message}`
- **To logout:** `/CLOSE`
