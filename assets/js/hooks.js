let Hooks = {}

Hooks.WarpCoords = {
  mounted() {
    this.handleEvent("update_warp_inputs", ({target_qx, target_qy}) => {
      const qxInput = document.getElementById('warp-qx-input')
      const qyInput = document.getElementById('warp-qy-input')

      if (qxInput) {
        qxInput.value = target_qx
      }
      if (qyInput) {
        qyInput.value = target_qy
      }
    })

    this.handleViewportResize = () => {
      this.schedulePhaserBeamDraw()
    }

    window.addEventListener("resize", this.handleViewportResize)

    const tacticalGrid = this.el.querySelector("#tactical-grid")

    if (tacticalGrid && window.ResizeObserver) {
      this.phaserResizeObserver = new ResizeObserver(() => this.schedulePhaserBeamDraw())
      this.phaserResizeObserver.observe(tacticalGrid)
    }

    this.schedulePhaserBeamDraw()
  },

  updated() {
    this.schedulePhaserBeamDraw()
  },

  destroyed() {
    window.removeEventListener("resize", this.handleViewportResize)

    if (this.phaserResizeObserver) {
      this.phaserResizeObserver.disconnect()
    }

    if (this.phaserBeamFrame) {
      cancelAnimationFrame(this.phaserBeamFrame)
    }
  },

  schedulePhaserBeamDraw() {
    if (this.phaserBeamFrame) {
      cancelAnimationFrame(this.phaserBeamFrame)
    }

    this.phaserBeamFrame = requestAnimationFrame(() => {
      this.phaserBeamFrame = null
      this.drawPhaserBeams()
    })
  },

  drawPhaserBeams() {
    const overlay = this.el.querySelector("#laser-overlay")

    if (!overlay) {
      return
    }

    const shipCell = this.el.querySelector(".grid-cell.ship-firing")
    const targetCells = Array.from(this.el.querySelectorAll(".grid-cell.target-hit"))

    overlay.innerHTML = ""

    if (!shipCell || targetCells.length === 0) {
      return
    }

    const overlayRect = overlay.getBoundingClientRect()
    const width = overlayRect.width
    const height = overlayRect.height

    if (width <= 0 || height <= 0) {
      return
    }

    const shipCenter = this.sectorCenter(shipCell, width, height)

    overlay.setAttribute("width", width)
    overlay.setAttribute("height", height)
    overlay.setAttribute("viewBox", `0 0 ${width} ${height}`)
    overlay.setAttribute("preserveAspectRatio", "none")

    for (const targetCell of targetCells) {
      const targetCenter = this.sectorCenter(targetCell, width, height)
      const line = document.createElementNS("http://www.w3.org/2000/svg", "line")

      line.setAttribute("class", "laser-beam")
      line.setAttribute("x1", shipCenter.x)
      line.setAttribute("y1", shipCenter.y)
      line.setAttribute("x2", targetCenter.x)
      line.setAttribute("y2", targetCenter.y)

      overlay.appendChild(line)
    }
  },

  sectorCenter(cell, overlayWidth, overlayHeight) {
    const sectorX = Number(cell.dataset.sectorX)
    const sectorY = Number(cell.dataset.sectorY)

    if (Number.isFinite(sectorX) && Number.isFinite(sectorY)) {
      return {
        x: ((sectorX - 0.5) / 10) * overlayWidth,
        y: ((sectorY - 0.5) / 10) * overlayHeight,
      }
    }

    const overlayRect = cell.closest("#tactical-grid")?.getBoundingClientRect()
    const cellRect = cell.getBoundingClientRect()

    if (!overlayRect) {
      return {x: 0, y: 0}
    }

    return {
      x: cellRect.left - overlayRect.left + (cellRect.width / 2),
      y: cellRect.top - overlayRect.top + (cellRect.height / 2),
    }
  }
}

Hooks.CockpitShortcuts = {
  mounted() {
    this.handlePageHide = () => {
      this.persistCockpitState()
    }

    this.handleGoHomeShortcut = (event) => {
      const key = event.key?.toLowerCase()

      if (event.ctrlKey && event.altKey && key === "h") {
        event.preventDefault()
        this.persistCockpitState()
        this.pushEvent("go_home", {})
      }
    }

    window.addEventListener("keydown", this.handleGoHomeShortcut)
    window.addEventListener("pagehide", this.handlePageHide)
    window.addEventListener("beforeunload", this.handlePageHide)
    this.restoreOrPersistCockpitState()
  },

  updated() {
    this.persistCockpitState()
  },

  destroyed() {
    window.removeEventListener("keydown", this.handleGoHomeShortcut)
    window.removeEventListener("pagehide", this.handlePageHide)
    window.removeEventListener("beforeunload", this.handlePageHide)
  },

  restoreOrPersistCockpitState() {
    const gameState = this.readStoredValue("universe:cockpit_game_state")
    const selectedPower = this.readStoredValue("universe:cockpit_selected_power")

    if (gameState) {
      this.pushEvent("restore_game_state", {
        cockpit_game_state: gameState,
        cockpit_selected_power: selectedPower || "",
      })

      return
    }

    this.persistCockpitState()
  },

  persistCockpitState() {
    try {
      const gameState = this.el.dataset.cockpitGameState
      const selectedPower = this.el.dataset.selectedPower

      if (gameState) {
        this.writeStoredValue("universe:cockpit_game_state", gameState)
      }

      if (selectedPower) {
        this.writeStoredValue("universe:cockpit_selected_power", selectedPower)
      }
    } catch (_error) {
      // Ignore storage failures and keep gameplay functional.
    }
  },

  readStoredValue(key) {
    try {
      return window.localStorage.getItem(key) || window.sessionStorage.getItem(key)
    } catch (_error) {
      return null
    }
  },

  writeStoredValue(key, value) {
    try {
      window.localStorage.setItem(key, value)
    } catch (_error) {
      // Keep going so we still try sessionStorage below.
    }

    try {
      window.sessionStorage.setItem(key, value)
    } catch (_error) {
      // Ignore storage failures and keep gameplay functional.
    }
  }
}

export default Hooks
