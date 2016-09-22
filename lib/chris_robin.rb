#!/usr/bin/env ruby
require 'action_view'
require 'json'
require 'date'

# ----- replace with something better? ----
ROBIN_API_TOKEN=ENV.fetch('ROBIN_API_TOKEN', 'l2CWtLjIh57qBj38gjVhkQuHEVX9MSbm8Ozxk4qWmK22KwevfUpMuBKBCQhBFI3o6S1r4toWFC6GjPCZMPudEh1SGRqc7CqjKGHA0GbuMwXthlI1fVXd1KRuJ0McJ0nh')
ROBIN_URL=ENV.fetch('ROBIN_URL', 'https://api.robinpowered.com/v1.0')
CACHE_MINUTES=ENV.fetch('CACHE_MINUTES', 1).to_i
LOCATION_ID=ENV.fetch('LOCATION_ID', 3502).to_i

ROBIN_CACHE_DIR=ENV.fetch('ROBIN_CACHE_DIR', '.cache')
# TODO convert to ruby
%x{[ -d "#{ROBIN_CACHE_DIR}" ] || mkdir -p "#{ROBIN_CACHE_DIR}"}


def cache_key(path)
  # TODO convert to ruby
  "#{ROBIN_CACHE_DIR}/#{%x{echo "#{path}" | md5}.strip}"
end

def flush_cache(f)
  # TODO convert to ruby
  %x([ -e "#{f}" ] && find "#{f}" -mmin +"#{CACHE_MINUTES}" -exec rm {} \\;)
end

def get_from_cache(path)
  f=cache_key(path)
  flush_cache(f)
  if File.exists?(f)
    STDERR.puts "[cached from #{f} ...]" if ENV['DEBUG']
  else
    STDERR.puts "[caching to #{f} ...]" if ENV['DEBUG']
    %x{curl --silent -H "Authorization: Access-Token #{ROBIN_API_TOKEN}" -X GET "#{ROBIN_URL}/#{path}" > "#{f}"}
  end
  File.read(f)
end

def get(path)
  get_from_cache path
end
# ----- replace with something better? ----



class Invitee
  def initialize(data)
    @name = data["display_name"]
  end

  def to_s
    @name
  end
end

class Event
  include ActionView::Helpers::DateHelper
  attr_reader :title, :invitees

  def initialize(data)
    @started_at = DateTime.parse(data["started_at"])
    @title = data["title"]
    @invitees = data["invitees"].map { |invitee_data| Invitee.new(invitee_data) }
  end

  def to_s
    "  #{started_at} #{title} #{invitees.map(&:to_s).join(", ")}"
  end

  def started_at
    time_ago_in_words(@started_at)
  end
end

class Space
  attr_reader :name, :id

  def initialize(data)
    @name = data["name"]
    @id = data["id"]
  end

  def self.each
    JSON.parse(
      get_from_cache "locations/#{LOCATION_ID}/spaces"
    )["data"].map { |data| yield new(data) }
  end

  def upcoming_events
    JSON.parse(
      get_from_cache "spaces/#{id}/events?after=#{today}&before=#{tomorrow}"
    )["data"].map { |data| Event.new(data) }
  end

  def to_s
    "#{name}\n#{upcoming_events.join("\n")}"
  end

  private

  def today
    @today ||= %x{date +%Y-%m-%d}.strip
  end

  def tomorrow
    Date.parse(today) + 2
  end
end

class BusySpace
  attr_reader :name, :busy 
  def initialize(space_data)
    @name = space_data["space"]["name"]
    @busy = space_data["busy"].count > 0
  end 

  def get_space
    {name: @name, busy: @busy}
  end

end

class FreeBusy
  
  def initialize
    
  end

  def say_something
    puts "say_something"
  end

  def self.get_busy
      busy_data = JSON.parse (get_from_cache "free-busy/spaces?location_ids=#{LOCATION_ID}")
      busy_hash = {}
      busy_data["data"].each do |space_data|
        busy_hash[space_data["space"]["name"]] = space_data["busy"].count == 0 ? "Empty" : "Busy"
      end
      busy_hash
  end


end

if __FILE__ == $0
  require 'table_print'
  #Space.each do |space|
  #  puts space
  #end
  puts FreeBusy.get_busy

  
  #puts fb.get_busy
  
end