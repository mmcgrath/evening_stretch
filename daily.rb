# frozen_string_literal: true

require 'sun_times'
require 'mastodon'

masto_server = '' # You need to fill this in, for example 'https://universeodon.com'
token = '' # On your Masto server, go to Settings-->Applications to create an app and get a token

# Fort Collins, Colo.
lat = 40.5365583
lng = -105.0722078

date = Date.today
sun_times = SunTimes.new

today_sunset = sun_times.set(date, lat, lng)
earliest_sunset = sun_times.set(Date.parse('7 Dec 2022'), lat, lng)
diff = today_sunset - sun_times.set(date - 1, lat, lng) - (24 * 3600)
earliest_diff_secs = (today_sunset - earliest_sunset) % (24 * 3600)
diff_mins, diff_secs = earliest_diff_secs.divmod 60
diff_secs = diff_secs.to_i
words = %w[glorious delicious beautiful magnificent]
sunset_local = today_sunset - (7 * 3600)
sunset_local_text = sunset_local.strftime('%l:%M%P').lstrip
text = "Today's sunset will be #{diff.abs.round} seconds "
text << (diff.negative? ? 'earlier' : 'later')
text << " than yesterday's and will occur at #{sunset_local_text}\n\#FortCollins. "
text << "This is a #{words.sample} #{diff_mins} minutes"
if diff_secs > 1
  text << " and #{diff_secs} seconds"
elsif diff_secs == 1
  text << " and #{diff_secs} second"
end
text << ' more than the earliest sunset. '
text << 'Hat-tip to @theauldsthretch@mastodon.ie'

puts text

client = Mastodon::REST::Client.new(base_url: masto_server, bearer_token: token)
client.create_status(text.dup, { 'visibility': 'public' }) unless masto_server.empty?
