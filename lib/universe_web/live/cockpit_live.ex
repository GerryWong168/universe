defmodule UniverseWeb.CockpitLive do
  use UniverseWeb, :live_view

  alias Universe.SpaceGame

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:game, SpaceGame.new_game())
     |> assign(:selected_power, 100)
     |> assign(:selected_direction, "up")
     |> assign(:view_mode, "tactical")
     |> assign(:ship_firing, false)
     |> assign(:targets_hit, [])}
  end

  @impl true
  def handle_event("move", %{"direction" => direction}, socket) do
    game = SpaceGame.move_ship(socket.assigns.game, direction)

    # Check if ship is now on starbase and auto-resupply
    game =
      if at_starbase?(game) do
        game
        # 100% energy
        |> Map.put(:energy, 3000)
        # 100% torpedoes
        |> Map.put(:torpedoes, 10)
        |> Map.put(:shields, 0)
        |> Map.update!(:messages, fn msgs ->
          ["Docked! All systems repaired and resupplied." | msgs] |> Enum.take(10)
        end)
      else
        game
      end

    {:noreply, assign(socket, :game, game)}
  end

  @impl true
  def handle_event("fire_phasers", _params, socket) do
    game = socket.assigns.game

    # Find all Klingon positions in current quadrant
    klingon_positions =
      game.current_quadrant
      |> Enum.filter(fn {_, entity} -> entity.type == :klingon end)
      |> Enum.map(fn {pos, _} -> pos end)

    # Update game state
    updated_game = SpaceGame.fire_phasers(game, socket.assigns.selected_power)

    # Schedule clearing the highlights after 1.5 seconds
    Process.send_after(self(), :clear_phaser_highlights, 1500)

    {:noreply,
     socket
     |> assign(:game, updated_game)
     |> assign(:ship_firing, true)
     |> assign(:targets_hit, klingon_positions)}
  end

  @impl true
  def handle_event("navigate_by_click", %{"x" => x, "y" => y}, socket) do
    {x_int, _} = Integer.parse(x)
    {y_int, _} = Integer.parse(y)

    direction =
      cond do
        y_int < 4 -> "up"
        y_int > 7 -> "down"
        x_int < 4 -> "left"
        x_int > 7 -> "right"
        true -> nil
      end

    if direction do
      game = SpaceGame.move_ship(socket.assigns.game, direction)

      # Check if ship is now on starbase and auto-resupply
      game =
        if at_starbase?(game) do
          game
          # 100% energy
          |> Map.put(:energy, 3000)
          # 100% torpedoes
          |> Map.put(:torpedoes, 10)
          |> Map.put(:shields, 0)
          |> Map.update!(:messages, fn msgs ->
            ["Docked! All systems repaired and resupplied." | msgs] |> Enum.take(10)
          end)
        else
          game
        end

      {:noreply, assign(socket, :game, game)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("fire_torpedo", %{"direction" => direction}, socket) do
    game = SpaceGame.fire_torpedo(socket.assigns.game, direction)
    {:noreply, assign(socket, :game, game)}
  end

  @impl true
  def handle_event("short_scan", _params, socket) do
    game = SpaceGame.short_range_scan(socket.assigns.game)
    {:noreply, assign(socket, :game, game)}
  end

  @impl true
  def handle_event("long_scan", _params, socket) do
    game = SpaceGame.long_range_scan(socket.assigns.game)
    {:noreply, assign(socket, :game, game)}
  end

  @impl true
  def handle_event("engage_warp", params, socket) do
    # Get target coordinates from form inputs
    target_qx = params["target_qx"] || to_string(socket.assigns.game.quadrant_x)
    target_qy = params["target_qy"] || to_string(socket.assigns.game.quadrant_y)

    {target_qx_int, _} = Integer.parse(target_qx)
    {target_qy_int, _} = Integer.parse(target_qy)

    game = SpaceGame.warp_to_quadrant(socket.assigns.game, target_qx_int, target_qy_int)
    {:noreply, assign(socket, :game, game)}
  end

  @impl true
  def handle_event("dock", _params, socket) do
    game = SpaceGame.dock_at_starbase(socket.assigns.game)
    {:noreply, assign(socket, :game, game)}
  end

  @impl true
  def handle_event("recharge_at_sol", _params, socket) do
    game = SpaceGame.recharge_at_sol(socket.assigns.game)
    {:noreply, assign(socket, :game, game)}
  end

  @impl true
  def handle_event("go_home", _params, socket) do
    {:noreply, push_navigate(socket, to: ~p"/tools")}
  end

  @impl true
  def handle_event("restore_game_state", params, socket) do
    {:noreply,
     socket
     |> assign(:game, restore_game(params))
     |> assign(:selected_power, restore_selected_power(params))
     |> assign(:ship_firing, false)
     |> assign(:targets_hit, [])}
  end

  @impl true
  def handle_event("raise_shields", params, socket) do
    amount = params["amount"] || params["value"]
    {shield_amount, _} = Integer.parse(amount)
    game = SpaceGame.raise_shields(socket.assigns.game, shield_amount)
    {:noreply, assign(socket, :game, game)}
  end

  @impl true
  def handle_event("set_warp_coords_from_map", %{"target" => target}, socket) do
    # Get coordinates from the clicked element's data attributes
    {qx, ""} = Integer.parse(target["dataset"]["qx"] || "1")
    {qy, ""} = Integer.parse(target["dataset"]["qy"] || "1")

    IO.inspect("set_warp_coords_from_map received: #{qx}, #{qy}")

    # Update the warp input fields with the clicked quadrant coordinates
    {:noreply,
     socket
     |> push_event("update_warp_inputs", %{target_qx: qx, target_qy: qy})}
  end

  @impl true
  def handle_event("set_warp_coords", %{"qx" => qx, "qy" => qy}, socket) do
    IO.inspect("set_warp_coords received: #{qx}, #{qy}")
    # Update the warp input fields with the clicked quadrant coordinates
    {:noreply,
     socket
     |> push_event("update_warp_inputs", %{target_qx: qx, target_qy: qy})}
  end

  @impl true
  def handle_event("set_power", %{"power" => power}, socket) do
    {power_val, _} = Integer.parse(power)
    {:noreply, assign(socket, :selected_power, power_val)}
  end

  @impl true
  def handle_event("new_game", _params, socket) do
    game = SpaceGame.new_game()

    {:noreply,
     socket
     |> assign(:game, game)
     |> assign(:ship_firing, false)
     |> assign(:targets_hit, [])}
  end

  @impl true
  def handle_info(:clear_phaser_highlights, socket) do
    {:noreply,
     socket
     |> assign(:ship_firing, false)
     |> assign(:targets_hit, [])}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} variant={:cockpit}>
      <div
        class="cockpit-container"
        id="cockpit-dashboard"
        aria-label="Cockpit dashboard"
        phx-hook="CockpitShortcuts"
        data-cockpit-game-state={SpaceGame.serialize_state(@game)}
        data-selected-power={@selected_power}
      >
        <div class="cockpit-frame">
          <div class={["tactical-stage", SpaceGame.at_sol?(@game) && "has-sol-actions"]}>
            <section
              id="tactical-view-panel"
              class="viewport-container dashboard-panel"
              aria-labelledby="tactical-view-panel-label"
            >
              <.panel_label id="tactical-view-panel-label" name="Tactical View" />
              <div class="viewport-frame">
                <.viewport game={@game} ship_firing={@ship_firing} targets_hit={@targets_hit} />
              </div>

              <div class="hud-overlay"></div>
            </section>

            <%= if SpaceGame.at_sol?(@game) do %>
              <.sol_actions_menu />
            <% end %>
          </div>

          <div class="control-panels">
            <div class="top-row">
              <.systems_and_weapons_controls game={@game} selected_power={@selected_power} />
              <.status_display game={@game} />
            </div>

            <div class="bottom-row">
              <.message_log
                messages={@game.messages}
                klingons={@game.klingons_remaining}
                stardates={@game.stardates_remaining}
              />
            </div>
          </div>
        </div>

        <%= if SpaceGame.game_over?(@game) do %>
          <.game_over_modal game={@game} />
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  attr :id, :string, required: true
  attr :name, :string, required: true

  defp panel_label(assigns) do
    ~H"""
    <div class="panel-reference-label" id={@id} data-panel-name={@name}>
      {@name}
    </div>
    """
  end

  defp sol_actions_menu(assigns) do
    ~H"""
    <aside
      id="sol-actions-panel"
      class="sol-actions-panel dashboard-panel"
      aria-labelledby="sol-actions-panel-label"
    >
      <.panel_label id="sol-actions-panel-label" name="Sol" />
      <div class="sol-actions-content">
        <div class="sol-actions-kicker">Home System</div>
        <div class="sol-actions-title">Sol</div>
        <p class="sol-actions-copy">
          You are landed on the Sol system at quadrant 3,3 sector 5,5.
        </p>
        <button
          type="button"
          id="sol-recharge-button"
          class="system-btn sol-action-btn"
          phx-click="recharge_at_sol"
        >
          Recharge
        </button>
        <button
          type="button"
          id="sol-go-home-button"
          class="system-btn sol-action-btn"
          phx-click="go_home"
        >
          Go Home
        </button>
      </div>
    </aside>
    """
  end

  defp viewport(assigns) do
    ~H"""
    <div class="viewport" id="warp-coords-hook" phx-hook="WarpCoords">
      <div class="starfield">
        <%= for _ <- 1..100 do %>
          <div
            class="star"
            style={"left: #{:rand.uniform(100)}%; top: #{:rand.uniform(100)}%; animation-delay: #{:rand.uniform(3)}s;"}
          >
          </div>
        <% end %>
      </div>

      <div class="sector-grid" id="tactical-grid">
        <%= for y <- 1..10 do %>
          <%= for x <- 1..10 do %>
            <div
              class={"grid-cell #{cell_class(@game, x, y)} #{highlight_class(@game, x, y, @ship_firing, @targets_hit)}"}
              data-sector-x={x}
              data-sector-y={y}
              phx-click="navigate_by_click"
              phx-value-x={x}
              phx-value-y={y}
            >
              {render_entity(@game, x, y)}
            </div>
          <% end %>
        <% end %>

        <svg id="laser-overlay" class="laser-overlay" phx-update="ignore"></svg>
      </div>

      <div class="crosshair"></div>
    </div>
    """
  end

  defp highlight_class(game, x, y, ship_firing, targets_hit) do
    cond do
      ship_firing and game.sector_x == x and game.sector_y == y -> "ship-firing"
      ship_firing and {x, y} in targets_hit -> "target-hit"
      true -> ""
    end
  end

  defp systems_and_weapons_controls(assigns) do
    at_starbase = at_starbase?(assigns.game)
    near_starbase = near_starbase?(assigns.game)
    assigns = assign(assigns, :at_starbase, at_starbase) |> assign(:near_starbase, near_starbase)

    ~H"""
    <section
      id="weapons-control-panel"
      class="panel-section systems-weapons dashboard-panel"
      aria-labelledby="weapons-control-panel-label"
    >
      <.panel_label id="weapons-control-panel-label" name="Weapons Control" />

      <div class="widgets-row">
        <div
          id="phaser-bank-panel"
          class="widget-phasers dashboard-subpanel"
          data-panel-name="Phaser Bank"
          aria-labelledby="phaser-bank-panel-label"
        >
          <div class="widget-title" id="phaser-bank-panel-label">Phaser Bank</div>
          <label class="control-label">Power</label>
          <.form for={%{}} phx-change="set_power" class="power-form">
            <input
              type="range"
              min="50"
              max="500"
              value={@selected_power}
              name="power"
              class="power-slider"
            />
          </.form>
          <span class="power-value">{@selected_power}</span>
          <button phx-click="fire_phasers" class="fire-btn phaser-btn">FIRE</button>
        </div>

        <div
          id="photon-torpedoes-panel"
          class="widget-torpedoes dashboard-subpanel"
          data-panel-name="Photon Torpedoes"
          aria-labelledby="photon-torpedoes-panel-label"
        >
          <div class="widget-title" id="photon-torpedoes-panel-label">Photon Torpedoes</div>
          <label class="control-label">Count: {@game.torpedoes}</label>
          <div class="torpedo-grid">
            <button phx-click="fire_torpedo" phx-value-direction="up" class="torpedo-btn">↑</button>
            <div class="torpedo-row">
              <button phx-click="fire_torpedo" phx-value-direction="left" class="torpedo-btn">
                ←
              </button>
              <button phx-click="fire_torpedo" phx-value-direction="right" class="torpedo-btn">
                →
              </button>
            </div>

            <button phx-click="fire_torpedo" phx-value-direction="down" class="torpedo-btn">↓</button>
          </div>
        </div>
      </div>

      <div class="dock-section">
        <%= if @at_starbase do %>
          <div class="docked-indicator"><span class="dock-icon">🏭</span> DOCKED</div>
        <% else %>
          <%= if @near_starbase do %>
            <button phx-click="dock" class="system-btn">DOCK AT STARBASE</button>
          <% end %>
        <% end %>
      </div>
    </section>
    """
  end

  defp status_display(assigns) do
    ~H"""
    <section
      id="navigation-systems-panel"
      class="panel-section status-display dashboard-panel"
      aria-labelledby="navigation-systems-panel-label"
    >
      <.panel_label id="navigation-systems-panel-label" name="Navigation & Systems" />

      <div class="widgets-row">
        <div
          id="long-range-scanner-panel"
          class="widget-tactical dashboard-subpanel"
          data-panel-name="Long-Range Scanner"
          aria-labelledby="long-range-scanner-panel-label"
        >
          <div class="widget-title" id="long-range-scanner-panel-label">Long-Range Scanner</div>

          <div class="hud-mini-map">
            <%= for y <- 1..8 do %>
              <%= for x <- 1..8 do %>
                <button
                  class={"hud-mini-cell #{mini_cell_class(@game, x, y)}"}
                  phx-click="set_warp_coords"
                  phx-value-qx={x}
                  phx-value-qy={y}
                  type="button"
                >
                  <%= if x == @game.quadrant_x and y == @game.quadrant_y do %>
                    <span class="hud-mini-ship">E</span>
                  <% else %>
                    {mini_quadrant_info(@game, x, y)}
                  <% end %>
                </button>
              <% end %>
            <% end %>
          </div>

          <div class="warp-controls">
            <.form for={%{}} phx-submit="engage_warp" class="warp-form" id="warp-form">
              <div class="warp-inputs">
                <input
                  type="number"
                  min="1"
                  max="8"
                  value={@game.quadrant_x}
                  name="target_qx"
                  class="warp-input"
                  placeholder="X"
                  id="warp-qx-input"
                />
                <input
                  type="number"
                  min="1"
                  max="8"
                  value={@game.quadrant_y}
                  name="target_qy"
                  class="warp-input"
                  placeholder="Y"
                  id="warp-qy-input"
                /> <button type="submit" class="warp-btn">ENGAGE</button>
              </div>
            </.form>
          </div>
        </div>

        <div
          id="ship-status-panel"
          class="widget-status dashboard-subpanel"
          data-panel-name="Ship Status"
          aria-labelledby="ship-status-panel-label"
        >
          <div class="widget-title" id="ship-status-panel-label">Ship Status</div>

          <div class="status-row">
            <div class="status-bar">
              <span class="status-label">QUADRANT</span>
              <div class="status-bar-content">
                <span class="status-value">{@game.quadrant_x},{@game.quadrant_y}</span>
              </div>
            </div>

            <div class="status-bar">
              <span class="status-label">SECTOR</span>
              <div class="status-bar-content">
                <span class="status-value">{@game.sector_x},{@game.sector_y}</span>
              </div>
            </div>
          </div>

          <div class="status-row">
            <div class="status-bar">
              <span class="status-label">ENERGY</span>
              <div class="status-bar-content">
                <div class="bar-container">
                  <div class="bar energy-bar" style={"width: #{energy_percent(@game)}%"}></div>
                </div>
                <span class="status-value">{@game.energy}</span>
              </div>
            </div>

            <div class="status-bar">
              <span class="status-label">SHIELDS</span>
              <div class="status-bar-content">
                <.form for={%{}} phx-change="raise_shields" class="shield-form">
                  <input
                    type="range"
                    min="0"
                    max="1000"
                    value={@game.shields}
                    name="amount"
                    class="shield-slider"
                  />
                </.form>
                <span class="status-value">{@game.shields}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
    """
  end

  defp message_log(assigns) do
    ~H"""
    <section
      id="mission-log-panel"
      class="message-log dashboard-panel"
      aria-labelledby="mission-log-panel-label"
    >
      <.panel_label id="mission-log-panel-label" name="Mission Log" />
      <h3 class="panel-title">
        KLINGONS: {@klingons} | STARDATES: {:erlang.float_to_binary(@stardates * 1.0,
          decimals: 1
        )}
      </h3>

      <div class="messages">
        <%= for message <- Enum.take(@messages, 8) do %>
          <div class="message"><span class="message-prompt">></span> {message}</div>
        <% end %>
      </div>
    </section>
    """
  end

  defp at_starbase?(game) do
    ship_pos = {game.sector_x, game.sector_y}

    case Map.get(game.current_quadrant, ship_pos) do
      %{type: :starbase} -> true
      _ -> false
    end
  end

  defp near_starbase?(game) do
    ship_pos = {game.sector_x, game.sector_y}

    Enum.any?(game.current_quadrant, fn {pos, entity} ->
      entity.type == :starbase and distance(ship_pos, pos) <= 1.5
    end)
  end

  defp distance({x1, y1}, {x2, y2}) do
    :math.sqrt(:math.pow(x2 - x1, 2) + :math.pow(y2 - y1, 2))
  end

  defp game_over_modal(assigns) do
    {status, message} = SpaceGame.game_status(assigns.game)

    assigns = assign(assigns, :status, status) |> assign(:message, message)

    ~H"""
    <div class="modal-overlay">
      <div class={"game-over-modal #{@status}"}>
        <h2 class="modal-title">{if @status == :won, do: "VICTORY!", else: "MISSION FAILED"}</h2>

        <p class="modal-message">{@message}</p>

        <div class="modal-stats">
          <div>Final Score: <strong>{@game.score}</strong></div>

          <div>Klingons Destroyed: <strong>{count_killed(@game)}</strong></div>
        </div>
        <button phx-click="new_game" class="new-game-btn">NEW MISSION</button>
      </div>
    </div>
    """
  end

  defp cell_class(game, x, y) do
    cond do
      game.sector_x == x and game.sector_y == y -> "ship-cell"
      Map.has_key?(game.current_quadrant, {x, y}) -> "entity-cell"
      true -> ""
    end
  end

  defp render_entity(game, x, y) do
    cond do
      game.sector_x == x and game.sector_y == y ->
        # Check if docked (on same square as starbase)
        case Map.get(game.current_quadrant, {x, y}) do
          %{type: :starbase} ->
            Phoenix.HTML.raw(
              ~s(<div class="docked-ship">◆</div><div class="docked-starbase">B</div>)
            )

          _ ->
            Phoenix.HTML.raw(~s(<div class="ship">◆</div>))
        end

      true ->
        case Map.get(game.current_quadrant, {x, y}) do
          %{type: :klingon, health: health} ->
            health_percent = health / 100

            Phoenix.HTML.raw(
              ~s(<div class="klingon-container"><div class="klingon-shield" style="width: #{health_percent * 30}px; height: #{health_percent * 30}px;"></div><div class="klingon">K</div></div>)
            )

          %{type: :starbase} ->
            Phoenix.HTML.raw(~s(<div class="starbase">B</div>))

          %{type: :solar_system, name: name} ->
            Phoenix.HTML.raw(~s(<div class="solar-system">#{name}</div>))

          %{type: :star} ->
            Phoenix.HTML.raw(~s(<div class="star-entity">*</div>))

          _ ->
            ""
        end
    end
  end

  defp mini_cell_class(game, x, y) do
    data = game.galaxy[{x, y}]

    cond do
      data.solar_system -> "has-sol"
      data.klingons > 0 -> "has-klingons"
      data.starbases > 0 -> "has-starbase"
      true -> ""
    end
  end

  defp mini_quadrant_info(game, x, y) do
    data = game.galaxy[{x, y}]

    cond do
      data.solar_system -> "Sol"
      data.klingons > 0 -> "K"
      true -> ""
    end
  end

  defp energy_percent(game), do: min(100, trunc(game.energy / 30))

  defp count_killed(game) do
    initial_klingons = Enum.reduce(game.galaxy, 0, fn {_, data}, acc -> acc + data.klingons end)
    initial_klingons - game.klingons_remaining
  end

  defp restore_game(%{"cockpit_game_state" => encoded})
       when is_binary(encoded) and encoded != "" do
    case SpaceGame.deserialize_state(encoded) do
      {:ok, game} -> game
      :error -> SpaceGame.new_game()
    end
  end

  defp restore_game(_connect_params), do: SpaceGame.new_game()

  defp restore_selected_power(%{"cockpit_selected_power" => power}) when is_binary(power) do
    case Integer.parse(power) do
      {value, ""} -> value
      _ -> 100
    end
  end

  defp restore_selected_power(_connect_params), do: 100
end
