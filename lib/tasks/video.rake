namespace :bands do
    task :video => :environment do
        require 'uri'
        
        iterator = 1
        34.times do |n|
            20.times do |i|
                if Band.find(i + iterator).songkick_id != nil
                    videoCall = "http://developer.echonest.com/api/v4/artist/video?api_key=" + ENV["ECHO_API_KEY"] + '&id=songkick:artist:' + Band.find(i + iterator).songkick_id.to_s + '&format=json'

                    echo_video = Curl::Easy.new(videoCall) do |curl| end

                    echo_video.perform

                    echo_video_info = JSON.parse(echo_video.body_str)
            
                    if echo_video_info["response"]["status"]["code"] == 0
                        if echo_video_info["response"]["video"][0] != nil
                            echo_video_info["response"]["video"].each do |video|
                                if video["site"] = "youtube.com"
                                    url = video["url"]
                                    youtube_id = url[/(?<=[?&]v=)[^&$]+/].to_s
                                    
                                    Band.find(i + iterator).update(youtube_id: youtube_id)
                                    break
                                end
                            end
                        end
                    end
                end
            end
            iterator = iterator + 20
            sleep(60)
        end
        
    end
end