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

      protected

      def _each_item options
        TagCollection.new(:config => config).filter(:key, "asgfleet:#{@fleet.name}").each do |tag|
          yield tag.resource
        end
      end
    end
  end
end
