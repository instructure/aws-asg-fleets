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

      # Create a group within a Fleet.
      #
      # To create a group you supply a name, and any desired Auto
      # Scaling group options. Any options not specified will be pulled
      # from the template group for the fleet. Scaling policies and
      # alarms will also be created for the new Group, based on those
      # associated with the template.
      #
      # @param [String] name The name of the new group to create in the
      #   fleet. Must be unique in your account.
      #
      # @param [Hash] options
      #
      # @option (see GroupOptions#group_options)
      #
      # @return [Group]
      def create name, options = {}
        ## Clone the group
        template_group = @fleet.template_group

        options = Fleet.options_from(template_group,
          :load_balancers, :min_size, :max_size, :launch_configuration,
          :availability_zones, :default_cooldown, :desired_capacity,
          :health_check_grace_period, :health_check_type, :placement_group,
          :termination_policies, :subnets).merge(options)

        # merge together tags from options and the template
        new_tags = template_group.tags.to_a.map do |t|
          {
            :key => t[:key],
            :value => t[:value],
            :propagate_at_launch => t[:propagate_at_launch]
          }
        end
        if options[:tags]
          options[:tags].each do |tag|
            existing_tag = new_tags.find {|t| t[:key] == tag[:key] }
            if existing_tag
              existing_tag.merge! tag
            else
              new_tags << tag
            end
          end
        end
        # change the fleet tag value from "template" to "member"
        fleet_tag = new_tags.find {|t| t[:key] == "asgfleet:#{@fleet.name}" }
        fleet_tag[:value] = "member"
        options[:tags] = new_tags

        group = GroupCollection.new(:config => config).create name, options

        # Match metric collection with the template
        # (If this call ever supports specifying a granularity of other than
        # '1Minute', this will need to change.)
        group.enable_metrics_collection(template_group.enabled_metrics.keys)

        ## Clone the scaling policies and alarms from the group
        cloudwatch = AWS::CloudWatch.new(:config => config)
        template_group.scaling_policies.each do |template_policy|
          policy_options = Fleet.options_from(template_policy,
            :adjustment_type, :scaling_adjustment, :cooldown, :min_adjustment_step)

          policy = group.scaling_policies.create template_policy.name, policy_options

          template_policy.alarms.keys.each do |template_alarm_name|
            template_alarm = cloudwatch.alarms[template_alarm_name]
            alarm_name = "#{template_alarm.name}-#{group.name}"
            alarm_options = Fleet.options_from(template_alarm,
              :namespace, :metric_name, :comparison_operator, :evaluation_periods,
              :period, :statistic, :threshold, :actions_enabled, :alarm_description,
              :unit)

            # For dimensions, copy them all except for the one
            # referencing the ASG - replace that with the right group.
            alarm_options[:dimensions] = template_alarm.dimensions.map do |dimension|
              if dimension[:name] == "AutoScalingGroupName"
                { :name => "AutoScalingGroupName", :value => group.name }
              else
                dimension
              end
            end

            # For actions, we want to go through them all, replacing any
            # ARNs referencing the template_policy with ones pointing to
            # our new policy. For ARNs we don't recognize, we just copy
            # them, assuming the user wants those ARNs to continue to
            # fire.
            [ :insufficient_data_actions, :ok_actions, :alarm_actions ].each do |key|
              new_actions = template_alarm.send(key).map do |arn|
                if arn == template_policy.arn
                  policy.arn
                else
                  arn
                end
              end

              unless new_actions.empty?
                alarm_options[key] = new_actions
              end
            end

            cloudwatch.alarms.create alarm_name, alarm_options
          end
        end

        group
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
