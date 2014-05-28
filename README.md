# AWS Auto Scaling Fleet

Helps manage several Auto-Scaling Groups that share common
configuration.

## Installation

Add this line to your application's Gemfile:

    gem 'aws-asg-fleet'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install aws-asg-fleet

## Usage

Initialize:

```ruby
require 'aws/auto_scaling/fleets'

auto_scaling = AWS::AutoScaling.new(
  :access_key_id => 'YOUR_ACCESS_KEY_ID',
  :secret_access_key => 'YOUR_SECRET_ACCESS_KEY')
```

First create an Auto Scaling group (with a Launch Configuration, Scaling
Policy, and an Alarm to trigger the Policy.) This ASG (and related
objects) will act as a template for future additions to the fleet:

```ruby
launch_config = auto_scaling.launch_configurations.create(
  'my-launch-config',
  'ami-123456',
  't1.micro')

group = auto_scaling.groups.create('my-group',
  :launch_configuration => launch_config,
  :availability_zones => [ 'us-east-1a' ],
  :min_size => 1,
  :max_size => 4,
  :load_balancers => [ 'my-main-elb' ])

up_policy = group.scaling_policies.create('my-scaleup-policy',
  :adjustment_type => 'ChangeInCapacity',
  :scaling_adjustment => 1)

down_policy => group.scaling_policies.create('my-scaledown-policy',
  :adjustment_type => 'ChangeInCapacity',
  :scaling_adjustment => -1)

cloudwatch = AWS::CloudWatch.new
up_alarm = cloudwatch.alarms.create('cpu-high-alarm',
  :namespace => "AWS/EC2",
  :metric_name => "CPUUtilization",
  :dimensions => [{
    :name => "AutoScalingGroupName",
    :value => group.name
  }],
  :comparison_operator => "GreaterThanOrEqualToThreshold",
  :evaluation_periods => 2,
  :period => 120,
  :statistic => "Average",
  :threshold => 80,
  :alarm_actions => [ up_policy.arn ])

down_alarm = cloudwatch.alarms.create('cpu-low-alarm',
  :namespace => "AWS/EC2",
  :metric_name => "CPUUtilization",
  :dimensions => [{
    :name => "AutoScalingGroupName",
    :value => group.name
  }],
  :comparison_operator => "LessThanOrEqualToThreshold",
  :evaluation_periods => 2,
  :period => 300,
  :statistic => "Average",
  :threshold => 40,
  :alarm_actions => [ down_policy.arn ])
```

Phew - that was a lot of stuff. But we now have a configured Auto
Scaling group we can use in our fleet.

Create the fleet:

```ruby
fleet = auto_scaling.fleets.create('my-fleet', group)
```

Add another group to the fleet:

```ruby
# (creation of other_group not shown)
fleet.groups << other_group
```

Now that you have a fleet with multiple groups you can perform actions
across the fleet.

Suspend and resume scaling activities across all groups:

```ruby
fleet.suspend_all_processes
# do stuff where you don't want scaling activities
fleet.resume_all_processes
```

Update the launch configuration for all groups:

```ruby
fleet.update_launch_configuration('new-launch-config',
  :image_id => 'ami-8765432')
```

That will create a new launch configuration, and add it to all the
groups, replacing the old one.

## How It Works

Fleets are identified using tags on Auto Scaling groups. When you create
a new fleet 'my-fleet', it adds the tag key "asgfleet:my-fleet" with
value "template". Other groups added to the fleet get tagged with key
"asgfleet:my-fleet" and value "member". If you don't have a group tagged
with "template" and attempt to perform a `update_launch_configuration`, it
will use the first group tagged as a member instead.
