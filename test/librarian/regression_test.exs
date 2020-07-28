defmodule RealbookTest.Librarian.RegressionTest do
  use ExUnit.Case, async: true

  test "regression_test 27Jul2020" do
    # sudo_send doesn't correctly send a file to a location that is owned by
    # superuser that the primary user can't itself send to

    random_dirname = Realbook.tmp_dir!()

    tmp_filename = 0..0xFFFFFFFF
    |> Enum.random
    |> Integer.to_string(16)

    File.mkdir_p!(random_dirname)
    {_, 0} = System.cmd("chmod", ["700", random_dirname])
    {_, 0} = System.cmd("sudo", ["chown", "root:root", random_dirname])

    username = case System.cmd("whoami", []) do
      {res, 0} -> String.trim(res)
    end

    random_file_path = Path.join(random_dirname, tmp_filename)
    Realbook.set(random_file_path: random_file_path)

    Realbook.connect!(Realbook.Adapters.SSH, host: "localhost", user: username)

    Realbook.eval("""
    verify false
    play do
      sudo_send!("foo", (get :random_file_path))
    end
    """)

    {_, 0} = System.cmd("sudo", ["chown", username, random_dirname])

    assert File.read!(random_file_path) =~ "foo"
  end
end
