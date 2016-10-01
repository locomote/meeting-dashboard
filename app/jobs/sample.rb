current_valuation = 0

require 'chris_robin'
Dashing.scheduler.every '10s' do

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

    puts "#{todaysevents}"

    hrows = [
      { cols: [ {value: 'Start'}, {value: 'Finish'}, {value: 'Title'} ] }
    ]
    
    Dashing.send_event(space.slug, { occupied_status: space.occupied_status, event_title: event_title, 
                                     invitees: invitees, end_time: end_time, todaysevents: todaysevents, 
                                     hrows: hrows, rows: todaysevents })
  end

end
