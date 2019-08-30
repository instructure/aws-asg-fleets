module Aws::AutoScaling
  class Fleet

    def initialize name, options
      @name = name
      @client = options.delete(:client)
    end

    # @return [String]
    attr_reader :name

    def tags(filters=[])
      # mostly copied from Resource#tags
      options = {:filters => [{:name => "key", :values => [tag_name]}] + filters}
      batches = Enumerator.new do |y|
        resp = @client.describe_tags(options)
        resp.each_page do |page|
          batch = []
          page.data.tags.each do |t|
            batch << Tag.new(
              key: t.key,
              resource_id: t.resource_id,
              resource_type: t.resource_type,
              data: t,
              client: @client
            )
          end
          y.yield(batch)
        end
      end
      Tag::Collection.new(batches)
    end

    def group_for_tag(tag)
      return nil unless tag
      case tag.resource_type
      when 'auto-scaling-group'
        AutoScalingGroup.new(name: tag.resource_id, client: @client)
      else
        msg = "unhandled resource type: #{tag.resource_type}" # shamelessly copied from old aws-sdk
        raise ArgumentError, msg
      end
    end

    def tag_name
      "asgfleet:#{name}"
    end

    # @return [Group]
    def template_group
      tag = tags([{:name => 'value', :values => ["template"]}]).first
      group_for_tag(tag)
    end

    # @return [Group]
    def any_group
      group_for_tag(tags.first)
    end

    def template_or_any_group
      template_group || any_group
    end

    def exists?
      !any_group.nil?
    end

    def groups
      FleetGroupCollection.new(self)
    end

    # Suspends all scaling processes in all Auto Scaling groups in the
    # fleet.
    def suspend_all_processes
      groups.each do |group|
        group.suspend_processes
      end
    end

    # Resumes all scaling processes in all Auto Scaling groups in the
    # fleet.
    def resume_all_processes
      groups.each do |group|
        group.resume_processes
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
      old_lc = template_or_any_group.launch_configuration
      options = Fleet.options_from(old_lc,
        :image_id, :instance_type,
        :block_device_mappings, :instance_monitoring, :kernel_id,
        :key_name, :ramdisk_id, :security_groups, :user_data,
        :iam_instance_profile, :spot_price).merge(options)

      options[:launch_configuration_name] = name
      @client.create_launch_configuration(options)

      groups.each do |group|
        next unless group.launch_template.nil?
        next unless group.mixed_instances_policy.nil?

        group.update(:launch_configuration_name => name)
      end

      LaunchConfiguration.new(name: name, client: @client)
    end

    # @private
    # Collects non-nil, non-empty-array attributes from the supplied object
    # into a Hash. Also converts any Array-like objects into real
    # Arrays.
    def self.options_from(obj, *attributes)
      opts = {}
      attributes.each do |key|
        value = obj.send(key)
        next if value.blank?
        if value.is_a? Array
          value = value.to_a
          next if value.empty?
        end
        opts[key] ||= value
      end
      opts
    end

    protected

    def resource_identifiers
      [[:name, name]]
    end
  end
end
