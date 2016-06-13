require 'aws-sdk'

module Plugins
  class SSM
    def self.response(pingdom_data)

      ssm = Aws::SSM::Client.new({region: 'us-east-1'})
      ssm.send_command({
        instance_ids: [pingdom_data['instance_id']], # required
        document_name: 'AWS-RunShellScript',
        timeout_seconds: 600,
        parameters: {
          'commands' => [pingdom_data['command']],
        }
      })
    end
  end
end
