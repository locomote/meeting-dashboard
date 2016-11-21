
require 'net/http'
require 'json'
require 'cgi'

current_valuation = 0
server = "http://api.icndb.com"



require 'chris_robin'
Dashing.scheduler.every '180s' do

  location.spaces_free_busy.each do |space|
    event_title = ""
    invitees = ""
    
    if space.busy_events.count > 0 
      event = space.busy_events.first
      event_title = event.title
      invitees_a = []
      end_time = "#{event.ended_at.to_time.localtime.to_s(:time)}"

      event.invitees.each do |invitee|
        invitees_a << invitee.display_name 
      end
      invitees = invitees_a.to_sentence
    end    
    
    todaysevents = space.events_today.map  do |event|  
      {cols: {title: event.title ,start_time: "#{event.started_at.to_time.localtime.to_s(:time)}", end_time: "#{event.ended_at.to_time.localtime.to_s(:time)}"}}      
    end

    events_remaining = space.events_remaining.map  do |event|  
      {cols: {title: event.title ,start_time: "#{event.started_at.to_time.localtime.to_s(:time)}", end_time: "#{event.ended_at.to_time.localtime.to_s(:time)}"}}      
    end

    #puts "#{events_remaining}"

    hrows = [
      { cols: [ {value: 'Start'}, {value: 'Finish'}, {value: 'Title'} ] }
    ]
    
    Dashing.send_event(space.slug, { occupied_status: space.occupied_status, event_title: event_title, 
                                     invitees: invitees, end_time: end_time, todaysevents: events_remaining,
                                     rows: events_remaining, 
                                     hrows: hrows })
  end

  rows = location.spaces_free_busy.map do |space|
    room = space.get_occupancy.to_a.map do |x|
      {class: x==1 ? "graybox" : "whitebox" , value: x}
    end 
    room.unshift ( {class: "title", value: space.name }  )

    { cols: room }
  end

  header = [ {value: "Time"}]
  # 8am to 8pm
  (480..1080).step(30) do |time_in_minutes|
      header << {value: "#{time_in_minutes/60}:#{(time_in_minutes%60 == 0) ? "00" : "30" }"}
  end

  hrow = [ { cols: header}  ]
  
  uri = URI("#{server}/jokes/random?limitTo=[nerdy]")


  res = Net::HTTP.get(uri)
  j = JSON[res]
  #Get the joke
  joke = CGI.unescapeHTML(j['value']['joke'])
  puts joke

  Dashing.send_event('schedule', { hrows: hrow, rows: rows, chuckfact: joke } )
  
end

