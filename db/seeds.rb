# frozen_string_literal: true

# This file is the demo: run `bin/rails db:seed` and you'll watch
# the seams event bus fire end-to-end. It creates a User, publishes
# the host's `user.onboarded.example` event (the subscriber wired in
# config/initializers/example_events.rb logs the payload), and uses
# Notifications::Notifiable to deliver an in-app notification.
#
# Re-run safe: `find_or_create_by!` keeps a single demo user across
# repeated `db:seed` invocations.

email = "demo+seams@example.com"
puts "[seed] Creating User with email=#{email}..."
user = User.find_or_create_by!(email: email)

puts "[seed] Publishing user.onboarded.example..."
Seams::Events::Publisher.publish(
  "user.onboarded.example",
  user_id: user.id,
  email:   user.email,
  source:  "db:seed"
)

puts "[seed] Registering 'default' notification type + delivering in_app notification..."
Notifications::TypeRegistry.register("default",
                                     template: "default", channels: %i[in_app])
notification = user.notify(strategy: :in_app, template: "default")

puts "[seed] Notification id=#{notification.id} owner=#{notification.owner_type}##{notification.owner_id}"
puts "[seed] User now has #{user.unread_in_app_notifications.count} unread in_app notification(s)."
puts "[seed] Done. Tail log/development.log to see the event subscriber's [example] line."
