# Compatibility alias - delegates to CincInfra
require_relative "cinc_infra"

module Kitchen
  module Provisioner
    ChefInfra = CincInfra
  end
end
