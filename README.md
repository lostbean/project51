# 👽 Area 51: Unveiling the Unknown 🕵️‍♀️

Welcome to **Area 51: Unveiling the Unknown**, a real-time collaborative investigation game powered by Elixir, Phoenix, React, and Large Language Models (LLMs)! 🚀 Dive into the mysteries of Area 51, work with fellow investigators, and unravel the secrets hidden within this enigmatic location.

## 🎮 The Game

In **Area 51: Unveiling the Unknown**, you and your team of investigators are tasked with uncovering the truth behind the legendary Area 51. 🕵️‍♂️ Collaborate in real-time, share your findings, and let the LLM-powered game master guide your investigation.

### How to Play

1.  **Join an Investigation:** Start a new investigation or join an existing one.
2.  **Collaborate:** Share your observations, theories, and actions with your team.
3.  **Interact with the LLM:** The game master, powered by an LLM, will dynamically respond to your inputs, evolving the narrative in real-time.
4.  **Uncover Clues:** Discover hidden clues and piece together the puzzle.
5.  **Solve the Mystery:** Work together to uncover the truth behind Area 51!

## 🛠️ Tech Stack

-   **Elixir & Phoenix:** Robust and scalable backend for real-time communication and application logic. ⚡
-   **React:** Dynamic and responsive frontend for an engaging user experience. ⚛️
-   **Phoenix Channels:** Real-time communication via WebSockets. 📡
-   **LiveState:** Efficient state synchronization between the backend and frontend. 🔄
-   **Ecto & SQLite:** Data persistence for game sessions, clues, and logs. 💾
-   **Magus Library:** Seamless integration with Large Language Models. 🧠

## 🚀 Setup

1.  **Prerequisites:**
    -   Install Elixir: [Installation Guide](https://elixir-lang.org/install.html)
    -   Install Node.js: [Installation Guide](https://nodejs.org/)

3.  **Install Elixir Dependencies:**
    ```bash
    mix setup
    ```

4.  **Install Frontend Dependencies:**
    ```bash
    cd apps/area51_web/assets
    npm install
    cd ../../.. # Return to the project root directory
    ```

5.  **Start the Phoenix Server:**
    ```bash
    mix phx.server
    ```

6.  **Access the Game:**
    -   Open your web browser and navigate to `http://localhost:4000`.

## 🎨 Design & User Experience

### Thematic Immersion

-   **Dark & Mysterious UI:** The user interface features a dark, mysterious aesthetic with subtle hints of alien technology and classified information. 🌑
-   **Thematic Typography & Imagery:** Custom fonts and imagery evoke the atmosphere of Area 51. 👽
-   **In-Game Terminology:** Labels and messages use thematic language, such as "Anomaly Detected," "Classified Intel," and "Witness Report." 📝

### Real-Time Collaboration

-   **Dynamic Narrative:** The LLM evolves the narrative in real-time based on player inputs. 📖
-   **Shared Clues & Logs:** Clues and investigation logs are shared instantly among all players. 🔍
-   **Interactive Elements:** Input fields and buttons are styled to resemble secure computer terminals. 💻

### Engaging Gameplay

-   **Collaborative Storytelling:** Players contribute to the story through their observations and actions. ✍️
-   **Dynamic Challenges:** The LLM introduces new challenges and obstacles based on player decisions. 🧩
-   **Real-Time Feedback:** Players receive immediate feedback from the LLM and their team. 🗣️

## 📂 Project Structure

```
area51_investigation/
├── apps/
│   ├── area51_core/       # Core game logic
│   ├── area51_data/       # Data persistence with Ecto & SQLite
│   ├── area51_llm/        # LLM integration using Magus
│   └── area51_web/        # Phoenix web application
│       ├── assets/        # Frontend assets (React, JavaScript, CSS)
│       ├── lib/           # Elixir backend code
│       └── test/          # Backend tests
├── config/                # Application configurations
├── mix.exs                # Umbrella project configuration
└── README.md              # Project documentation
```

## 🧠 LLM Integration

The `area51_llm` application handles the integration with the Large Language Model using the Magus library. 🚀

-   **Prompt Engineering:** Carefully crafted prompts guide the LLM to generate narrative elements, clues, and responses that fit the Area 51 theme. 📝
-   **Structured Output:** The LLM's responses are formatted into structured JSON to facilitate seamless integration with the backend. 📦
-   **Asynchronous Processing:** LLM interactions are handled asynchronously to maintain application responsiveness. ⏳

**Note:** You'll need to replace the placeholder in `apps/area51_llm/lib/area51_llm/agent.ex` with your actual Magus library code and LLM provider credentials. 🔑

## 🤝 Contributing

We welcome contributions! Feel free to submit pull requests or open issues to improve the game. 🛠️

## 📜 License

This project is licensed under the [MIT License](LICENSE). 📄

---

Uncover the secrets of Area 51 and join the investigation! 🕵️‍♂️👽🚀
