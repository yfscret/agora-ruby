module Agora
  module Errors
    class AgoraError < StandardError; end
    class ConfigurationError < AgoraError; end
    class APIError < AgoraError
      attr_reader :response

      def initialize(message, response = nil)
        super(message)
        @response = response
      end
    end
  end
end