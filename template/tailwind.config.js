const defaultTheme = require("tailwindcss/defaultTheme")

/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./app/views/**/*.{turbo_stream.erb,html.erb}",
    "./app/javascript/controllers/**/*.{js,ts}",
    "./app/components/**/*.html.erb",
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ["Figtree", ...defaultTheme.fontFamily.sans],
      },
    },
  },
  plugins: [require("@tailwindcss/forms")],
}
