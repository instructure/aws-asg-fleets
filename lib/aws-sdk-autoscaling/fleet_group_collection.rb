module Aws::AutoScaling
  class FleetGroupCollection
    include Enumerable

    def initialize fleet
      @fleet = fleet
    end

    # @return [Fleet]
    attr_reader :fleet

    # Add an existing group to a Fleet.
    #
    # @param [Group] The group to add.
    def << group
      group.set_fleet @fleet.name
    end

    def each
      @fleet.tags.each do |t|
        yield @fleet.group_for_tag(t)
      end
    end
  end
end
