defmodule UniverseWeb.CockpitLive do
  use UniverseWeb, :live_view

  alias Universe.SpaceGame

  @impl true
  def mount(_params, _session, socket) do
    game = SpaceGame.new_game()

    {:ok,
     socket
     |> assign(:game, game)
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
    game = if at_starbase?(game) do
      game
      |> Map.put(:energy, 3000)  # 100% energy
      |> Map.put(:torpedoes, 10)  # 100% torpedoes
      |> Map.put(:shields, 0)
      |> Map.update!(:messages, fn msgs -> ["Docked! All systems repaired and resupplied." | msgs] |> Enum.take(10) end)
    else
      game
    end

    {:noreply, assign(socket, :game, game)}
  end

  @impl true
  def handle_event("fire_phasers", _params, socket) do
    game = socket.assigns.game

    # Find all Klingon positions in current quadrant
    klingon_positions = game.current_quadrant
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
    <div class="cockpit-container">
      <div class="cockpit-frame">
        <div class="viewport-container">
          <div class="viewport-frame">
            <.viewport game={@game} ship_firing={@ship_firing} targets_hit={@targets_hit} />
          </div>

          <div class="hud-overlay">
            <.hud_top game={@game} />
          </div>
        </div>

        <div class="control-panels">
          <div class="top-row">
            <.systems_controls game={@game} />
            <.status_display game={@game} />
          </div>

          <div class="bottom-row">
            <.weapons_controls selected_power={@selected_power} game={@game} />
            <.message_log messages={@game.messages} />
          </div>
        </div>
      </div>

      <%= if SpaceGame.game_over?(@game) do %>
        <.game_over_modal game={@game} />
      <% end %>
    </div>
    """
  end

  defp viewport(assigns) do
    ~H"""
    <div class="viewport" id="warp-coords-hook" phx-hook="WarpCoords">
      <div class="starfield">
        <%= for _ <- 1..100 do %>
          <div class="star" style={"left: #{:rand.uniform(100)}%; top: #{:rand.uniform(100)}%; animation-delay: #{:rand.uniform(3)}s;"}></div>
        <% end %>
      </div>

      <div class="sector-grid" id="tactical-grid">
        <%= for y <- 1..10 do %>
          <%= for x <- 1..10 do %>
            <div class={"grid-cell #{cell_class(@game, x, y)} #{highlight_class(@game, x, y, @ship_firing, @targets_hit)}"}>
              <%= render_entity(@game, x, y) %>
            </div>
          <% end %>
        <% end %>
      </div>

      <%= if @ship_firing and length(@targets_hit) > 0 do %>
        <.laser_beams ship_x={@game.sector_x} ship_y={@game.sector_y} targets={@targets_hit} />
      <% end %>

      <div class="crosshair"></div>
    </div>
    """
  end

  defp laser_beams(assigns) do
    ~H"""
    <svg class="laser-overlay" viewBox="0 0 100 100" preserveAspectRatio="none">
      <%= for {target_x, target_y} <- @targets do %>
        <line
          class="laser-beam"
          x1={"#{grid_to_percent_x(@ship_x)}%"}
          y1={"#{grid_to_percent_y(@ship_y)}%"}
          x2={"#{grid_to_percent_x(target_x)}%"}
          y2={"#{grid_to_percent_y(target_y)}%"}
        />
      <% end %>
    </svg>
    """
  end

  defp grid_to_percent_x(coord) do
    # X axis: center at 50%, reduce spread further (was 1 square too wide each side)
    # New multiplier ~2.6, base = 50 - 5.5 * 2.6 = 35.7
    35.7 + coord * 2.6
  end

  defp grid_to_percent_y(coord) do
    # Y axis: original calculation works for vertical
    # Grid is 418px in 500px viewport height
    3.8 + coord * 8.4
  end

  defp highlight_class(game, x, y, ship_firing, targets_hit) do
    cond do
      ship_firing and game.sector_x == x and game.sector_y == y -> "ship-firing"
      ship_firing and {x, y} in targets_hit -> "target-hit"
      true -> ""
    end
  end

  defp hud_top(assigns) do
    ~H"""
    <div class="hud-top">
      <div class="hud-left">
        <div class="hud-item">
          <span class="hud-label">QUADRANT</span>
          <span class="hud-value"><%= @game.quadrant_x %>,<%= @game.quadrant_y %></span>
        </div>
        <div class="hud-item">
          <span class="hud-label">SECTOR</span>
          <span class="hud-value"><%= @game.sector_x %>,<%= @game.sector_y %></span>
        </div>
        <div class="hud-tactical">
          <div class="hud-tactical-title">TACTICAL</div>
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
                    <%= mini_quadrant_info(@game, x, y) %>
                  <% end %>
                </button>
              <% end %>
            <% end %>
          </div>
        </div>
      </div>

      <div class="hud-center">
        <div class="ship-name">USS ENTERPRISE</div>
      </div>

      <div class="hud-right">
        <div class="hud-item">
          <span class="hud-label">KLINGONS</span>
          <span class="hud-value alert"><%= @game.klingons_remaining %></span>
        </div>
        <div class="hud-item">
          <span class="hud-label">STARDATES</span>
          <span class="hud-value"><%= :erlang.float_to_binary(@game.stardates_remaining * 1.0, decimals: 1) %></span>
        </div>
        <div class="hud-item">
          <span class="hud-label">SCORE</span>
          <span class="hud-value score"><%= @game.score %></span>
        </div>
        <div class="hud-navigation">
          <div class="nav-grid">
            <button phx-click="move" phx-value-direction="up" class="nav-btn nav-up">↑</button>
            <div class="nav-row">
              <button phx-click="move" phx-value-direction="left" class="nav-btn nav-left">←</button>
              <div class="nav-center">MOVE</div>
              <button phx-click="move" phx-value-direction="right" class="nav-btn nav-right">→</button>
            </div>
            <button phx-click="move" phx-value-direction="down" class="nav-btn nav-down">↓</button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp weapons_controls(assigns) do
    ~H"""
    <div class="panel-section weapons">
      <h3 class="panel-title">WEAPONS</h3>

      <div class="weapons-grid">
        <div class="weapon-control phaser-control">
          <label class="control-label">Phaser Power</label>
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
          <span class="power-value"><%= @selected_power %></span>
          <button phx-click="fire_phasers" class="fire-btn phaser-btn">FIRE PHASERS</button>
        </div>

        <div class="weapon-control torpedo-control">
          <label class="control-label">Torpedoes: <%= @game.torpedoes %></label>
          <div class="torpedo-grid">
            <button phx-click="fire_torpedo" phx-value-direction="up" class="torpedo-btn">↑</button>
            <div class="torpedo-row">
              <button phx-click="fire_torpedo" phx-value-direction="left" class="torpedo-btn">←</button>
              <button phx-click="fire_torpedo" phx-value-direction="right" class="torpedo-btn">→</button>
            </div>
            <button phx-click="fire_torpedo" phx-value-direction="down" class="torpedo-btn">↓</button>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp status_display(assigns) do
    ~H"""
    <div class="panel-section status-display">
      <h3 class="panel-title">STATUS</h3>
      <div class="status-row">
        <div class="status-bar">
          <span class="status-label">ENERGY</span>
          <div class="status-bar-content">
            <div class="bar-container">
              <div class="bar energy-bar" style={"width: #{energy_percent(@game)}%"}></div>
            </div>
            <span class="status-value"><%= @game.energy %></span>
          </div>
        </div>

        <div class="status-bar">
          <span class="status-label">SHIELDS</span>
          <div class="status-bar-content">
            <div class="bar-container">
              <div class="bar shield-bar" style={"width: #{shield_percent(@game)}%"}></div>
            </div>
            <span class="status-value"><%= @game.shields %></span>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp message_log(assigns) do
    ~H"""
    <div class="message-log">
      <h3 class="panel-title">SHIP'S LOG</h3>
      <div class="messages">
        <%= for message <- Enum.take(@messages, 8) do %>
          <div class="message"><span class="message-prompt">></span> <%= message %></div>
        <% end %>
      </div>
    </div>
    """
  end

  defp systems_controls(assigns) do
    at_starbase = at_starbase?(assigns.game)
    near_starbase = near_starbase?(assigns.game)
    assigns = assign(assigns, :at_starbase, at_starbase) |> assign(:near_starbase, near_starbase)

    ~H"""
    <div class="panel-section systems">
      <h3 class="panel-title">SYSTEMS</h3>
      <div class="systems-row">
        <div class="warp-control">
          <label class="control-label">WARP DRIVE</label>
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
              />
              <button type="submit" class="warp-btn">ENGAGE</button>
            </div>
          </.form>
        </div>
        <%= if @at_starbase do %>
          <div class="docked-indicator">
            <span class="dock-icon">🏭</span> DOCKED
          </div>
        <% else %>
          <%= if @near_starbase do %>
            <button phx-click="dock" class="system-btn">DOCK AT STARBASE</button>
          <% end %>
        <% end %>
        <div class="shield-control">
          <label class="control-label">Shield Level</label>
          <.form for={%{}} phx-submit="raise_shields" class="shield-form">
            <input
              type="number"
              min="0"
              max={@game.energy + @game.shields}
              value={@game.shields}
              name="amount"
              class="shield-input"
              phx-blur="raise_shields"
            />
          </.form>
        </div>
      </div>
    </div>
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
        <h2 class="modal-title"><%= if @status == :won, do: "VICTORY!", else: "MISSION FAILED" %></h2>
        <p class="modal-message"><%= @message %></p>
        <div class="modal-stats">
          <div>Final Score: <strong><%= @game.score %></strong></div>
          <div>Klingons Destroyed: <strong><%= count_killed(@game) %></strong></div>
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
            Phoenix.HTML.raw(~s(<div class="docked-ship">◆</div><div class="docked-starbase">B</div>))
          _ ->
            Phoenix.HTML.raw(~s(<div class="ship">◆</div>))
        end

      true ->
        case Map.get(game.current_quadrant, {x, y}) do
          %{type: :klingon, health: health} ->
            health_percent = health / 100
            Phoenix.HTML.raw(~s(<div class="klingon-container"><div class="klingon-shield" style="width: #{health_percent * 30}px; height: #{health_percent * 30}px;"></div><div class="klingon">K</div></div>))
          %{type: :starbase} -> Phoenix.HTML.raw(~s(<div class="starbase">B</div>))
          %{type: :star} -> Phoenix.HTML.raw(~s(<div class="star-entity">*</div>))
          _ -> ""
        end
    end
  end

  defp mini_cell_class(game, x, y) do
    data = game.galaxy[{x, y}]
    cond do
      data.klingons > 0 -> "has-klingons"
      data.starbases > 0 -> "has-starbase"
      true -> ""
    end
  end

  defp mini_quadrant_info(game, x, y) do
    data = game.galaxy[{x, y}]
    if data.klingons > 0, do: "K", else: ""
  end

  defp energy_percent(game), do: min(100, trunc(game.energy / 30))
  defp shield_percent(game), do: min(100, trunc(game.shields / 10))

  defp count_killed(game) do
    initial_klingons = Enum.reduce(game.galaxy, 0, fn {_, data}, acc -> acc + data.klingons end)
    initial_klingons - game.klingons_remaining
  end
end
