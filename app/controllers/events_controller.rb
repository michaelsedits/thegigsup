class EventsController < ApplicationController
    before_action :set_event, only: [:show, :edit, :update, :destroy]
    
    def gigs
        
    end

    # GET /events
    # GET /events.json
    def index
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
        end
        
        eventsObjects = []
        
        pages.times do |i|
            eventsCall = eventsCall + '&page=' + i.to_s
            events = Curl::Easy.new(eventsCall) do |curl|
            
            end
            
            events.perform
            
            eventsObjects << JSON.parse(events.body_str)["resultsPage"]["results"]["event"]
        end
        
        eventsObjects.each do |eventObject|
            eventObject.each do |event|
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
                            street: venueJSON["street"]
                        )
                    
                        @venue.save
                    else
                        @venue = Venue.find_by songkick_id: event["venue"]["id"].to_i
                    end
                
                    @event = Event.new(
                        songkick_id: event["id"].to_i,
                        start: event["start"]["datetime"]
                    )
                
                    @event.save
                
                    @venue.events << @event
                
                    bands = event["performance"]
                
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
                    end
                end
            end
        end
        
        if params[:month] && params[:year]
            dateString = params[:month] + ' ' + params[:year]
            @month = Time.parse(dateString)
            
            events = Event.where("start >= ? AND start <= ?", @month.beginning_of_month, Time.parse(dateString).end_of_month).order(:start)
        else
            @month = Time.now
            events = Event.where("start >= ? AND start <= ?", @month, Time.now.end_of_month).order(:start)
        end
        
        @dates = []
    
        events.each do |event|
            unless @dates.include? event.start.beginning_of_day
                @dates << event.start.beginning_of_day
            end
        end
    end

    # GET /events/1
    # GET /events/1.json
    def show
    end

    # GET /events/new
    def new
        @event = Event.new
    end

    # GET /events/1/edit
    def edit
    end

    # POST /events
    # POST /events.json
    def create
        @event = Event.new(event_params)
        
        @venue = Venue.find(params[:event][:venue_id])
        @bands = []
        
        respond_to do |format|
            if @event.save
                @event.start = params[:event][:start]
                @venue.events << @event
                params[:event][:band_ids].each_with_index do |id, index|
                    if index != 0
                        @event.bands << Band.find(id)
                    end
                end
                format.html { redirect_to events_url, notice: 'Event was successfully created.' }
                format.json { render :show, status: :created, location: @event }
            else
                format.html { render :new }
                format.json { render json: @event.errors, status: :unprocessable_entity }
            end
        end
    end

    # PATCH/PUT /events/1
    # PATCH/PUT /events/1.json
    def update
        respond_to do |format|
            if @event.update(event_params)
                format.html { redirect_to events_url, notice: 'Event was successfully updated.' }
                format.json { render :show, status: :ok, location: @event }
            else
                format.html { render :edit }
                format.json { render json: @event.errors, status: :unprocessable_entity }
            end
        end
    end

    # DELETE /events/1
    # DELETE /events/1.json
    def destroy
        @event.destroy
        respond_to do |format|
            format.html { redirect_to events_url, notice: 'Event was successfully destroyed.' }
            format.json { head :no_content }
        end
    end

    private
    # Use callbacks to share common setup or constraints between actions.
    def set_event
        @event = Event.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def event_params
        params.require(:event).permit(:facebook_id)
    end
end
