import { registerControllers } from "stimulus-vite-helpers"
import { application } from "./application"

const controllers = import.meta.globEager("./**/*_controller.{js,ts}")
registerControllers(application, controllers)
