# Realbook versions

## 0.1.0

- initial release, as split to a separate project, *warning: untested for real deployments*.

## 0.1.1

- added (provisional) assets! command.  A smarter version will be rolled out
  in `0.2.0`, so don't count on its current semantics.
- converted `Realbook.Commands.get/2` to a function instead of a macro.

## 0.1.2

- added guides directory to mix package so that downloading from hex.pm
  doesn't fail

## 0.1.3

- fixed `requires` to be able to take a comptime variable
- fixed `sudo_send` to not fail with a permissions error.
- implemented `wait_till`

## Future features:

- Deployment guides
- Structured metadata logging
- Use a different backend than `System.cmd` for `Realbook.Adapters.Local`
- Streaming file transfers (requires `Librarian` ~> 0.2.0)
- Track executing realbooks, and dynamically provision/deprovision modules.
- Improve composability, by optionally remapping variable names
- Type-validation on variable names.
