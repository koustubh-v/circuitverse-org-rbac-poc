koustubh = User.create!(name: "Koustubh", email: "koustubh@admin.com")
Vedant   = User.create!(name: "Vedant",   email: "vedant@admin.com")
Pratham  = User.create!(name: "Pratham",  email: "pratham@admin.com")

puts "Seeded users:"
puts "  Koustubh (id: #{koustubh.id})"
puts "  Vedant   (id: #{Vedant.id})"
puts "  Pratham  (id: #{Pratham.id})"