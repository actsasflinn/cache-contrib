begin
  require_library_or_gem 'memcached'

  module ActionController
    module Session
      class MemcachedStore < AbstractStore
        def initialize(app, options = {})
          # Support old :expires option
          options[:expire_after] ||= options[:expires]

          super

          @default_options = {
            :namespace => 'rack:session',
            :memcache_server => 'localhost:11211'
          }.merge(@default_options)

          @pool = options[:cache] || Rails::Memcached.new(@default_options[:memcache_server], @default_options)
#          unless @pool.servers.any? { |s| s.alive? }
#            raise "#{self} unable to find server during initialization."
#          end
          @mutex = Mutex.new

          super
        end

        private
          def get_session(env, sid)
            sid ||= generate_sid
            begin
              session = @pool.get(sid) || {}
            rescue Memcached::Error, Errno::ECONNREFUSED
              session = {}
            end
            [sid, session]
          end

          def set_session(env, sid, session_data)
            options = env['rack.session.options']
            expiry  = options[:expire_after] || 0
            @pool.set(sid, session_data, expiry)
            return true
          rescue Memcached::Error, Errno::ECONNREFUSED
            return false
          end
      end
    end
  end
rescue LoadError
  # MemCache wasn't available so neither can the store be
end
