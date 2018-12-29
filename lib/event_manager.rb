puts "EventManager Initialized"
file_small = "event_attendees.csv"
file_full = "event_attendees_full.csv"

contents = File.open(file_small, "r") if File.exist?(file_small)
puts contents



sleep(1) # REMOVE after finish
