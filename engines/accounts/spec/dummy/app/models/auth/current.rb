# frozen_string_literal: true
# Slim Auth::Current stub for the accounts dummy app. Stands in
# for the real Auth::Current (which lives in the auth engine,
# not loaded by the dummy) so accounts specs can wire
# `Current.identity = identity` against the same surface area
# the canonical seams host uses.
module Auth
  class Current < ActiveSupport::CurrentAttributes
    attribute :identity
  end
end
