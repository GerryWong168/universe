defmodule Universe.SpaceGameTest do
  use ExUnit.Case, async: true

  alias Universe.SpaceGame

  test "reserves quadrant 3,3 sector 5,5 for Sol" do
    game = SpaceGame.new_game() |> SpaceGame.warp_to_quadrant(3, 3)

    assert game.galaxy[{3, 3}].solar_system == "Sol"
    assert game.galaxy[{3, 3}].klingons == 0
    assert game.galaxy[{3, 3}].starbases == 0
    assert game.galaxy[{3, 3}].stars > 0
    assert game.current_quadrant[{5, 5}].type == :solar_system
    assert game.current_quadrant[{5, 5}].name == "Sol"
    assert SpaceGame.at_sol?(game)
  end

  test "allows the ship to land on Sol and recharge" do
    game =
      SpaceGame.new_game()
      |> SpaceGame.warp_to_quadrant(3, 3)
      |> SpaceGame.move_ship("down")
      |> SpaceGame.move_ship("up")
      |> Map.put(:energy, 42)
      |> Map.put(:torpedoes, 1)
      |> Map.put(:shields, 200)

    assert SpaceGame.at_sol?(game)

    game = SpaceGame.recharge_at_sol(game)

    assert game.energy == 3000
    assert game.torpedoes == 10
    assert game.shields == 0
  end

  test "serializes and restores an in-progress game state" do
    game =
      SpaceGame.new_game()
      |> SpaceGame.warp_to_quadrant(3, 3)
      |> Map.put(:energy, 2450)
      |> Map.put(:torpedoes, 7)

    encoded = SpaceGame.serialize_state(game)

    assert {:ok, restored} = SpaceGame.deserialize_state(encoded)
    assert restored.energy == 2450
    assert restored.torpedoes == 7
    assert restored.quadrant_x == 3
    assert restored.quadrant_y == 3
  end
end
