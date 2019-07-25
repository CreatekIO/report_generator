# ReportGenerator

A gem for generating CSVs asynchronously with a DSL.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'report_generator'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install report_generator

## Usage

Declare a new generator somewhere (`lib` is a good place):

```ruby
# lib/widget_report.rb
class WidgetReport < ReportGenerator::Base
  # give your report a name, so that we can find this generator class
  registers :widgets

  # Declare your columns - the blocks here are given each instance from `collection`
  column('ID', &:id) # you can use shorthand blocks
  column('Added') { |widget| widget.created_at.to_s(:long) }

  private

  # The `collection` method generates the instances that are passed to the `column` helpers
  def collection
    widgets = Widget.all

    # You can use any params you've passed in when enqueuing the report
    start_date = report_download.report_data[:start_date]
    widgets = widgets.where('created_at > ?', start_date) if start_date.present?

    widgets
  end
end
```

Then add a button somewhere for your report:

```erb
<%= report_button(
  'widgets', # this is the name you passed to `registers`
  report_start_date: Date.today, # any custom params can be given, starting with `report_`
  button_label: 'Export widget CSV' # you can also customise parts of the button
) %>
```

This button will pop open a modal asking the user if they want a link to CSV sent via email, and will then
enqueue their report in Sidekiq.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.
