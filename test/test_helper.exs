Application.ensure_all_started(:ssh)
Code.ensure_compiled(:crypto)
Code.ensure_compiled(:asn1rt_nif)
Application.put_env(:realbook, :script_dir, Path.join(__DIR__, "_scripts"))
Application.put_env(:realbook, :asset_dir, Path.join(__DIR__, "_assets"))

System.cmd("rm", ["-rf", "/tmp/.realbook"])

ExUnit.start()
