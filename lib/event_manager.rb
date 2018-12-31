require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

file_small = "event_attendees.csv"
file_full = "event_attendees_full.csv"

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, "0")[0..4]
end

def clean_phone_numbers(phone)
  phone.gsub!(/\D+/, '')
  return "Invalid phone number" if phone.length < 10 || (phone.length == 11 && phone[0] != "1")
  phone.slice!(0) if phone[0] == "1"
end

def calculate_best_ad_time(file_full)
  hash = find_best_date_and_time(file_full)
  best_time, best_day = ""
  day_count = 0
  time_count = 0
  hash.each do |key, value|
    if key.to_s =~ (/\d+/)
      if value[0] > time_count
        best_time = key.to_s
        time_count = value[0]
      end
    elsif key.to_s =~ (/\w+/)
      if value[0] > day_count
      best_day = key.to_s
      day_count = value[0]
      end
    end  
  end
  print_best_ad_times(best_time, best_day)
end

def print_best_ad_times(best_time, best_day)
  File.open("output/best_ad_times.txt", "w") do |file|
    file.puts "The best day for advertising is #{best_day}, "\
      "while the best time is around #{best_time}:00."
  end
end

def find_best_date_and_time(file_full)
  contents = CSV.open(file_full, headers: true, header_converters: :symbol)
  hsh = {}
  contents.each do |row|
    date_and_time = row[:regdate]
    day = convert_wday_to_english(Date.strptime(date_and_time, "%m/%d/%Y").wday.to_s)
    time = DateTime.strptime(date_and_time, "%m/%d/%Y %H:%M").hour
    hsh[day] ||= [0]
    hsh[day][0] += 1
    hsh[time] ||= [0]
    hsh[time][0] += 1
    hsh
  end
hsh
end

def convert_wday_to_english(day)
  days = {sunday: "0",
          monday: "1",
          tuesday: "2",
          wednesday: "3",
          thursday: "4",
          friday: "5",
          saturday: "6"
  }
  return days.key(day).to_s.capitalize!
end

def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir("output") unless Dir.exists? "output"
  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts "EventManager Initialized"

contents = CSV.open(file_full, headers: true, header_converters: :symbol)

template_letter = File.read("form_letter.erb")
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  reg_date = row[:regdate]
  phone = row[:homephone]
  
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  phone_number = clean_phone_numbers(phone)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)  
end

calculate_best_ad_time(file_full)