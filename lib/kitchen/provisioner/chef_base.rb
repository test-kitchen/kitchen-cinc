# Compatibility alias - delegates to CincBase
require_relative "cinc_base"

module Kitchen
  module Provisioner
    ChefBase = CincBase
  end
end
