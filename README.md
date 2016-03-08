# CanDo

Flips your features based on a `config/features.yml` file or environment variables. No data store required.

## Usage

Add `can-do` to your Gemfile:

```ruby
# Gemfile

gem "can-do", require: "can_do"
```

Inside the `config` folder relative to your working directory create a file called `features.yml`. Within this file,
place your *default feature flags* within the `defaults` key. All available features should be listed here, together with
their default values. Add *environment-specific* feature flags under the environment name.

```
# config/features.yml

defaults:
  some_feature: false
  other_feature: true
development:
  some_feature: true
production:
  other_feature: false
```

Check if a feature is enabled by calling `CanDo.feature?(:some_feature)`:

```ruby
require "can_do"

CanDo.feature?(:some_feature)
```

Or by using a block:

```ruby
require "can_do"

CanDo.feature?(:some_feature) do
  # This block is only evaluated if some_feature is enabled
end
```

If a feature is not found, `CanDo::NotAFeature` is raised.

## Environment variables

You can use environment variables to flip your features. Environment variables **always take precedence** over anything
within your `config/features.yml` file.

```sh
> RAILS_ENV=development rails console
CanDo.feature?(:some_feature) => false

> SOME_FEATURE=true RAILS_ENV=development rails console
CanDo.feature?(:some_feature) => true

> SOME_FEATURE=true RAILS_ENV=development rails console
CanDo.feature?(:some_feature) => true

> OTHER_FEATURE=true RAILS_ENV=production rails console
CanDo.feature?(:other_feature) => true
```

## Contributing

1. Fork it ( https://github.com/blacklane/can_do/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
