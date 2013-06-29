require 'aws/auto_scaling'
require 'aws/version'

module AWS
  class AutoScaling

    autoload :Fleet, 'aws/auto_scaling/fleet'
    autoload :FleetCollection, 'aws/auto_scaling/fleet_collection'
    autoload :FleetGroupCollection, 'aws/auto_scaling/fleet_group_collection'

    # @return [FleetCollection]
    def fleets
      FleetCollection.new(:config => config)
    end

    # stupid hack to get an attribute added to Group. It'll be fixed in
    # 1.11.4, so remove this and set 1.11.4 as the required version when
    # released.
    if AWS::VERSION == '1.11.3'
      require 'aws/auto_scaling/group'
      class Group; attribute :termination_policies; end
    end
  end
end
