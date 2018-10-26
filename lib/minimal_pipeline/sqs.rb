require 'aws-sdk'

class MinimalPipeline
  # Here is an example of how to use this class to send a message onto a queue.
  #
  # ```
  # sqs = MinimalPipeline::Sqs.new
  # message = 'Beep boop'
  # sqs.send_message('queue-name', message)
  # ```
  class Sqs
    def initialize
      raise 'You must set env variable AWS_REGION or region.' \
        if ENV['AWS_REGION'].nil? && ENV['region'].nil?

      region = ENV['AWS_REGION'] || ENV['region']
      @client = Aws::SQS::Client.new(region: region)
    end

    # Places a message on a SQS queue
    #
    # @param queue_name [String] The name of the SQS queue
    # @param body [String] The message body to place on the queue
    # @return [Aws::SQS::Types::SendMessageResult] The result object
    def send_message(queue_name, body)
      queue_url = @client.get_queue_url(queue_name: queue_name).queue_url
      @client.send_message(queue_url: queue_url, message_body: body,
                           message_group_id: queue_name)
    end
  end
end
