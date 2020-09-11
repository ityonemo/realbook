# Realbook versions

## 0.1.0

- initial release, as split to a separate project, *warning: untested for real deployments*.

## 0.1.1

- added (provisional) `asset!` command.  A smarter version will be rolled out
  in `0.2.0`, so don't count on its current semantics.
- converted `Realbook.Commands.get/2` to a function instead of a macro.

## 0.1.2

- added guides directory to mix package so that downloading from hex.pm
  doesn't fail

## 0.1.3

- fixed `requires` to be able to take a comptime variable.
- fixed `sudo_send` to not fail with a permissions error.
- implemented `wait_till` macro.
- implemented `assigns` macro.

## 0.1.4

- run! now trims its string output.

## 0.2.0

- more inforamtive KeyErrors
- asset tracking and errors on absence of the assets
- support for Tasks
- correct support for submodule and subdirectory dependencies.
- `sigil_b` and `sigil_B` support
- simplified requires-only realbooks.
- `asset!` is now a macro and causes early checking.

## 0.2.1

- fix sigil_B to emit correct error messages
- fix sigil_B to be concurrent

## 0.2.2

- added logger metadata and information to disambiguate hosts in
  concurrent deploys

## 0.3.0

- added `Realbook.Commands.asset!/1`
- added `Realbook.Commands.asset_path!/1`
- added `Realbook.Commands.run_tty/2!`
- added `Realbook.Commands.run_bool!/2`
- added support for statically included `.ex` realbooks
- generalized compiler semaphore for general use
- fixed bug in `Roalbook.Commands.sudo_send!/2`

## 0.3.1

- updated to use Librarian 0.2.0 with guidelines for large file scp.

## Future features:

- Deployment guides
- Structured metadata logging
- Use a different backend than `System.cmd` for `Realbook.Adapters.Local`
- Streaming file transfers (requires `Librarian` ~> 0.2.0)
- Track executing realbooks, and dynamically provision/deprovision modules.
- Improve composability, by optionally remapping variable names
- Type-validation on variable names.
