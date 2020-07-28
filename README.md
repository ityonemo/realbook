# Realbook

You... rather dislike Ansible.  And wish there were a simple, imperative DSL
that did all the things that Ansible doesn't do.  The code you write should be
explicit, variables should be tracked, easily inspected, and it should be in
a turing-complete language.

This is the package for you.

## Feature Roadmap

Warning:  This system is not guaranteed to be tested in a real deployment until release `0.2.0`.  It's also not certain if the designed strategy is
reasonable or useful.  The API will be guaranteed to be stabilized by
`0.5.0`, at which point the following features will be guaranteed:

- tested in a concurrent deployment scenario
- being used to deploy an in-prod system
- being used as a sidecar system via distributed erlang:
  - a separate erlang VM is spawned which contains the realbook modules
    this VM can be thrown away, which clears the resources for those
    modules
- well-defined logger metadata

The `1.0` version will include telemetry and operability features,
  possibly include support for a pluggable Phoenix LiveView dashboard.
  It may also possibly include data ingress typechecking.

PRs and assistance greatly welcome.

## Usage

1. You must set the directory that contains your Realbook scripts:

  ```elixir
  Application.put_env(:realbook, :script_dir, "scripts/")
  ```

2. In your scripts directory, write your scripts as `.exs` files, for example
  into `example.exs`:

  ```elixir
  verify do
    run! "test -f /tmp/foo"
  end

  play do
    run! "touch /tmp/foo"
  end
  ```

3. Connect to your server.
  ```elixir
  Realbook.connect!(:ssh, host: "my_host_name", user: "my_user_name")
  ```

4. Run it!

  ```elixir
  Realbook.run("example.exs")
  ```

For further information, check the `Guides` section of the documentation.

## Installation

The package can be installed by adding `realbook` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:realbook, "~> 0.1.2"}
  ]
end
```

Documentation can be found at [https://hexdocs.pm/realbook](https://hexdocs.pm/realbook).
