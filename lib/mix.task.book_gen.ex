defmodule Mix.Tasks.Realbook.Gen do

  use Mix.Task
  @shortdoc "generates a empty realbook in lib/realbook"

  @moduledoc """
  Generates an empty realbook.

  This realbook will be placed in lib/realbook/scripts.

  ## Arguments

  The list of realbook skeletons to be created.  You may omit
  the `.ex` extension.  Currently, subdirectories are not supported.
  """

  @base_path "lib/realbook/scripts"

  require EEx

  @impl true
  def run(lst) do
    if Mix.Project.umbrella?() do
      Mix.raise "mix realbook.gen must be invoked from within your application root directory"
    end

    File.mkdir_p!(@base_path)
    for filename <- lst do

      if filename =~ "/" do
        Mix.raise "mix realbook.gen does not currently allow subdirectories"
      end

      normalized_filename = Path.basename(filename, ".ex")
      
      @base_path
      |> Path.join(normalized_filename <> ".ex")
      |> File.write!(skeleton(normalized_filename))
    end
  end

  EEx.function_from_string(:defp, :skeleton, """
  defmodule Realbook.Scripts.<%= Macro.camelize(normalized_filename) %> do
    use Realbook

    # insert dependencies here
    requires []

    verify do
      # insert verification code here
    end

    play do
      # insert action code here
    end
  end
  """, [:normalized_filename])

end
