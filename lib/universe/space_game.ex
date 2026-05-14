defmodule Universe.SpaceGame do
  @moduledoc """
  Core game logic for the Star Trek-style space game.
  Manages the galaxy state, ship position, enemies, and game mechanics.
  """

  defstruct [
    :galaxy,
    :quadrant_x,
    :quadrant_y,
    :sector_x,
    :sector_y,
    :energy,
    :torpedoes,
    :shields,
    :klingons_remaining,
    :stardates_remaining,
    :score,
    :messages,
    :current_quadrant
  ]

  @galaxy_size 8
  @quadrant_size 10
  @initial_energy 3000
  @initial_torpedoes 10
  @initial_shields 0
  @sol_quadrant {3, 3}
  @sol_sector {5, 5}
  @sol_name "Sol"

  def new_game do
    galaxy = generate_galaxy()
    {qx, qy} = find_safe_starting_quadrant(galaxy)
    total_klingons = count_total_klingons(galaxy)

    %__MODULE__{
      galaxy: galaxy,
      quadrant_x: qx,
      quadrant_y: qy,
      sector_x: 5,
      sector_y: 5,
      energy: @initial_energy,
      torpedoes: @initial_torpedoes,
      shields: @initial_shields,
      klingons_remaining: total_klingons,
      stardates_remaining: trunc(total_klingons * 2.5),
      score: 0,
      messages: [
        "Welcome to the USS Enterprise, Captain!",
        "Your mission: eliminate all Klingon warships."
      ],
      current_quadrant: %{}
    }
    |> refresh_quadrant()
  end

  def move_ship(game, direction) do
    {dx, dy} = direction_to_delta(direction)
    new_sx = game.sector_x + dx
    new_sy = game.sector_y + dy

    cond do
      new_sx < 1 or new_sx > @quadrant_size or new_sy < 1 or new_sy > @quadrant_size ->
        change_quadrant(game, dx, dy)

      collision?(game.current_quadrant, new_sx, new_sy) ->
        add_message(game, "Cannot move there - obstacle in the way!")

      true ->
        game
        |> Map.put(:sector_x, new_sx)
        |> Map.put(:sector_y, new_sy)
        |> use_energy(5)
        |> use_stardate(0.1)
        |> klingons_attack()
        |> add_message("Impulse engines engaged. Position: #{new_sx},#{new_sy}")
    end
  end

  def fire_phasers(game, power) when power > 0 and power <= game.energy do
    klingons = find_klingons(game.current_quadrant)

    if Enum.empty?(klingons) do
      add_message(game, "No targets detected!")
    else
      game
      |> use_energy(power)
      |> use_stardate(0.1)
      |> damage_klingons(power, klingons)
      |> klingons_attack()
    end
  end

  def fire_phasers(game, _power), do: add_message(game, "Insufficient energy for phaser banks!")

  def fire_torpedo(game, direction) when game.torpedoes > 0 do
    game
    |> Map.update!(:torpedoes, &(&1 - 1))
    |> use_stardate(0.1)
    |> launch_torpedo(direction)
    |> klingons_attack()
  end

  def fire_torpedo(game, _direction), do: add_message(game, "Photon torpedo tubes empty!")

  def short_range_scan(game) do
    klingons = count_entities(game.current_quadrant, :klingon)
    starbases = count_entities(game.current_quadrant, :starbase)
    stars = count_entities(game.current_quadrant, :star)

    add_message(game, "Scan: #{klingons} Klingons, #{starbases} Starbases, #{stars} Stars")
  end

  def long_range_scan(game) do
    scan_results = get_adjacent_quadrants(game)
    add_message(game, "Long range sensors: #{format_scan(scan_results)}")
  end

  def raise_shields(game, amount) when amount >= 0 and amount <= 1000 do
    current_shields = game.shields
    shield_diff = amount - current_shields
    energy_cost = trunc(shield_diff * 0.5)

    cond do
      shield_diff > 0 and game.energy < energy_cost ->
        add_message(
          game,
          "Insufficient energy! Need #{energy_cost} energy for #{shield_diff} shields."
        )

      shield_diff < 0 ->
        # Lowering shields returns energy
        energy_returned = trunc(abs(shield_diff) * 0.5)

        game
        |> Map.put(:shields, amount)
        |> Map.put(:energy, game.energy + energy_returned)
        |> add_message("Deflector shields lowered to #{amount} units")

      true ->
        # Raising shields costs energy
        game
        |> Map.put(:shields, amount)
        |> Map.put(:energy, game.energy - energy_cost)
        |> add_message("Deflector shields set to #{amount} units")
    end
  end

  def raise_shields(game, _amount),
    do: add_message(game, "Invalid shield setting! Must be 0-1000.")

  def warp_to_quadrant(game, target_qx, target_qy) do
    # Validate coordinates
    cond do
      target_qx < 1 or target_qx > @galaxy_size or target_qy < 1 or target_qy > @galaxy_size ->
        add_message(game, "Invalid quadrant coordinates! Must be 1-8.")

      target_qx == game.quadrant_x and target_qy == game.quadrant_y ->
        add_message(game, "Already in quadrant #{target_qx},#{target_qy}!")

      true ->
        # Calculate hypotenuse distance
        dx = target_qx - game.quadrant_x
        dy = target_qy - game.quadrant_y
        distance = :math.sqrt(:math.pow(dx, 2) + :math.pow(dy, 2))

        # Energy cost: 50 * distance (minimum 50)
        energy_cost = max(50, round(50 * distance))

        # Time cost: 0.5 * distance (minimum 0.5)
        time_cost = max(0.5, 0.5 * distance)

        if game.energy < energy_cost do
          add_message(
            game,
            "Insufficient energy for warp! Required: #{energy_cost}, Available: #{game.energy}"
          )
        else
          game
          |> Map.put(:quadrant_x, target_qx)
          |> Map.put(:quadrant_y, target_qy)
          |> Map.put(:sector_x, div(@quadrant_size, 2))
          |> Map.put(:sector_y, div(@quadrant_size, 2))
          |> use_energy(energy_cost)
          |> use_stardate(time_cost)
          |> refresh_quadrant()
          |> add_message(
            "Warp drive engaged! Warped to quadrant #{target_qx},#{target_qy} (Distance: #{Float.round(distance, 1)}, Energy: #{energy_cost}, Time: #{Float.round(time_cost, 1)})"
          )
        end
    end
  end

  def dock_at_starbase(game) do
    if starbase_adjacent?(game) do
      game
      # 100% energy
      |> Map.put(:energy, 3000)
      # 100% torpedoes
      |> Map.put(:torpedoes, 10)
      |> Map.put(:shields, 0)
      |> add_message("Docked! All systems repaired and resupplied.")
    else
      add_message(game, "No starbase in docking range!")
    end
  end

  def at_sol?(game) do
    {game.quadrant_x, game.quadrant_y} == @sol_quadrant and
      {game.sector_x, game.sector_y} == @sol_sector
  end

  def recharge_at_sol(game) do
    if at_sol?(game) do
      game
      |> Map.put(:energy, @initial_energy)
      |> Map.put(:torpedoes, @initial_torpedoes)
      |> Map.put(:shields, @initial_shields)
      |> add_message("Recharged at Sol. Energy and torpedoes restored.")
    else
      add_message(game, "Recharge unavailable - set course for Sol in quadrant 3,3 sector 5,5.")
    end
  end

  def serialize_state(%__MODULE__{} = game) do
    game
    |> :erlang.term_to_binary()
    |> Base.url_encode64(padding: false)
  end

  def deserialize_state(encoded) when is_binary(encoded) do
    with {:ok, binary} <- Base.url_decode64(encoded, padding: false),
         term <- :erlang.binary_to_term(binary, [:safe]),
         %__MODULE__{} = game <- term do
      {:ok, game}
    else
      _ -> :error
    end
  rescue
    ArgumentError -> :error
  end

  def game_over?(game) do
    game.energy <= 0 or game.stardates_remaining <= 0 or game.klingons_remaining <= 0
  end

  def game_status(game) do
    cond do
      game.energy <= 0 -> {:lost, "Enterprise destroyed!"}
      game.stardates_remaining <= 0 -> {:lost, "Mission failed - out of time!"}
      game.klingons_remaining <= 0 -> {:won, "Victory! All Klingon forces eliminated!"}
      true -> {:playing, ""}
    end
  end

  defp generate_galaxy do
    for x <- 1..@galaxy_size, y <- 1..@galaxy_size, into: %{} do
      {klingons, starbases, stars, solar_system} =
        if {x, y} == @sol_quadrant do
          {0, 0, :rand.uniform(8), @sol_name}
        else
          {
            if(:rand.uniform(100) < 30, do: :rand.uniform(3), else: 0),
            if(:rand.uniform(100) < 10, do: 1, else: 0),
            :rand.uniform(8),
            nil
          }
        end

      {{x, y},
       %{klingons: klingons, starbases: starbases, stars: stars, solar_system: solar_system}}
    end
  end

  defp refresh_quadrant(game) do
    quadrant = generate_quadrant(game.galaxy, game.quadrant_x, game.quadrant_y)
    game = Map.put(game, :current_quadrant, quadrant)

    # Check for Klingons and activate red alert shields
    klingon_count = count_entities(quadrant, :klingon)

    if klingon_count > 0 do
      # Red Alert! Auto-activate shields
      target_shields = if game.energy >= 250, do: 500, else: trunc(game.energy * 2)
      energy_cost = trunc((target_shields - game.shields) * 0.5)

      if energy_cost > 0 and game.energy >= energy_cost do
        game
        |> Map.put(:shields, target_shields)
        |> Map.put(:energy, game.energy - energy_cost)
        |> add_message(
          "RED ALERT! #{klingon_count} Klingon warship(s) detected! Shields raised to #{target_shields}."
        )
      else
        add_message(game, "RED ALERT! #{klingon_count} Klingon warship(s) detected!")
      end
    else
      game
    end
  end

  defp generate_quadrant(galaxy, qx, qy) do
    quadrant_data = galaxy[{qx, qy}]

    entities =
      []
      |> add_solar_system(qx, qy)
      |> add_entities(:klingon, quadrant_data.klingons, 100)
      |> add_entities(:starbase, quadrant_data.starbases, 0)
      |> add_entities(:star, quadrant_data.stars, 0)

    Enum.into(entities, %{})
  end

  defp add_solar_system(list, qx, qy) do
    if {qx, qy} == @sol_quadrant do
      [
        {@sol_sector, %{type: :solar_system, name: @sol_name, health: 0}}
        | list
      ]
    else
      list
    end
  end

  defp add_entities(list, _type, 0, _health), do: list

  defp add_entities(list, type, count, health) when count > 0 do
    new_entities =
      for _ <- 1..count do
        pos = find_empty_position(list)
        {pos, %{type: type, health: health}}
      end

    list ++ new_entities
  end

  defp find_empty_position(existing) do
    pos = {:rand.uniform(@quadrant_size), :rand.uniform(@quadrant_size)}

    if Enum.any?(existing, fn {p, _} -> p == pos end) do
      find_empty_position(existing)
    else
      pos
    end
  end

  defp find_safe_starting_quadrant(galaxy) do
    safe = Enum.find(galaxy, fn {{_x, _y}, data} -> data.klingons == 0 end)

    case safe do
      {{x, y}, _} -> {x, y}
      nil -> {1, 1}
    end
  end

  defp count_total_klingons(galaxy) do
    Enum.reduce(galaxy, 0, fn {_, data}, acc -> acc + data.klingons end)
  end

  defp direction_to_delta("up"), do: {0, -1}
  defp direction_to_delta("down"), do: {0, 1}
  defp direction_to_delta("left"), do: {-1, 0}
  defp direction_to_delta("right"), do: {1, 0}
  defp direction_to_delta(_), do: {0, 0}

  defp collision?(quadrant, x, y) do
    Enum.any?(quadrant, fn {{qx, qy}, entity} ->
      qx == x and qy == y and entity.type not in [:starbase, :solar_system]
    end)
  end

  defp change_quadrant(game, dx, dy) do
    new_qx = game.quadrant_x + if dx != 0, do: div(dx, abs(dx)), else: 0
    new_qy = game.quadrant_y + if dy != 0, do: div(dy, abs(dy)), else: 0

    if new_qx >= 1 and new_qx <= @galaxy_size and new_qy >= 1 and new_qy <= @galaxy_size do
      new_sx = if dx < 0, do: @quadrant_size, else: if(dx > 0, do: 1, else: game.sector_x)
      new_sy = if dy < 0, do: @quadrant_size, else: if(dy > 0, do: 1, else: game.sector_y)

      game
      |> Map.put(:quadrant_x, new_qx)
      |> Map.put(:quadrant_y, new_qy)
      |> Map.put(:sector_x, new_sx)
      |> Map.put(:sector_y, new_sy)
      |> use_energy(50)
      |> use_stardate(1)
      |> refresh_quadrant()
      |> add_message("Warp drive engaged. Entering quadrant #{new_qx},#{new_qy}")
    else
      add_message(game, "Cannot warp beyond galaxy boundaries!")
    end
  end

  defp find_klingons(quadrant) do
    Enum.filter(quadrant, fn {_, entity} -> entity.type == :klingon end)
  end

  defp damage_klingons(game, power, klingons) do
    ship_pos = {game.sector_x, game.sector_y}

    {updated_quadrant, hits, kills} =
      Enum.reduce(klingons, {game.current_quadrant, 0, 0}, fn {{kx, ky}, klingon},
                                                              {quad, hit_count, kill_count} ->
        distance = calculate_distance(ship_pos, {kx, ky})
        damage = trunc(power / distance)
        new_health = klingon.health - damage

        if new_health <= 0 do
          {Map.delete(quad, {kx, ky}), hit_count + 1, kill_count + 1}
        else
          {Map.put(quad, {kx, ky}, %{klingon | health: new_health}), hit_count + 1, kill_count}
        end
      end)

    game
    |> Map.put(:current_quadrant, updated_quadrant)
    |> update_galaxy_klingon_count(kills)
    |> Map.update!(:klingons_remaining, &(&1 - kills))
    |> Map.update!(:score, &(&1 + kills * 100))
    |> add_message("Phasers fired! #{hits} hits, #{kills} Klingons destroyed!")
  end

  defp launch_torpedo(game, direction) do
    {dx, dy} = direction_to_delta(direction)
    start_pos = {game.sector_x, game.sector_y}

    case trace_torpedo_path(start_pos, {dx, dy}, game.current_quadrant) do
      {:hit, :klingon, pos} ->
        updated_quadrant = Map.delete(game.current_quadrant, pos)

        game
        |> Map.put(:current_quadrant, updated_quadrant)
        |> update_galaxy_klingon_count(1)
        |> Map.update!(:klingons_remaining, &(&1 - 1))
        |> Map.update!(:score, &(&1 + 150))
        |> add_message("Torpedo HIT! Klingon warship destroyed!")

      {:hit, :star, _pos} ->
        add_message(game, "Torpedo absorbed by star!")

      {:miss} ->
        add_message(game, "Torpedo missed all targets!")
    end
  end

  defp trace_torpedo_path({x, y}, {dx, dy}, quadrant, steps \\ 0) do
    new_x = x + dx
    new_y = y + dy

    cond do
      steps > @quadrant_size * 2 ->
        {:miss}

      new_x < 1 or new_x > @quadrant_size or new_y < 1 or new_y > @quadrant_size ->
        {:miss}

      true ->
        case Map.get(quadrant, {new_x, new_y}) do
          %{type: :klingon} -> {:hit, :klingon, {new_x, new_y}}
          %{type: :star} -> {:hit, :star, {new_x, new_y}}
          _ -> trace_torpedo_path({new_x, new_y}, {dx, dy}, quadrant, steps + 1)
        end
    end
  end

  defp klingons_attack(game) do
    klingons = find_klingons(game.current_quadrant)

    if Enum.empty?(klingons) do
      game
    else
      total_damage =
        Enum.reduce(klingons, 0, fn {{kx, ky}, _}, acc ->
          distance = calculate_distance({game.sector_x, game.sector_y}, {kx, ky})
          acc + trunc(50 / distance)
        end)

      absorbed = min(total_damage, game.shields)
      hull_damage = total_damage - absorbed

      game
      |> Map.update!(:shields, &max(0, &1 - absorbed))
      |> Map.update!(:energy, &max(0, &1 - hull_damage))
      |> add_message("Klingons attack! Damage: #{total_damage} (#{absorbed} absorbed by shields)")
    end
  end

  defp calculate_distance({x1, y1}, {x2, y2}) do
    :math.sqrt(:math.pow(x2 - x1, 2) + :math.pow(y2 - y1, 2)) |> max(1)
  end

  defp update_galaxy_klingon_count(game, kills) when kills > 0 do
    quadrant_key = {game.quadrant_x, game.quadrant_y}

    Map.update!(game, :galaxy, fn galaxy ->
      Map.update!(galaxy, quadrant_key, fn quadrant_data ->
        Map.update!(quadrant_data, :klingons, &max(0, &1 - kills))
      end)
    end)
  end

  defp update_galaxy_klingon_count(game, _kills), do: game

  defp starbase_adjacent?(game) do
    ship_pos = {game.sector_x, game.sector_y}

    Enum.any?(game.current_quadrant, fn {pos, entity} ->
      entity.type == :starbase and calculate_distance(ship_pos, pos) <= 1.5
    end)
  end

  defp get_adjacent_quadrants(game) do
    for dx <- -1..1, dy <- -1..1, dx != 0 or dy != 0 do
      qx = game.quadrant_x + dx
      qy = game.quadrant_y + dy

      if qx >= 1 and qx <= @galaxy_size and qy >= 1 and qy <= @galaxy_size do
        data = game.galaxy[{qx, qy}]
        {{qx, qy}, data}
      else
        nil
      end
    end
    |> Enum.reject(&is_nil/1)
  end

  defp format_scan(results) do
    Enum.map_join(results, ", ", fn {{x, y}, data} ->
      system = if data.solar_system, do: " #{data.solar_system}", else: ""
      "Q#{x},#{y}: K#{data.klingons} B#{data.starbases} S#{data.stars}#{system}"
    end)
  end

  defp count_entities(quadrant, type) do
    Enum.count(quadrant, fn {_, entity} -> entity.type == type end)
  end

  defp use_energy(game, amount) do
    Map.update!(game, :energy, &max(0, &1 - amount))
  end

  defp use_stardate(game, amount) do
    Map.update!(game, :stardates_remaining, &max(0, &1 - amount))
  end

  defp add_message(game, message) do
    messages = [message | game.messages] |> Enum.take(10)
    Map.put(game, :messages, messages)
  end
end
