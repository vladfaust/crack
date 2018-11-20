require "socket"

def handle_client(client)
  # message = client.gets
  message = client.gets(1)
  client.print("HTTP/1.0 200 Success\r\n\r\nHello World!\n")
  client.close
end

server = TCPServer.new("localhost", 5000)
puts "\nListening"
while client = server.accept?
  spawn handle_client(client)
end
