current_valuation = 0

require 'chris_robin'
Dashing.scheduler.every '10s' do


  # curl -X GET https://api.robinpowered.com/v1.0/locations/3502/spaces -H "Authorization: Access-Token l2CWtLjIh57qBj38gjVhkQuHEVX9MSbm8Ozxk4qWmK22KwevfUpMuBKBCQhBFI3o6S1r4toWFC6GjPCZMPudEh1SGRqc7CqjKGHA0GbuMwXthlI1fVXd1KRuJ0McJ0nh"
  #response = Faraday.get 'https://api.robinpowered.com/v1.0/locations/3502/spaces -H "Authorization: Access-Token l2CWtLjIh57qBj38gjVhkQuHEVX9MSbm8Ozxk4qWmK22KwevfUpMuBKBCQhBFI3o6S1r4toWFC6GjPCZMPudEh1SGRqc7CqjKGHA0GbuMwXthlI1fVXd1KRuJ0McJ0nh"'
  #begin
  #  dubai = Faraday.new(:url => 'https://api.robinpowered.com/v1.0/locations/spaces/14260/events') do |faraday|
  #    faraday.headers['Authorization'] = 'Access-Token l2CWtLjIh57qBj38gjVhkQuHEVX9MSbm8Ozxk4qWmK22KwevfUpMuBKBCQhBFI3o6S1r4toWFC6GjPCZMPudEh1SGRqc7CqjKGHA0GbuMwXthlI1fVXd1KRuJ0McJ0nh'
  #end
  #end
  #dubai_response = dubai.get
  #debugger

  location.spaces_free_busy.each do |space|
    puts "#{space} #{space.busy?} #{space.invitees}"
    event_title = ""
    invitees = ""

    
    if space.busy_events.count > 0 
      event = space.busy_events.first
      event_title = event.title
      invitees_a = []
      end_time = "#{event.ended_at.to_time.localtime.to_s(:time)}"
      puts end_time

      event.invitees.each do |invitee|
        invitees_a << invitee.display_name 
      end
       = invitees_a.to_sentence

    end    
    
    event_list = ""
    space.todays_events.each  do |event|  
      event_list << "<p> #{event.title} #{event.started_at.to_time.localtime.to_s(:time)} - #{event.ended_at.to_time.localtime.to_s(:time)} </p>"
    end

    puts event_list

    
    Dashing.send_event(space.slug, { occupied_status: space.occupied_status, event_title: event_title, invitees: invitees, end_time: end_time  })
  end

end
