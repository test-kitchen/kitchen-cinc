# Compatibility alias - delegates to CincZero
require_relative "cinc_zero"

module Kitchen
  module Provisioner
    ChefZero = CincZero
  end
end
