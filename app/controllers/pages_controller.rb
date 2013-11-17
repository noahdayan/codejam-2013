require 'time'
require 'net/https'
require 'uri'

class PagesController < ApplicationController
  def index
    t = Time.new
    @time = t-t.sec-t.min%15*60 + (15*60)
    @power = 20000
    @points = 128
  end

  def pulseapi(attr,time)
    key = '60777831C1AA2C232B6D4E796B4C3650'
    loc = 'https://api.pulseenergy.com/pulse/1/points/' + attr + '/data.json?key=' + key + '&interval=day&start=' + (time.iso8601)[0..-7]
    puts loc
    uri = URI.parse(loc)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(uri.request_uri)

    response = http.request(request)
    response.body
  end

  def pulse
    attr = params[:attr]
    time = params[:time]
    time = DateTime.new(2011,11,11,00,00,000)
    render :text => pulseapi(attr,time)
  end

  def empty
    Point.delete_all
    acc = []
    CSV.foreach('data_set.csv') do |row|
      m = []
      next if row[0] == 'Date'
      m[Utils::Csv::DATE] = DateTime.parse(row[0])
      m[Utils::Csv::RADIATION] = row[1].to_f
      m[Utils::Csv::HUMIDITY] = row[2].to_f
      m[Utils::Csv::TEMPERATURE] = row[3].to_f
      m[Utils::Csv::WINDSPEED] = row[4].to_f
      m[Utils::Csv::TIME] = Utils::Algorithm::time_to_f(Time.parse(row[0]))
      m[Utils::Csv::CONSUMPTION] = row[5].to_f
      acc << m
    end
    full_csv = Utils::Algorithm::fill_missing_values(Matrix.rows(acc))
    #delta_c = 0
    #(Utils::Constant::N+548...full_csv.row_size).each do |index|
    #  csv = Utils::Algorithm::get_last_n_rows(full_csv, index)
    #  begin
    #  curve = Utils::Algorithm::get_curve(csv, full_csv.row(index)[Utils::Csv::CONSUMPTION])
    #  puts index.to_s  + ' - ' + curve.value.to_s
    #  if curve.delta <= Utils::Constant::MAX_DELTA
    #  curve.save
    #  else
    #    puts 'To big delta'
    #    delta_c += 1
    #  end
    #
    #  rescue ExceptionForMatrix::ErrNotRegular => error
    #    puts '===================error '
    #  end
    #end


    (0...full_csv.row_size-80).each do |row|
      Point::from_row(full_csv.row(row)).save
    end

  end
end
