module Aws::AutoScaling
  class FleetCollection

    include Enumerable

    def initialize(opts)
      @resource = opts.delete(:resource)
    end

    # Create an ASG Fleet.
    #
    # To create a Fleet, you must supply an already-constructed
    # Auto Scaling group to be used as the template for new groups
    # added to the fleet.
    #
    #     fleet = auto_scaling.fleets.create('fleet-name',
    #         auto_scaling.groups['my-asg-group'])
    #
    # @param [String] name The name of the new fleet to create.
    #   Must be unique in your account.
    #
    # @param [Group] group The group to be used as a template
    #   for future groups and fleet changes.
    #
    # @return [Fleet]
    #
    def create name, template_group
      raise ArgumentError, "Fleet #{name} already exists" if @resource.fleet(name).exists?
      raise ArgumentError, "Group is already in a fleet" if template_group.fleet

      template_group.set_fleet(name, "template")
      @resource.fleet(name)
    end

    def each
      yielded_fleets = []

      @resource.tags.each do |tag|
        if tag.key =~ /^asgfleet:/
          name = tag.key.split(':', 2)[1]

          next if yielded_fleets.include? name
          yielded_fleets << name

          yield @resource.fleet(name)
        end
      end
    end
  end
end
