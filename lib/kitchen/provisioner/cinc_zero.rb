# Deprecated - use CincInfra instead
require_relative "cinc_infra"

module Kitchen
  module Provisioner
    # Cinc Zero provisioner (deprecated, use CincInfra instead).
    #
    # This provisioner is maintained for backward compatibility and delegates
    # to CincInfra.
    #
    # @author Cinc Project
    class CincZero < CincInfra
      kitchen_provisioner_api_version 2

      plugin_version Kitchen::VERSION
    end
  end
end
