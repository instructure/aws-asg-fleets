module AWS
  class AutoScaling
    class FleetCollection

      include Core::Collection::Simple

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
        raise ArgumentError, "Fleet #{name} already exists" if self[name].exists?

        tags = template_group.tags
        if tags.map(&:key).any? {|k| k =~ /^asgfleet:/ }
          raise ArgumentError, "Group is already in a fleet"
        end

        template_group.update(:tags => [{
          :key => "asgfleet:#{name}",
          :value => "template",
          :propagate_at_launch => false
        }])

        self[name]
      end

      # @param [String] name The name of the ASG fleet.
      # @return [Fleet]
      def [] name
        Fleet.new(name, :config => config)
      end

      protected

      def _each_item options
        TagCollection.new(:config => config).filter(:value, "template").each do |tag|
          if tag[:key] =~ /^asgfleet:/
            name = tag[:key].split(':', 2)[1]
            yield Fleet.new(name, :config => config)
          end
        end
      end
    end
  end
end
