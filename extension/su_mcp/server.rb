require "socket"
require "json"

module SU_MCP
  # TCP server that runs inside SketchUp's UI thread via UI.start_timer.
  #
  # Two non-blocking guards keep SketchUp responsive:
  #   1. accept_nonblock + IO.select(0)   — never wait for new connections
  #   2. IO.select on the client socket   — never wait on a slow `gets`
  class Server
    DEFAULT_PORT      = 9876
    POLL_INTERVAL     = 0.1   # seconds between accept attempts
    READ_TIMEOUT      = 0.05  # seconds to wait for client data before giving up

    attr_reader :port

    def self.instance
      @instance ||= new
    end

    def initialize
      @port      = Sketchup.read_default("SU_MCP", "port", DEFAULT_PORT).to_i
      @port      = DEFAULT_PORT if @port <= 0 || @port > 65535
      @server    = nil
      @timer_id  = nil
      @running   = false
    end

    def running?
      @running
    end

    def start
      return if @running

      @server   = TCPServer.new("127.0.0.1", @port)
      @running  = true
      @timer_id = UI.start_timer(POLL_INTERVAL, true) { tick }

      Log.info("Listening on 127.0.0.1:#{@port}")
    rescue StandardError => e
      Log.error("Failed to start on port #{@port}: #{e.message}")
      stop
    end

    def stop
      @running = false
      UI.stop_timer(@timer_id) if @timer_id
      @server&.close
      @server = nil
      @timer_id = nil
    end

    def restart(new_port = nil)
      stop
      @port = new_port if new_port
      start
    end

    private

    def tick
      return unless @running
      return unless IO.select([@server], nil, nil, 0)

      client = @server.accept_nonblock
      handle_client(client)
    rescue IO::WaitReadable
      # No pending connection — normal.
    rescue StandardError => e
      Log.error("tick: #{e.message}")
    end

    def handle_client(client)
      data = read_line(client)
      if data.nil? || data.strip.empty?
        Log.info("Client connected but sent no data; closing.")
        return
      end

      request  = JSON.parse(data)
      response = Dispatcher.dispatch(request)
      client.write(response.to_json + "\n")
      client.flush
    rescue JSON::ParserError => e
      write_error(client, nil, -32700, "Parse error: #{e.message}")
    rescue StandardError => e
      Log.error("handle_client: #{e.message}")
      write_error(client, nil, -32603, e.message)
    ensure
      client.close rescue nil
    end

    # Wait briefly for the client to send a line. Returns nil on timeout
    # or socket error — never blocks the UI thread indefinitely.
    def read_line(client)
      ready, _, _ = IO.select([client], nil, nil, READ_TIMEOUT)
      return nil unless ready
      client.gets
    rescue Errno::ECONNRESET, IOError => e
      Log.error("read_line: #{e.message}")
      nil
    end

    def write_error(client, id, code, message)
      payload = { jsonrpc: "2.0", id: id, error: { code: code, message: message } }
      client.write(payload.to_json + "\n")
      client.flush
    rescue StandardError
      # Client may already be gone.
    end
  end
end
