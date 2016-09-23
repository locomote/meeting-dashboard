current_valuation = 0

require 'chris_robin'
Dashing.scheduler.every '5s' do


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
    Dashing.send_event(space.slug, { occupied_status: space.occupied_status })
  end

#  Dashing.send_event('melbourne', { occupied_status: busy_spaces["Melbourne"].downcase ,  })
#  Dashing.send_event('sanfrancisco', { occupied_status: busy_spaces["San Francisco"].downcase })
#  Dashing.send_event('dubai', { occupied_status: busy_spaces["Dubai"].downcase})
#  Dashing.send_event('vizzini', { occupied_status: busy_spaces["Vizzini"].downcase})



end
