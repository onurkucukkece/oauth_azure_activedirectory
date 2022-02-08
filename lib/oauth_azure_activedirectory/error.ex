defmodule OauthAzureActivedirectory.Error do
  @type t() :: %__MODULE__{
    module: module(),
    reason: atom()
  }

  defexception [:module, :reason]

  @spec wrap(module(), atom()) :: t()
  def wrap(module, reason), do: %__MODULE__{module: module, reason: reason}

  @doc """
  Return the message for the given error.
  ### Examples
       iex> {:error, %MyApp.Error{} = error} = do_something()
       iex> Exception.message(error)
       "Unable to perform this action."
  """
  @spec message(t()) :: String.t()
  def message(%__MODULE__{reason: reason, module: module}) do
    module.format_error(reason)
  end
end
