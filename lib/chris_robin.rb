#!/usr/bin/env ruby
require 'her'

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

  # {"id"=>98058970, "event_id"=>18748693, "user_id"=>nil, "email"=>"abugajewska@locomote.com", "display_name"=>"Aleksandra Bugajewska", "response_status"=>"accepted", "is_organizer"=>false, "is_resource"=>false, "updated_at"=>"2016-09-22T12:26:28+0000", "created_at"=>"2016-09-05T04:45:42+0000"}
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
    #date_range = "spaces/#{id}/events/?after=#{DateTime.now.in_time_zone(Time.zone).beginning_of_day}&before=#{DateTime.now.in_time_zone(Time.zone).end_of_day}"
    #date_range = "spaces/#{id}/events/?after=#{DateTime.now.yesterday}&before=#{DateTime.now.tomorrow}"
    date_range = "spaces/#{id}/events/?after=#{Date.today}T00%3A00%3A00%2B1000&before=#{Date.today+1}T00%3A00%3A00%2B1000"
    #date_range = "spaces/#{id}/events/?after=#{Date.yesterday}&before=#{Date.tomorrow}"
    puts date_range
    self.class.get_raw("#{date_range}&auto_created=false") do |parsed_data, response|
      parsed_data[:data].map { |event_data| Event.new(event_data) }
    end
  end

  def slug
    @slug ||= name.gsub(" ", "").downcase
  end

  def occupied_status
    busy? ? 'busy' : 'empty'
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
#    space.busy_events.each do |event|
#      puts "  [#{event.title}] started #{time_ago_in_words(event.started_at)} ago"
#      event.ended_at
#      puts "  [#{event.title}] finishes #{event.ended_at.to_time.localtime}"
#      event.invitees.each do |invitee|
#        puts "    #{invitee.display_name}"
#      end
#    end
    space.events_today.each do |event|
      puts "#{event.title} #{event.started_at.to_time.localtime.to_formatted_s(:iso8601)}"
    end

  end


#  location.spaces.each do |space|
#    puts "#{space} #{space.attributes}"
#  end
end
