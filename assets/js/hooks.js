let Hooks = {}

Hooks.WarpCoords = {
  mounted() {
    console.log("WarpCoords hook mounted!")
    
    this.handleEvent("update_warp_inputs", ({target_qx, target_qy}) => {
      console.log("Received update_warp_inputs:", {target_qx, target_qy})
      
      const qxInput = document.getElementById('warp-qx-input')
      const qyInput = document.getElementById('warp-qy-input')
      
      console.log("Found inputs:", {qxInput, qyInput})
      
      if (qxInput) {
        qxInput.value = target_qx
        console.log("Set qx input to:", target_qx)
      }
      if (qyInput) {
        qyInput.value = target_qy
        console.log("Set qy input to:", target_qy)
      }
    })
  }
}

export default Hooks
