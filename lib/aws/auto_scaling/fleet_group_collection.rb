module AWS
  class AutoScaling
    class FleetGroupCollection

      include Core::Collection::Simple

      def initialize fleet, options = {}
        @fleet = fleet
        super
      end

      # @return [Fleet]
      attr_reader :fleet

      # Add an existing group to a Fleet.
      #
      # @param [Group] The group to add.
      def << group
        group.set_fleet @fleet.name
      end
    end
  end
end
