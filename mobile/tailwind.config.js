/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./App.tsx", "./src/**/*.{ts,tsx}"],
  presets: [require("nativewind/preset")],
  theme: {
    extend: {
      colors: {
        ink: "#0B0F14",
        panel: "#111821",
        panel2: "#17212B",
        line: "#273442",
        text: "#E8EEF5",
        muted: "#95A3B3",
        blue: "#4F8CFF",
        green: "#44D19D",
        amber: "#F6B84B",
        red: "#F66F6F"
      }
    }
  },
  plugins: []
};
