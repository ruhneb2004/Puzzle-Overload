# 🧠 Puzzle Overload

Welcome to **Puzzle Overload**, a Web3-based puzzle game that blends mental agility with blockchain rewards. Compete with others to solve increasingly difficult puzzles and win the pot. The faster, the smarter, the more you win.

<img width="1440" height="778" alt="Screenshot 2025-08-02 at 8 35 06 PM" src="https://github.com/user-attachments/assets/5034128e-32b5-4898-93a5-86be679e7333" />

## 🚀 Live Demo

[🔗 Live Website](https://puzzle-overload.vercel.app)  
[📦 Smart Contracts Repo (Foundry)](https://github.com/ruhneb2004/Puzzle-Overload)

---

## 🕹️ Gameplay Overview

- The game runs for **1 day**.
- Players must pay an **entry fee of 0.0001 ETH**.
- The player who **solves the most levels first** wins the game.
- Each level increases in complexity:
  - 🧩 Level 1 → 3x3 puzzle
  - 🧩 Level 2 → 4x4 puzzle
  - 🧩 Level 3 → 5x5 puzzle  
  ... and so on.

It’s a race against time, logic, and everyone else. Are you up for the overload?

---

---

## 🛠️ Installation & Local Setup (continued)

```bash
# Inside your repo
npm install

# Start the frontend locally
npm run dev
```

then copy the .env.copy to .env and then fill the variables 

Once the dev server is up, open your browser to:

**http://localhost:3000**

And you’re good to go, start puzzling and linking your wallet. 🎉

---

## 🎮 True Web3 Fun: Game Logic & Leaderboard

This isn’t just any puzzle game:

- ⏳ **1-day tournament mode**  
- 💎 Pay **0.0001 ETH** to enter
- 🧩 Progress through levels: 3×3 → 4×4 → 5×5 → … and beyond
- 🥇 Highest level solved **first** wins the round
- 🔄 Smart contract updates leaderboard and handles prize distribution automatically via `PuzzleCompleted` events

Players race the clock, the logic, and each other. Let's see who cracks the chaos fastest.

---

## 🤝 Built With These Tools

| Layer        | Stack & Packages                           |
|--------------|--------------------------------------------|
| Smart Contracts | **Foundry + Forge**                     |
| Frontend     | **Next.js 15**, **TailwindCSS**, React     |
| Blockchain   | `ethers`, `wagmi`, `viem`, `rainbowkit`    |
| Networking   | `@tanstack/react-query`, `axios`          |
| UI Feedback  | `react-toastify`                           |

---

## 🌿 Dir Structure (A Refresher)

```
Puzzle-Overload/
├── public/              # Game images and static assets
├── src/
│   ├── app/             # UI & frontend logic
│   └── contracts/       # Compiled ABIs/types for frontend use
├── foundry/             # Solidity contracts, tests, deploy scripts
├── .vercelignore        # Excludes `foundry/` from Vercel deploy
├── vercel.json          # Vercel build + ignore configuration
├── package.json
└── README.md            # ← You’re here!
```

The `foundry/` directory is **development-only** and isn’t shipped with your frontend builds.

---

## 🔧 Environment Variables

These need to be defined before running or deploying:

| Key                  | Description                                  |
|----------------------|----------------------------------------------|
| `NEXT_PUBLIC_RPC_URL`| JSON‑RPC endpoint for wallet interactions     |
| `NEXT_PUBLIC_CHAIN_ID`| Network ID you’re using (e.g. `5` for Goerli) |
| `PRIVATE_KEY`        | Optional; needed for locally broadcasting deploy scripts |

---

## ☁️ Deploying to Vercel

To keep smart contract code out of your build:

- Add this to `.vercelignore`:
  ```
  foundry/
  ```
- Or use this snippet in `vercel.json`:
  ```json
  {
    "ignoreCommand": "echo \"📦 Skipping foundry\" && exit 0",
    "buildCommand": "npm run build",
    "outputDirectory": ".vercel/output"
  }
  ```

Only the built frontend and `src/contracts/` directory (with ABI files) will be published.

---

## 🌟 Contributing or Adding Your Spin

Love puzzles? Want to build a brand new level?

1. **Fork** the repo  
2. Branch off (e.g. `feature/add-6x6-puzzle`)  
3. Tweak in `src/app`, Solidity logic, or tests  
4. Run:
   ```bash
   npm run lint
   forge test
   ```
5. Make a **Pull Request** — we’ll be happy to review!

---

## 💾 Built With ❤️ by **Benhur**

Designed as your go-to puzzle showdown. Want to reset the board or start a new round? You're always three clicks away from seeing what genius you’re up against.

Let the logic race begin—and may the smartest brain win. 🚀
