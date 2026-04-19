# Compatibility alias - delegates to CincTarget
require_relative "cinc_target"

module Kitchen
  module Provisioner
    ChefTarget = CincTarget
  end
end
