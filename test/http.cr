require "http/server"

server = HTTP::Server.new do |context|
  context.response.print "Hello world!"
end

server.bind_tcp("localhost", 5000, reuse_port: true)
puts "\nListening"
server.listen

# wrk -c100 -t3 -d5 http://0.0.0.0:5000
# Running 5s test @ http://0.0.0.0:5000
#   3 threads and 100 connections
#   Thread Stats   Avg      Stdev     Max   +/- Stdev
#     Latency     2.61ms    1.52ms  35.88ms   97.24%
#     Req/Sec    12.34k     0.97k   13.81k    93.33%
#   184147 requests in 5.00s, 6.50MB read
# Requests/sec:  36795.61
# Transfer/sec:      1.30MB
