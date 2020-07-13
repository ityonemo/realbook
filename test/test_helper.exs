Application.ensure_all_started(:ssh)
Code.ensure_compiled(:crypto)
Application.put_env(:realbook, :script_dir, Path.join(__DIR__, "_assets"))

ExUnit.start()
