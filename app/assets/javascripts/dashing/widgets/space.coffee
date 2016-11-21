class Dashing.Space extends Dashing.Widget

  ready: ->
    if not @get('status')
      @set 'error', 'No data'
      @set 'status', 'error'

  onData: (data) ->

    status = switch
      when @get('occupied_status') == 'busy' then 'occupied'
      when @get('occupied_status') == 'empty' then 'available'
      else 'green'

    @set 'show_title', @get('event_title')
    @set 'show_invitees', @get('invitees')


    @set 'status', status

    if status is 'error'
      if not data.hasOwnProperty('error')
        # Error condition because of a missing field
        @set 'error', 'Data provided without "warnings" and "criticals" fields.'
    
    