# Toggle

Toggle provides an organized and flexible framework to set up, manage, and
switch between different configuration settings in your Ruby scripts.

## Why?

Ensuring that a script has the correct configuration settings can become a real
headache. Have you ever had to run a script under different environment
specifications or had to share a script that requires different settings based
on who is running the code?

You may have resorted to storing configuration information in a hash to the top
of a given script to provide some flexibility. This can work for a script or
two and when your on a small team, but as you write more code or increase your
team's size the need for organization while still maintaining flexibility
quickly arises.

Having a common pattern around how per-project configurations are handled
becomes a big plus. Projects like [rbenv-vars](https://github.com/sstephenson/rbenv-vars)
came about to help solve issues like these.

Toggle provides a project with rbenv-vars-like functionality with two main
additions:

1. rbenv is not required
2. you can specify *multiple* environment setups instead of just one on a
   per-project basis, each of which is easily switchable to either programmatically
   or at runtime.

Additionally, Toggle provides a command line interface to facilitate setting up
this framework along with a set of options to quickly inspect which variables are
available within a project and what each variable is set to for a given environment
specification.

## Installation

Add this line to your application's Gemfile:

    gem 'toggle'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install toggle

## Basic Usage

To start using Toggle you first need a configuration file. This file
will typically be in YAML format and can contain inline ERB. The file's content
will include all the different configuration sections you want to be able to toggle to.
Each section should be namespaced appropriately.

As an example let's say we have two different script configurations we'd like to
have available and we name each `alpha` and `beta` respectively. Then our
configuration file might look like:

```yaml
# Sample config.yml demonstrating Toggle usage.
# Notice that each section contains the same keys but the values vary.
:alpha:
  :name: mr_alpha
  :secret: <%= ENV['ALPHA_SECRET'] %> # pretend this is "alpha-secret"

:beta:
  :name: mr_beta
  :secret: <%= ENV['BETA_SECRET'] %> # pretend this is "beta-secret"
```

Now in any script we can leverage Toggle to toggle between each configuration
section by setting the `key` attribute, which will load the corresponding
configuration section:

```ruby
require 'toggle'
toggle = Toggle.new config_filepath: './config.yml'

toggle.key = :alpha
puts "#{toggle[:name]} has a secret: #{toggle[:secret]}!"
#=> mr_alpha has a secret: alpha-secret

toggle.key = :beta
puts "#{toggle[:name]} has a secret: #{toggle[:secret]}!"
#=> mr_beta has a secret: beta-secret
```

Toggle also supports temporary access to a configuration section by passing a
block to `#using`:

```ruby
require 'toggle'

toggle = Toggle.new config_filepath: './config.yml',
                    key:             :beta

toggle.using(:alpha) do |s|
  puts "#{s[:name]} has a secret: #{s[:secret]}!"
  #=> mr_alpha has a secret: alpha-secret
end

puts "#{toggle[:name]} has a secret: #{toggle[:secret]}!"
#=> mr_beta has a secret: beta-secret
```

As an alternative to specifying the `key` attribute programmatically, you can
create a key file:

```yaml
# sample key.yml file
alpha
```

and then set Toggle's `key_filepath` attribute to specify where the `key`'s
value should be derived from:

```ruby
require 'toggle'

toggle = Toggle.new config_filepath: './config.yml',
                    key_filepath:    './key.yml'

puts "#{toggle[:name]} has a secret: #{toggle[:secret]}!"
#=> mr_alpha has a secret: alpha-secret
```

## Realworld Use Case: Runtime Toggling

Let's say there is a developer named Jane and she wants to author a script that
connects to a database server, pulls in data and does some processing, and then
emails the results to her team.

As she developes the script she wants to pull data from a staging database and
just email the results to herself so she can see how the final product would
look without bothering the whole team until the finished product is ready.

Once everything is complete she wants to pull data from a production database
and send the email.

With Toggle, this is easy:

```yaml
# Jane's sample config.yml
:development:
  :who_to_email: 'jane@company.com'

  :database:
    :host: https://staging.data.company.com
    :name: some_staging_db
    :table: some_staging_table
    :username: jane
    :password: <%= ENV['DATABASE_PASSWORD'] %>

:production:
  :who_to_email: 'team@company.com'

  :database:
    :host: https://prod.data.company.com
    :name: some_prod_db
    :table: some_prod_table
    :username: jane
    :password: <%= ENV['DATABASE_PASSWORD'] %>
```

```ruby
# Jane's sample email_data.rb script
require 'toggle'

toggle = Toggle.new config_filepath: './config.yml',
                    key:             ENV['key']

connection = SomeDBDriver.connect host:     toggle[:database][:host]
                                  username: toggle[:database][:username]
                                  password: toggle[:database][:password]

data = connection.get_data_from database: toggle[:database][:name],
                                table:    toggle[:database][:table]

SomeEmailer.send to:   toggle[:who_to_email],
                 what: data
```

Now running `email_data.rb` under the development configuration settings is a
snap:

    $ key=development ruby email_data.rb
    # => will connect to the staging db + just email jane

And when it's deemed ready for primetime it can be run with the production
configuration settings via:

    $ key=production ruby email_data.rb
    # => will connect to the prod db + email the team

## Realworld Use Case: Abstracted Configuration and Sharing

Continuing with our example from above, let's say that Jane needs to share the
script with John who is another developer on her team so he can work on it
(perhaps he wants to add in logic that does not send an email if no data is
returned so the team doesn't receive an empty email).

Jane can further abstract her `config.yml` file to faciliate quick sharing
between co-workers:

```yaml
# Jane's new sample config.yml
#
# Notice that we have abstracted out the email address, database username and
# password into ENV vars
:development:
  :who_to_email: <%= ENV['USER_EMAIL'] %>

  :database:
    :host: https://staging.data.company.com
    :name: some_staging_db
    :table: some_staging_table
    :username: <%= ENV['DATABASE_USERNAME'] %>
    :password: <%= ENV['DATABASE_PASSWORD'] %>

:production:
  :who_to_email: 'team@company.com'

  :database:
    :host: https://prod.data.company.com
    :name: some_prod_db
    :table: some_prod_table
    :username: <%= ENV['DATABASE_USERNAME'] %>
    :password: <%= ENV['DATABASE_PASSWORD'] %>
```

John is a `git clone` (or whatever vcs he is using) away from having the
script downloaded locally and ready to run without requiring any configuration
edits.

In fact, anyone that has `DATABASE_USERNAME`, `DATABASE_PASSWORD`
and `USER_EMAIL` set in their environment can run this script without requiring
any configuration adjustments.

In general if your team uses any common variables you should consider
abstracting each into environment variables and including them via ERB. Toggle
comes with an easy way to set this up on a per-computer basis. First, run:

    $ toggle --init-local

This will create `~/.toggle.local`, which you can then edit to `export` any
variables you want to be available in your environment. Finally, make sure
you source this file so your variables are ready to go.

## Ignoring the Config and Key Files

If you can effectively abstract out all configuration settings in environment
variables, you may be able to just commit your `config.yml` and your `key.yml`
files to source control.

However, consider .gitignore-ing each and providing a `config.yml.default` and
key.yml.default` in their place. With these default files in place you provide
runtime guidance, but allow each developer to make any local adjustments without
running the risk of having these changes committed back to the project's repo
and breaking someone else's settings when they pull in the latest changes.

Again, borrowing from the above example, if Jane were to instead provide
`config.yml.default` and `key.yml.default` files in her repo, anyone that
downloaded her repo would need to copy each file to their appropriate location
(`config.yml` and `key.yml` respectively) so the script could run. This can be
easily accomplished via:

    $ toggle --copy-defaults project/path

or you can do this manually via:

    $ cp project/path/config.yml.default project/project/config.yml
    $ cp project/path/key.yml.default    project/project/key.yml

## Toggle CLI

Toggle comes bundled with a commandline interface:

```
$ toggle --help
Usage: toggle <args>

Specific arguments:
    -g, --init-local [PATH]           Adds [PATH]/.toggle.local with var placeholders. Default is $HOME.
    -k, --keys file                   Show available keys for the specified config FILE
        --values FILE,KEY             Show values for the KEY in the config FILE
        --copy-config-defaults [PATH]
                                      Copy all toggle config defaults to actuals in PATH. Default is pwd.
    -c, --copy-defaults [PATH]        Copy all .toggle.default to .toggle for PATH. Default is pwd.
        --ensure-key [PATH]           Copies the default key in [PATH] if actual key is not present, does nothing otherwise. Default [PATH] is pwd.
    -m, --make-defaults [PATH]        Create [PATH]/{config|key}{,.*}.default. Default is pwd.
    -v, --version                     Show version
    -h, --help                        Show this message
```

## Contributing

If you would like to contribute code to Toggle you can do so through GitHub by
forking the repository and sending a pull request.

When submitting code, please make every effort to follow existing conventions
and style in order to keep the code as readable as possible.

Before your code can be accepted into the project you must also sign the
[Individual Contributor License Agreement (CLA)][1].


 [1]: https://spreadsheets.google.com/spreadsheet/viewform?formkey=dDViT2xzUHAwRkI3X3k5Z0lQM091OGc6MQ&ndplr=1

## License

Copyright 2013 Square Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
