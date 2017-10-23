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

    class Group
      def fleet
        fleet_tag = tags.find {|t| t[:key] =~ /^asgfleet:/ }
        return nil unless fleet_tag

        fleet_name = fleet_tag[:key].split(':', 2)[1]
        Fleet.new(fleet_name, :config => config)
      end

      def set_fleet fleet, role = "member"
        if fleet && self.fleet
          raise ArgumentError, "Group already belongs to a fleet"
        end

        if fleet.nil?
          tags.find {|t| t[:key] =~ /^asgfleet:/ }.delete
        else
          self.update(:tags => [{
            :key => "asgfleet:#{fleet.is_a?(Fleet) ? fleet.name : fleet}",
            :value => role,
            :propagate_at_launch => false
          }])
        end
      end
    end
  end
end
