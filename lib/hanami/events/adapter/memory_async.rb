require 'securerandom'

module Hanami
  module Events
    class Adapter
      # Asynchronous Memory Adapter
      #
      # @since 0.1.0
      #
      # @api private
      class MemoryAsync
        attr_reader :subscribers

        def initialize(logger: nil, **)
          @logger = logger
          @subscribers = []
          @event_queue = Queue.new
        end

        # Brodcasts event to all subscribes
        #
        # @param event [Symbol, String] the event name
        # @param payload [Hash] the event data
        #
        # @since 0.1.0
        def broadcast(event_name, payload)
          @event_queue << { id: SecureRandom.uuid, name: event_name, payload: payload }
        end

        # Subscribes block for selected event
        #
        # @param event_name [Symbol, String] the event name
        # @param block [Block] to execute when event is broadcasted
        #
        # @since 0.1.0
        def subscribe(event_name, &block)
          @subscribers << Subscriber.new(event_name, block, @logger)

          return if thread_spawned?
          thread_spawned!

          Thread.new do
            loop { call_subscribers }
          end
        end

        private

        def thread_spawned?
          @thread_spawned
        end

        def thread_spawned!
          @thread_spawned = true
        end

        def call_subscribers
          event = @event_queue.pop

          @subscribers.each do |subscriber|
            subscriber.call(event[:name], event[:payload])
          end
        end
      end
    end
  end
end
