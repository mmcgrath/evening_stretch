require 'sun_times'
require 'mastodon'

base_url = '' # You need to fill this in, for example 'https://universeodon.com'
bearer_token = '' # You need to fill this in: go to Settings-->Applications to create an app and get a token

date = Date.today
# Fort Collins
lat=40.5064889
lng=-105.0186591

sun_times = SunTimes.new

today_sunset = sun_times.set(date, lat, lng)
diff = today_sunset - sun_times.set(date-1, lat, lng) - (24 *3600)

sunset_local = today_sunset - (7 * 3600) # a nicer solution would be to include Rails ActiveSupport and do this properly. I'll likely have to manually change this when the clocks go forward
sunset_local_text = sunset_local.strftime('%l:%M%P').lstrip
text = "Today's sunset will be #{diff.abs.round} seconds "
text << (diff<0 ? "earlier" : "later")
text << " than yesterday's and will occur at #{sunset_local_text}\n\#FortCollins. Hat-tip to @theauldsthretch@mastodon.ie"

client = Mastodon::REST::Client.new(base_url: base_url, bearer_token: bearer_token)
r = client.create_status(text)
