require 'aws-sdk-autoscaling'

module Aws::AutoScaling
  autoload :Fleet, 'aws-sdk-autoscaling/fleet'
  autoload :FleetCollection, 'aws-sdk-autoscaling/fleet_collection'
  autoload :FleetGroupCollection, 'aws-sdk-autoscaling/fleet_group_collection'

  module ResourceFleetsExtension
    # @return [FleetCollection]
    def fleet(name)
      Fleet.new(name, client: @client)
    end

    def fleets
      FleetCollection.new(resource: self)
    end
  end
  Resource.include(ResourceFleetsExtension)

  module AutoScalingGroupFletsExtension
    def fleet
      fleet_tag = tags.find {|t| t.key =~ /^asgfleet:/ }
      return nil unless fleet_tag

      fleet_name = fleet_tag.key.split(':', 2)[1]
      Fleet.new(fleet_name, client: @client)
    end

    def set_fleet fleet, role = "member"
      if fleet && self.fleet
        raise ArgumentError, "Group already belongs to a fleet"
      end

      if fleet.nil?
        tags.find {|t| t.key =~ /^asgfleet:/ }.delete
      else
        @client.create_or_update_tags(:tags => [{
          :resource_type => "auto-scaling-group",
          :resource_id => name,
          :key => "asgfleet:#{fleet.is_a?(Fleet) ? fleet.name : fleet}",
          :value => role,
          :propagate_at_launch => false
        }])
      end
    end
  end
  AutoScalingGroup.include(AutoScalingGroupFletsExtension)
end
