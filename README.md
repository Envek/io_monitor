# IoMonitor

A gem that helps to detect potential memory bloats.

When your controller loads a lot of data to the memory but returns a small response to the client it might mean that you're using the IO in the non–optimal way. In this case, you'll see the following message in your logs:

```
Completed 200 OK in 349ms (Views: 2.1ms | ActiveRecord: 38.7ms | ActiveRecord Payload: 866.00 B | Response Payload: 25.00 B | Allocations: 72304)
```

<p align="center">
  <a href="https://evilmartians.com/?utm_source=io_monitor">
    <img src="https://evilmartians.com/badges/sponsored-by-evil-martians.svg" alt="Sponsored by Evil Martians" width="236" height="54">
  </a>
</p>

## Usage

Add this line to your application's Gemfile:

```ruby
gem 'io_monitor'
```

Currently gem can collect the data from `ActiveRecord`, `Net::HTTP` and `Redis`.

Change configuration in an initializer if you need:

```ruby
IoMonitor.configure do |config|
  config.publish = :notifications # defaults to :logs
  config.warn_threshold = 0.8 # defaults to 0
  config.adapters = [:active_record, :net_http, :redis] # defaults to [:active_record]
end
```

Then include the concern into your controller:

```ruby
class MyController < ApplicationController
  include IoMonitor::Controller
end
```

Depending on configuration when IO payload size to response payload size ratio reaches the threshold either a `warn_threshold_reached.io_monitor` notification will be sent or a following warning will be logged:

```
ActiveRecord I/O to response payload ratio is 0.1, while threshold is 0.8
```

In addition, if `publish` is set to logs, additional data will be logged on each request:

```
Completed 200 OK in 349ms (Views: 2.1ms | ActiveRecord: 38.7ms | ActiveRecord Payload: 866.00 B | Response Payload: 25.00 B | Allocations: 72304)
```

If you want to inspect payload sizes, check out payload data for the `process_action.action_controller` event:

```ruby
ActiveSupport::Notifications.subscribe("process_action.action_controller") do |name, start, finish, id, payload|
  payload[:io_monitor] # { active_record: 866, response: 25 }
end
```

## Custom publishers

Implement your custom publisher by inheriting from `BasePublisher`:

```ruby
class MyPublisher < IoMonitor::BasePublisher
  def publish(source, ratio)
    puts "Warn threshold reched for #{source} at #{ratio}!"
  end
end
```

Then specify it in the configuration:

```ruby
IoMonitor.configure do |config|
  config.publish = MyPublisher.new
end
```

## Custom adapters

Implement your custom adapter by inheriting from `BaseAdapter`:

```ruby
class MyAdapter < IoMonitor::BaseAdapter
  def self.kind
    :my_source
  end

  def initialize!
    # Take a look at `AbstractAdapterPatch` for an example.
  end
end
```

Then specify it in the configuration:

```ruby
IoMonitor.configure do |config|
  config.adapters = [:active_record, MyAdapter.new]
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/DmitryTsepelev/io_monitor.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Credits

Thanks to [@prog-supdex](https://github.com/prog-supdex) and [@maxshend](https://github.com/maxshend) for building the initial implementations (see [PR#2](https://github.com/DmitryTsepelev/io_monitor/pull/2) and [PR#3](https://github.com/DmitryTsepelev/io_monitor/pull/3)).
