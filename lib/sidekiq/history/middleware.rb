module Sidekiq
  module History
    class Middleware
      include Sidekiq::Util

      attr_accessor :msg

      def call(worker, msg, queue)
        self.msg = msg

        data = {
          started_at: Time.now,
          payload: msg,
          worker: msg['class'],
          processor: "#{identity}-#{Thread.current.object_id}",
          queue: queue,
          finished_at: nil
        }
        
        
        index = Sidekiq.redis do |conn|
          conn.lpush(LIST_KEY, Sidekiq.dump_json(data))
          #unless Sidekiq.history_max_count == false
            #conn.ltrim(LIST_KEY, 0, Sidekiq.history_max_count - 1)
          #end
        end

        yield
        
        data[:finished_at] = Time.now
        Sidekiq.redis do |conn|
          conn.lset(LIST_KEY, -index, Sidekiq.dump_json(data))
        end
      end
    end
  end
end
