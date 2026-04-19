# Compatibility alias - delegates to CincSolo
require_relative "cinc_solo"

module Kitchen
  module Provisioner
    ChefSolo = CincSolo
  end
end
