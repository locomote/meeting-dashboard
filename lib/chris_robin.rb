#!/usr/bin/env ruby
require 'her'
require 'cgi'
require 'matrix'

# --- config ---
ROBIN_URL=ENV.fetch('ROBIN_URL', 'https://api.robinpowered.com/v1.0')

ROBIN_ORGANIZATION=ENV.fetch('ROBIN_ORGANIZATION', 'locomote-queens-rd')
ROBIN_API_TOKEN=ENV.fetch('ROBIN_API_TOKEN', 'aMpYUFmM7nGWJnXCKIX9oTA81OHmQRS4SjrEiVRU6iudV3xrWxT158fmOEFzG214sYvajULyuWdkF5Vv11cvTYqByIhcMe2Ftpy9wCnJ4y2zBWAwnHaMJnN8mfM4z5wg')

class RobinTokenAuthentication < Faraday::Middleware
  def call(env)
    env[:request_headers]["Authorization"] = "Access-Token #{ROBIN_API_TOKEN}"
    @app.call(env)
  end
end

Her::API.setup url: ROBIN_URL do |c|
  c.use RobinTokenAuthentication
  c.use Faraday::Request::UrlEncoded
  c.use Her::Middleware::JsonApiParser
  c.use Faraday::Adapter::NetHttp
end
# --- config ---


# --- models ---
class User
  # include Her::Model - hmmm.. fetching users doesn't seem to work

 
  ATTRIBUTES = %i{id display_name is_organizer email}
  attr_reader(*ATTRIBUTES)
  def initialize(attributes)
    attributes.each do |attribute, value|
      instance_variable_set("@#{attribute}", value)
    end
  end

  def to_s
    "<User:#{id} #{display_name} #{is_organizer} #{email}>"
  end
end

class Event
  include Her::Model

  def invitees
    @invitees = super.map do |invitee|
      # hmmm... fetching users doesn't seem to work
      # User.fetch(invitee[:id])
      User.new(invitee)
    end
  end

  def to_occupancy   
    occupancy_array = []
    (480..1080).step(30) do |time_in_minutes|
      begin
        occupancy_array << (occupied?(time_in_minutes/60, time_in_minutes%60) ? 1 : 0)
      rescue
        occupancy_array << 0
      end
    end
    occupancy_array
  end

  def occupied?(hour, minute)
    start_time = to_minutes(started_at.to_time.localtime.hour, started_at.to_time.min)
    end_time = to_minutes(ended_at.to_time.localtime.hour, ended_at.to_time.min)
    time = to_minutes(hour, minute)
    time >= start_time and time < end_time
  end  

  def to_minutes(hour, minute)
    hour * 60 + minute
  end

  def to_s
    "#{started_at} [#{title}] #{description}\n     #{invitees.join("\n     ")}"
  end
end

class EventBlock
  include Enumerable

  attr_reader :from, :to, :events

  def initialize(attributes)
    @from = attributes[:from]
    @to = attributes[:to]
    @events = attributes[:events].map { |event_data| Event.find(event_data[:id]) }
  end

  def each
    events.each
  end

  def to_s
    events.join(", ")
  end
end

class EventBlocks
  attr_reader :items

  def initialize(items)
    @items = items.map { |event_block| EventBlock.new(event_block) }
  end

  def busy?
    items.present?
  end

  def invitees
    events.map(&:invitees)
  end

  def events
    items.map(&:events).flatten
  end

  def to_s
    busy? ? items.join("\n") : "<Free>"
  end
end

class Space
  include Her::Model

  belongs_to :location
  has_many :events

  attr_reader :event_blocks

  delegate :invitees, :busy?, to: :event_blocks

  # TODO - Does *her* have a better way of doing this??
  def events_upcoming
    self.class.get_raw("spaces/#{id}/events/upcoming") do |parsed_data, response|
      parsed_data[:data].map { |event_data| Event.new(event_data) }
    end
  end

  def busy=(event_blocks)
    @event_blocks = EventBlocks.new(event_blocks)
  end

  def busy_events
    event_blocks.events
  end


  def events_today
    now = Time.now
    get_events(now.beginning_of_day, now.end_of_day)
  end

  def events_remaining
    now = Time.now
    get_events(now, now.end_of_day)
  end

  def get_events(start_time, end_time)
    date_range = "spaces/#{id}/events/?after=#{robin_date(start_time)}&before=#{robin_date(end_time)}"
    self.class.get_raw("#{date_range}&auto_created=false") do |parsed_data, response|
      parsed_data[:data].map { |event_data| Event.new(event_data) }
    end
  end

  def get_occupancy
    
    occ_events = events_today
    occ_all_events = occ_events.map do |event|
      event.to_occupancy
    end
    occ_all_events << Event.new.to_occupancy
    occ_all_events.map { |a| Vector[*a] }.inject(:+)
  end

  def slug
    @slug ||= name.gsub(" ", "").downcase
  end

  def occupied_status
    busy? ? 'busy' : 'empty'
  end


  def robin_date (time)
    CGI::escape(time.strftime("%Y-%m-%dT%H:%M:%S%z"))
  end

  def to_s
    "#{id} : #{name} (#{occupied_status})\n  #{busy_events.join("\n")}"
  end
end

class Location
  include Her::Model

  has_many :spaces

  def spaces_free_busy
    self.class.get_raw("free-busy/spaces?location_ids=#{id}") do |parsed_data, response|
      parsed_data[:data].map do |item|
        Space.new(item[:space]).tap { |space| space.busy = item[:busy] }
      end
    end
  end

  def to_s
    "#{id} : #{name}\n  #{spaces.join("\n  ")}"
  end
end

class Organization
  include Her::Model

  has_many :locations
end
# --- models ---


# --- helpers ---
def organization
  @organization ||= Organization.find(ROBIN_ORGANIZATION)
end

def location
  @location ||= organization.locations.first
end

def spaces
  location.spaces.inject({}) do |h, space|
    h.update(space.name => space)
  end
end

def vizzini
  spaces['Vizzini']
end

def show_all
  location.spaces.each do |space|
    puts space
    space.events_upcoming.each do |event|
      puts event
    end
  end
end
# --- helpers ---


if __FILE__ == $0
#  show_all
#  puts
#  puts vizzini
#  puts vizzini.events_upcoming
#  puts
#  puts location.spaces_free_busy

  require 'action_view'
  extend ActionView::Helpers::DateHelper

  location.spaces_free_busy.each do |space|
    puts "#{space.name} (#{space.occupied_status})"

    space.events_remaining.each do |event|
      puts "remaining #{event.title} #{event.started_at.to_time.localtime.to_formatted_s(:iso8601)}"
    end
    space.events_today.each do |event|
      puts "today #{event.title} #{event.started_at.to_time.localtime.to_formatted_s(:iso8601)}"
    end

    puts space.get_occupancy

    h = space.get_occupancy.to_a.map do |x|
      {class: x==1 ? "greybox" : "whitebox" , value: x}
    end 
    #space.slug

    h.unshift ( {class: "title", value: space.slug }  )

    puts "#{h}"
     
  end


#  location.spaces.each do |space|
#    puts "#{space} #{space.attributes}"
#  end
end
