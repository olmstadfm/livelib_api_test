require 'haml'
require 'ostruct'
require 'json'
require 'open-uri'
require 'pp'
require 'slop'

opts = Slop.parse do |o|
  o.string  '-s', '--session-id', 'active session id'
  o.integer '-i', '--interval',   'interval between api calls', default: 15
  o.string  '-l', '--login',      'export only messages from given user'
  o.on '--version', 'print version' do
    puts '0.0.1'
    exit
  end
  o.on '--help', 'print this message' do
    puts o
    exit
  end
end

unless opts[:session_id]
  puts 'You think it\'s magic? Give me session id with -s option!'
  exit
end

base_uri = 'http://livelib.ru/api/'
session = "&andyll=and7mpp4ss&session_id=#{opts[:session_id]}"

def conversation_list_uri
  base_uri + 'conversationlist' + session
end

def message_list_uri(recipient)
  base_uri + "messagelist?recipient=#{recipient}" + session
end

def json_from_uri(uri)
  JSON.parse(open(uri).read)
  sleep opts[:interval]
end

def conversation_list
  json_from_uri(conversation_list_uri)
end

def message_list(recipient)
  json_from_uri(message_list_uri(recipient))['data'].reverse
end

def participants
  conversation_list['data'].map{|c| c['reader']}
end

template = IO.read('template.html.haml')

for participant in participants
  File.open("#{participant}.html", "w") do |file|
    context = OpenStruct.new
    context.participant = participant
    context.message_list = message_list(participant)
    context.last_update = Time.now.strftime("%Y-%m-%d %H:%M:%S")
    file.write Haml::Engine.new(template).render(context)
  end
end
