module AWS
  class AutoScaling
    class Fleet < Core::Resource

      def initialize name, options = {}
        @name = name
        super
      end

      # @return [String]
      attr_reader :name

      # @return [Group]
      def template_group
        tag = TagCollection.new(:config => config)
          .filter(:key, "asgfleet:#{name}")
          .filter(:value, "template")
          .first
        return nil unless tag
        tag.resource
      end

      def exists?
        !template_group.nil?
      end

      def groups
        FleetGroupCollection.new(self)
      end
      
      # Suspends all scaling processes in all Auto Scaling groups in the
      # fleet.
      def suspend_all_processes
        groups.each do |group|
          group.suspend_all_processes
        end
      end

      # Resumes all scaling processes in all Auto Scaling groups in the
      # fleet.
      def resume_all_processes
        groups.each do |group|
          group.resume_all_processes
        end
      end

      # Creates a new launch configuration and applies it to all the
      # Auto Scaling groups in the fleet. Any options not specified will
      # be pulled from the Launch Configuration currently attached to
      # the template Auto Scaling group.
      #
      # @param [String] name The name of the new launch configuration
      #
      # @param [Hash] options Options for the new launch configuration.
      #   Any options not specified in this hash will be pulled from the
      #   existing launch configuration on the template scaling group.
      #
      def update_launch_configuration name, options = {}
        old_lc = template_group.launch_configuration
        image_id = options[:image_id] || old_lc.image_id
        instance_type = options[:instance_type] || old_lc.instance_type
        [ :block_device_mappings, :detailed_instance_monitoring, :kernel_id,
          :key_pair, :ramdisk_id, :security_groups, :user_data,
          :iam_instance_profile, :spot_price ].each do |k|
          existing_value = old_lc.send(k)
          next if existing_value == nil || existing_value == []
          options[k] ||= existing_value
        end

        launch_configurations = LaunchConfigurationCollection.new(:config => config)
        puts options
        new_lc = launch_configurations.create(name, image_id, instance_type, options)

        groups.each do |group|
          group.update(:launch_configuration => new_lc)
        end

        new_lc
      end

      protected

      def resource_identifiers
        [[:name, name]]
      end
    end
  end
end
