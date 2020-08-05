defmodule EtsyTest do
  use ExUnit.Case
  doctest Etsy

  test "greets the world" do
    assert Etsy.hello() == :world
  end
end
