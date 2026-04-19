# Compatibility alias - delegates to CincApply
require_relative "cinc_apply"

module Kitchen
  module Provisioner
    ChefApply = CincApply
  end
end
