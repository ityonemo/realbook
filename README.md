# Realbook

You... rather dislike Ansible.  And wish there were a simple, imperative DSL
that did all the things that Ansible doesn't do.  The code you write should be
explicit, variables should be tracked, easily inspected, and it should be in
a turing-complete language.

This is the package for you.

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
  Realbook.connect(:ssh, )
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
    {:realbook, "~> 0.1.0"}
  ]
end
```

Documentation can be found at [https://hexdocs.pm/realbook](https://hexdocs.pm/realbook).
