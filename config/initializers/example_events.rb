# frozen_string_literal: true

# Events emitted by the host app itself. The engines emit their own
# canonical events; the host's flows emit *.example events for things
# that don't belong inside any single engine — cross-engine
# orchestration, dashboards, audit overlays, host-defined lifecycles.
#
# This file shows the full register / subscribe / publish loop:
#
#   1. Register at boot so `bin/rails seams:list` displays the event.
#   2. Attach a subscriber so listeners survive code reloads
#      (Publisher.attach_once is reload-safe — the block re-resolves
#      every dispatch, so editing the subscriber doesn't need a
#      server restart).
#   3. Publish from anywhere — controllers, services, jobs — with
#      `Seams::Events::Publisher.publish("user.onboarded.example",
#      user_id: user.id, ...)`. db/seeds.rb does exactly that to
#      let you watch the bus fire on a fresh checkout.
Rails.application.config.after_initialize do
  Seams::EventRegistry.register("user.onboarded.example", emitted_by: "Host")

  Seams::Events::Publisher.attach_once(
    :host_user_onboarded_logger,
    "user.onboarded.example"
  ) do |payload|
    Rails.logger.info("[example] user.onboarded.example payload=#{payload.inspect}")
  end
end
