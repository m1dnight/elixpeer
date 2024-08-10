defmodule Measure do
  @moduledoc """
  Functions to measure the execution time of functions.
  """
  @doc """
  Measures the execution time of a function and returns the time in seconds together with the result
  """
  @spec measure((-> any())) :: {float(), any()}
  def measure(function) do
    {time, res} = :timer.tc(function)

    {time / 1_000_000, res}
  end
end
