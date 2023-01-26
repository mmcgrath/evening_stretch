# frozen_string_literal: false

require 'sun_times'
require 'mastodon'
require 'active_support/core_ext/time/zones'
require 'active_support/core_ext/integer/inflections'
require 'httparty'
require 'tod' # time of day

masto_server = ENV['MASTO_SERVER'] || '' # You need to fill this in, for example 'https://universeodon.com'
masto_token = ENV['MASTO_TOKEN'] || '' # On Masto server, go to Settings-->Applications to create an app & get a token
google_api_key = ENV['GOOGLE_API_KEY'] || ''
address = '375 E Horsetooth Rd, Fort Collins CO 80525'

geocode_url = 'https://maps.googleapis.com/maps/api/geocode/json?'
geocode_url << "address=#{CGI.escape address}"
geocode_url << "&key=#{google_api_key}"
data = JSON.parse(HTTParty.get(geocode_url).body)

@lat = data['results'].first['geometry']['location']['lat']
@lng = data['results'].first['geometry']['location']['lng']

timezone_url = 'https://maps.googleapis.com/maps/api/timezone/json?'
timezone_url << "location=#{@lat}%2C#{@lng}"
timezone_url << "&timestamp=#{Time.now.to_i}"
timezone_url << "&key=#{google_api_key}"
data = JSON.parse(HTTParty.get(timezone_url).body)

Time.zone = ActiveSupport::TimeZone.find_tzinfo data['timeZoneId']

def seconds_between(time1, time2) # rubocop:disable Metrics/AbcSize
  times = [time1.utc, time2.utc].sort
  rv = 0

  # have we crossed a day boundary?
  rv += (24 * 60 * 60) if times[1].hour < times[0].hour

  rv += (times[1].hour - times[0].hour) * (60 * 60)
  rv += (times[1].min - times[0].min) * 60
  rv += (times[1].sec - times[0].sec)
  rv.to_i
end

def earliest_sunset_time
  rv = @sun_times.set(@today_noon, @lat, @lng)
  (1..365).each do |day_adjust|
    sunset_time = @sun_times.set(@today_noon - (day_adjust * 24 * 60 * 60), @lat, @lng)
    rv = sunset_time if Tod::TimeOfDay(sunset_time.localtime) < Tod::TimeOfDay(rv.localtime)
  end
  rv
end

@today_noon = Time.zone.parse('12:00:00')
yesterday_noon = @today_noon - (24 * 60 * 60)
@sun_times = SunTimes.new

today_friendly = [@today_noon.day.ordinalize, @today_noon.strftime('%B')].join(' ')

diff = seconds_between(@sun_times.set(yesterday_noon, @lat, @lng), @sun_times.set(@today_noon, @lat, @lng))
earliest_diff_secs = seconds_between(earliest_sunset_time, @sun_times.set(@today_noon, @lat, @lng))
diff_mins, diff_secs = earliest_diff_secs.divmod 60
diff_secs = diff_secs.to_i
words = %w[glorious delicious beautiful magnificent]
sunset_local = @sun_times.set(@today_noon, @lat, @lng).localtime
sunset_local_text = sunset_local.strftime('%l:%M%P %Z').lstrip
text = "Today's sunset (#{today_friendly}) will be #{diff.abs.round} seconds "
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

client = Mastodon::REST::Client.new(base_url: masto_server, bearer_token: masto_token)
if masto_server.empty?
  puts text
else
  client.create_status(text.dup, { 'visibility': 'public' })
end
