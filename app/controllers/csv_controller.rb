class CsvController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def upload
    file = params[:file]
    if file.nil?
      render :nothing => true, :status => 204
    elsif file.class != ActionDispatch::Http::UploadedFile
      render :nothing => true, :status => 400
    else
      matrix = Utils::Algorithm::csv_to_matrix(file.read)

      render :text => get_missing_value(matrix).map { |x| "#{x[:date].to_s},#{x[:val].to_s}\n" }.join(''), :status => 200
    end
  end

  def uploadbonus
    file = params[:file]
    if file.nil?
      render :nothing => true, :status => 204
    elsif file.class != ActionDispatch::Http::UploadedFile
      render :nothing => true, :status => 400
    else
      matrix = Utils::Algorithm::csv_to_matrix(file.read)

      render :text => get_missing_value(matrix).map { |x| "#{x[:date].to_s},#{x[:in0].to_s},#{x[:in1].to_s}\n" }.join(''), :status => 200
    end
  end

  def local
    file = File.open('sample_input.csv')
    matrix = (Utils::Algorithm::csv_to_matrix(file.read))
    render :text => get_missing_value(matrix).map { |x| x[:val] }.join('<br/>'), :status => 200
  end


  def get_missing_value(csv)
    #Remove all existing prediction
    vals = []
    array = []

    prev_interval = 1
    (0...csv.row_size).each do |i|
      row = csv.row(i).to_a
      array << row
      last = array.size-1

      if csv.row(i)[Utils::Csv::CONSUMPTION] == 0.0
        tmp = nil
        #Forget temporaly the data
        if array[last][Utils::Csv::RADIATION] != 0.0
          tmp = array[last].clone
          array[last][Utils::Csv::RADIATION] = 0.0
          array[last][Utils::Csv::HUMIDITY] = 0.0
          array[last][Utils::Csv::TEMPERATURE] = 0.0
          array[last][Utils::Csv::WINDSPEED] = 0.0
        end
        val = Utils::Algorithm.forcast_next_value(Matrix.rows(array), last)
        array[last][Utils::Csv::CONSUMPTION] = val[:val]
        #Replace the data
        unless tmp.nil?
          array[last][Utils::Csv::RADIATION] = tmp[Utils::Csv::RADIATION]
          array[last][Utils::Csv::HUMIDITY] = tmp[Utils::Csv::HUMIDITY]
          array[last][Utils::Csv::TEMPERATURE] = tmp[Utils::Csv::TEMPERATURE]
          array[last][Utils::Csv::WINDSPEED] = tmp[Utils::Csv::WINDSPEED]
        end
        result_interval= []
        prev_interval = prev_interval * (1 -(val[:val]-val[:interval][0]).abs/val[:val])
        result_interval[0] = val[:val] - ((1-prev_interval) *val[:val])
        result_interval[1] = val[:val] + ((1-prev_interval) *val[:val])



        vals << {:date => array[last][Utils::Csv::DATE].to_s, :val => val[:val].to_s, :in0 => result_interval[0].to_s, :in1 => result_interval[1].to_s}
      end
    end
    vals
  end

end
