defmodule UniverseWeb.CalculatorComponents do
  use Phoenix.Component
  use Gettext, backend: UniverseWeb.Gettext

  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField
  attr :errors, :list, default: []
  attr :checked, :boolean
  attr :prompt, :string, default: nil
  attr :options, :list
  attr :multiple, :boolean, default: false
  attr :class, :string, default: nil
  attr :tone, :string, default: "neutral", values: ~w(neutral sky amber)

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error/1))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "checkbox"} = assigns) do
    assigns =
      assign_new(assigns, :checked, fn ->
        Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value])
      end)

    ~H"""
    <div class="mb-3 space-y-2">
      <label class={["inline-flex items-center gap-3", label_classes(@tone)]}>
        <input type="hidden" name={@name} value="false" disabled={@rest[:disabled]} />
        <input
          type="checkbox"
          id={@id}
          name={@name}
          value="true"
          checked={@checked}
          class={[
            "calculator-input size-4 rounded border bg-white/95 text-slate-950 shadow-sm focus:outline-none",
            checkbox_classes(@tone),
            @class
          ]}
          {@rest}
        />
        <span>{@label}</span>
      </label>
      <p :for={msg <- @errors} class={error_classes(@tone)}>{msg}</p>
    </div>
    """
  end

  def input(%{type: "select"} = assigns) do
    ~H"""
    <div class="mb-3 space-y-2">
      <label :if={@label} for={@id} class={label_classes(@tone)}>{@label}</label>
      <select
        id={@id}
        name={@name}
        class={[
          "calculator-input w-full rounded-xl border bg-white/95 px-3 py-2 text-slate-950 shadow-sm transition focus:outline-none focus:ring-2",
          input_classes(@tone),
          @class
        ]}
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt} value="">{@prompt}</option>
        {Phoenix.HTML.Form.options_for_select(@options, @value)}
      </select>
      <p :for={msg <- @errors} class={error_classes(@tone)}>{msg}</p>
    </div>
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div class="mb-3 space-y-2">
      <label :if={@label} for={@id} class={label_classes(@tone)}>{@label}</label>
      <textarea
        id={@id}
        name={@name}
        class={[
          "calculator-input min-h-28 w-full rounded-xl border bg-white/95 px-3 py-2 text-slate-950 shadow-sm transition focus:outline-none focus:ring-2",
          input_classes(@tone),
          @class
        ]}
        {@rest}
      >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      <p :for={msg <- @errors} class={error_classes(@tone)}>{msg}</p>
    </div>
    """
  end

  def input(assigns) do
    ~H"""
    <div class="mb-3 space-y-2">
      <label :if={@label} for={@id} class={label_classes(@tone)}>{@label}</label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          "calculator-input w-full rounded-xl border bg-white/95 px-3 py-2 text-slate-950 shadow-sm transition focus:outline-none focus:ring-2",
          input_classes(@tone),
          @class
        ]}
        {@rest}
      />
      <p :for={msg <- @errors} class={error_classes(@tone)}>{msg}</p>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :row_id, :any, default: nil
  attr :row_click, :any, default: nil
  attr :row_item, :any, default: &Function.identity/1
  attr :tone, :string, default: "neutral", values: ~w(neutral sky amber)

  slot :col, required: true do
    attr :label, :string
  end

  slot :action

  def table(assigns) do
    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class={[
      "calculator-table-shell overflow-hidden rounded-[1.5rem] border shadow-xl",
      table_shell_classes(@tone)
    ]}>
      <table id={@id} class="calculator-table min-w-full text-sm">
        <thead class={table_head_classes(@tone)}>
          <tr>
            <th
              :for={col <- @col}
              class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-[0.2em]"
            >
              {col[:label]}
            </th>
            <th
              :if={@action != []}
              class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-[0.2em]"
            >
              <span class="sr-only">{gettext("Actions")}</span>
            </th>
          </tr>
        </thead>
        <tbody
          id={"#{@id}-body"}
          phx-update={is_struct(@rows, Phoenix.LiveView.LiveStream) && "stream"}
          class={table_body_classes(@tone)}
        >
          <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="border-t border-white/8">
            <td
              :for={col <- @col}
              phx-click={@row_click && @row_click.(row)}
              class={["px-4 py-3 align-top", @row_click && "cursor-pointer"]}
            >
              {render_slot(col, @row_item.(row))}
            </td>
            <td :if={@action != []} class="px-4 py-3 align-top font-semibold">
              <div class="flex gap-4">
                <%= for action <- @action do %>
                  {render_slot(action, @row_item.(row))}
                <% end %>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  defp label_classes("amber"),
    do: "block text-xs font-semibold uppercase tracking-[0.14em] text-amber-100"

  defp label_classes(_tone),
    do: "block text-xs font-semibold uppercase tracking-[0.14em] text-white/90"

  defp input_classes("amber"),
    do:
      "border-amber-300/35 placeholder:text-amber-900/35 focus:border-amber-200 focus:ring-amber-200/35"

  defp input_classes(_tone),
    do:
      "border-slate-300/45 placeholder:text-slate-500 focus:border-slate-400 focus:ring-slate-300/30"

  defp checkbox_classes("amber"),
    do: "border-amber-300/45 focus:ring-amber-200/35"

  defp checkbox_classes(_tone),
    do: "border-slate-300/45 focus:ring-slate-300/30"

  defp error_classes("amber"), do: "text-sm text-amber-100"
  defp error_classes(_tone), do: "text-sm text-rose-100"

  defp table_shell_classes("amber"),
    do: "border-amber-200/15 bg-[rgba(60,23,10,0.72)]"

  defp table_shell_classes(_tone),
    do: "border-white/12 bg-[rgba(17,24,39,0.52)]"

  defp table_head_classes("amber"),
    do: "bg-[rgba(120,53,15,0.88)] text-amber-100"

  defp table_head_classes(_tone),
    do: "bg-[rgba(17,24,39,0.88)] text-white/85"

  defp table_body_classes("amber"), do: "text-amber-50 [&>tr:nth-child(even)]:bg-white/6"
  defp table_body_classes(_tone), do: "text-white/90 [&>tr:nth-child(even)]:bg-black/18"

  defp translate_error({msg, opts}) do
    if count = opts[:count] do
      Gettext.dngettext(UniverseWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(UniverseWeb.Gettext, "errors", msg, opts)
    end
  end
end
