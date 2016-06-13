require 'sinatra/base'
require 'json'
require 'aws-sdk'

Dir[File.dirname(__FILE__) + "/plugins/*.rb"].each {|file| require file }

DOWN_STATE = "DOWN"

class App < Sinatra::Base
  set :bind, "0.0.0.0"

  get "/" do
    "<p>The site is up!</p>"
  end

  post "/webhook" do

    # Verify the api-key sent is what we expect
    unless ENV['api-key'].eql?(params['api-key'])
      raise Exception.new("Invalid API KEY")
    end

    # parse the JSON data that was provided by Pingdom
    pingdom_data = JSON.parse(request.body.read)

    # We only wnat to react to a down event
    if pingdom_data['current_state'].eql?(DOWN_STATE)

      # Query dynamodb for data on this check_id to decide what tesponse to use
      check_data = get_check_data(pingdom_data['check_id'])

      # If there is no check_data then fail
      unless check_data.count > 0
        raise Exception.new("check_id #{pingdom_data['check_id']} has no entry in dynamodb.")
      end

      # Grab the data from the first item and respond based on check_data type
      check_data = check_data.items[0]
      puts "#{pingdom_data['check_name']} is #{DOWN_STATE} taking action of type #{check_data['type']}"
      eval("Plugins::#{check_data['type']}.response(check_data)")
    end
  end

  # Get the the check data from dyanmo
  def get_check_data(check_id)
    dynamodb = Aws::DynamoDB::Client.new({region: 'us-east-1'})

    dynamodb.query({
      table_name: "pingdom_response",
      key_conditions: {
        "check_id" => {
          attribute_value_list: ["#{check_id}"],
          comparison_operator: "EQ",
        },
      }
    })
  end

end
