require "hedgerow/version"

class Hedgerow
  class << self
    def with(name, opts = {})
      if status = lock(name, opts[:timeout] || 10)
        yield
      else
        raise LockFailure.new("Could not acquire lock.")
      end
    ensure
      release(name) if status
    end

    def lock(name, timeout)
      validate_name!(name)
      parse_response connection.prepare("SELECT GET_LOCK(?, ?)").execute(name, timeout)
    end

    def release(name)
      validate_name!(name)
      parse_response connection.prepare("SELECT RELEASE_LOCK(?)").execute(name)
    end

    def validate_name!(name)
      if name.length > 64
        raise LockFailure.new("MySQL enforces a maximum length on lock names of 64 characters.")
      end
    end

    def parse_response(r)
      val = r.to_a.flatten.first rescue 0
      val == 1 ? true : false
    end

    def connection=(connection)
      @@connection = connection
    end

    def connection
      @@connection ||= begin
        if defined?(ActiveRecord)
          ActiveRecord::Base.connection.raw_connection
        else
          raise "Could not find connection for hedgerow."
        end
      end
    end
  end

  class LockFailure < StandardError; end
end
