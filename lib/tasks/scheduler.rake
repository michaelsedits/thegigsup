namespace :events do
    task :update => :environment do
        puts "Updating events from Songkick...\n"
        
        eventsCall = "http://api.songkick.com/api/3.0/metro_areas/24586/calendar.json?apikey=" + ENV["API_KEY"]
        
        events = Curl::Easy.new(eventsCall) do |curl|
            
        end
      
        events.perform
        
        eventNumber = JSON.parse(events.body_str)["resultsPage"]["totalEntries"].to_i
        
        if eventNumber > 50
            pages = eventNumber / 50.0
            if pages % 1 != 0
                pages = (eventNumber / 50) + 1
            else
                pages = eventNumber / 50
            end
        else
            pages = 1
        end
        
        eventsObjects = []
        
        pages.times do |i|
            n = i + 1
            eventsCall = eventsCall + '&page=' + n.to_s
            events = Curl::Easy.new(eventsCall) do |curl|
            
            end
            
            events.perform
            
            eventsObjects << JSON.parse(events.body_str)["resultsPage"]["results"]["event"]
            
            eventsObjects.each do |eventObject|
                eventObject.each do |event|
                    if event["type"] == "Concert"
                        if (Event.find_by songkick_id: event["id"].to_i) == nil
                            if (Venue.find_by songkick_id: event["venue"]["id"].to_i) == nil
                                venueCall = "http://api.songkick.com/api/3.0/venues/" + event["venue"]["id"].to_s + ".json?apikey=" + ENV["API_KEY"]
                    
                                venueCurl = Curl::Easy.new(venueCall) do |curl|
                        
                                end
                    
                                venueCurl.perform
                    
                                venueJSON = JSON.parse(venueCurl.body_str)
                    
                                venueJSON = venueJSON["resultsPage"]["results"]["venue"]
                    
                                @venue = Venue.new(
                                    songkick_id: venueJSON["id"].to_i,
                                    name: venueJSON["displayName"],
                                    city: venueJSON["city"]["displayName"],
                                    zip: venueJSON["zip"].to_i,
                                    latitude: venueJSON["lat"].to_f,
                                    longitude: venueJSON["lng"].to_f,
                                    street: venueJSON["street"],
                                    website: venueJSON["website"],
                                    description: venueJSON["description"]
                                )
                    
                                @venue.save
                            else
                                @venue = Venue.find_by songkick_id: event["venue"]["id"].to_i
                            end
                
                            @event = Event.new(
                                songkick_id: event["id"].to_i,
                                start: event["start"]["datetime"],
                                songkick_link: event["uri"]
                            )
                
                            @event.save
                
                            @venue.events << @event
                
                            bands = event["performance"]
                            headliners = []
                            supporting_acts = []
                
                            bands.each do |band|
                                if (Band.find_by songkick_id: band["artist"]["id"].to_i) == nil
                                    @band = Band.new(
                                        songkick_id: band["artist"]["id"].to_i,
                                        name: band["artist"]["displayName"]
                                    )
                            
                                    @band.save
                                else
                                    @band = Band.find_by songkick_id: band["artist"]["id"].to_i
                                end
                    
                                @event.bands << @band
                                
                                if band["billing"] == "headline"
                                    headliners.push(@band.id)
                                else
                                    supporting_acts.push(@band.id)
                                end
                            end
                            
                            @event.update(headliners: headliners)
                            @event.update(supporting_acts: supporting_acts)
                        else
                            if (Venue.find_by songkick_id: event["venue"]["id"].to_i) == nil
                                venueCall = "http://api.songkick.com/api/3.0/venues/" + event["venue"]["id"].to_s + ".json?apikey=" + ENV["API_KEY"]
                    
                                venueCurl = Curl::Easy.new(venueCall) do |curl|
                        
                                end
                    
                                venueCurl.perform
                    
                                venueJSON = JSON.parse(venueCurl.body_str)
                    
                                venueJSON = venueJSON["resultsPage"]["results"]["venue"]
                    
                                @venue = Venue.new(
                                    songkick_id: venueJSON["id"].to_i,
                                    name: venueJSON["displayName"],
                                    city: venueJSON["city"]["displayName"],
                                    zip: venueJSON["zip"].to_i,
                                    latitude: venueJSON["lat"].to_f,
                                    longitude: venueJSON["lng"].to_f,
                                    street: venueJSON["street"],
                                    website: venueJSON["website"],
                                    description: venueJSON["description"]
                                )
                    
                                @venue.save
                            else
                                venueCall = "http://api.songkick.com/api/3.0/venues/" + event["venue"]["id"].to_s + ".json?apikey=" + ENV["API_KEY"]
                    
                                venueCurl = Curl::Easy.new(venueCall) do |curl|
                        
                                end
                    
                                venueCurl.perform
                    
                                venueJSON = JSON.parse(venueCurl.body_str)
                    
                                venueJSON = venueJSON["resultsPage"]["results"]["venue"]
                                
                                @venue = Venue.find_by songkick_id: event["venue"]["id"].to_i
                                @venue.update(
                                    name: venueJSON["displayName"],
                                    city: venueJSON["city"]["displayName"],
                                    zip: venueJSON["zip"].to_i,
                                    latitude: venueJSON["lat"].to_f,
                                    longitude: venueJSON["lng"].to_f,
                                    street: venueJSON["street"],
                                    website: venueJSON["website"],
                                    description: venueJSON["description"]
                                )
                            end
                            
                            @event = Event.find_by songkick_id: event["id"].to_i
                            
                            @event.update(
                                start: event["start"]["datetime"],
                                songkick_link: event["uri"]
                            )
                            
                            venue_has_event = false
                            @venue.events.each do |event|
                                if event.id == @event.id
                                    venue_has_event = true
                                    break
                                end
                            end
                            
                            if venue_has_event == false
                                @venue.events << @event
                            end
                            
                            bands = event["performance"]
                            headliners = []
                            supporting_acts = []
                            
                            bands.each do |band|
                                if (Band.find_by songkick_id: band["artist"]["id"].to_i) == nil
                                    @band = Band.new(
                                        songkick_id: band["artist"]["id"].to_i,
                                        name: band["artist"]["displayName"]
                                    )
                            
                                    @band.save
                                else
                                    @band = Band.find_by songkick_id: band["artist"]["id"].to_i
                                end
                                
                                event_has_band = false
                                @event.bands.each do |band|
                                    if @band.id == band.id
                                        event_has_band = true
                                        break
                                    end
                                end
                                
                                if event_has_band == false
                                    @event.bands << @band
                                end
                                
                                if band["billing"] == "headline"
                                    headliners.push(@band.id)
                                else
                                    supporting_acts.push(@band.id)
                                end
                            end
                            
                            @event.update(headliners: headliners)
                            @event.update(supporting_acts: supporting_acts)
                        end
                    end
                end
            end
        end
        
        puts "Events updated."
        
    end
end