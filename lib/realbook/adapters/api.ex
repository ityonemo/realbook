defmodule Realbook.Adapters.Api do

  @moduledoc """
  common interface for communications adapters between the local machine
  and the remote deployment target.

  All realbook command macros adapt this interface to perform the relevant
  commands.

  For example code, see:

  - `Realbook.Adapters.Local`
  - `Realbook.Adapters.SSH`
  """

  @typedoc """
  A token that represents the remote deployment target.

  Such a token will be provided to the adapter functions as their first
  parameter.  Produced by `c:connect/1`
  """
  @type conn :: any

  @doc """
  connects into the remote target and produces a  `t:conn/0` token.

  NB: for `Realbook.Adapters.SSH` the host parameter will live in this
  variable.
  """
  @callback connect(options :: keyword) :: {:ok, conn} | {:error, term}

  @doc """
  provides the connection name, given the initial connection options
  """
  @callback name(options :: keyword) :: String.t

  @doc """
  executes a unix command on the remote target.

  ## Warning:
  this may or may not support piping operations, depending on the underlying
  implementation.  The guidelines for running pipes may change in the future.
  """
  @callback run(conn, String.t, options :: keyword) ::
    {:ok, String.t, non_neg_integer} | {:error, String.t | :file.posix}

  @typedoc "allows you to select a stored key for content or file name"
  @type variable_key :: atom

  @doc """
  sends a binary or a file to the remote server.

  NB: options might take the `:sudo` options, which should be filtered
  prior to sending the contents.
  """
  @callback send(conn, binary | Enumerable.t, Path.t, options :: keyword) ::
    :ok | {:error, :file.posix}

  @doc """
  appends a binary or a file to the remote server.

  NB: options might take the `:sudo` options, which should be filtered
  prior to sending the contents.
  """
  @callback append(conn, binary | Enumerable.t, Path.t, options :: keyword) ::
    :ok | {:error, :file.posix}

end
