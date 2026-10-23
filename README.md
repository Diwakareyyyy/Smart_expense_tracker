# Smart AI Expense Tracker

An intelligent expense tracking application built with **Flutter** (Frontend) and **FastAPI** (Backend). 
It features AI-powered receipt scanning (OCR) and an intelligent financial assistant that analyzes your spending, answers complex financial queries (e.g., "highest expense", "total spend this month"), and provides smart budget advice.

## Features
- **AI Chatbot**: Powered by Groq LLM to instantly answer any question about your budget or transactions.
- **OCR Receipt Scanner**: Automatically extracts total amount and category from receipt images.
- **Detailed Analytics**: Visual breakdowns of your daily, weekly, and monthly spending.
- **Budget Management**: Set budgets for categories and track your spending limits.

---

## 🚀 How to Run the Project

### 1. Backend Setup (FastAPI & Python)

The backend handles the AI logic and communicates with the Groq API.

1. Navigate to the `backend` folder:
   ```bash
   cd backend
   ```
2. Create your Virtual Environment and install dependencies:
   ```bash
   python -m venv venv
   # Windows:
   .\venv\Scripts\activate
   # Mac/Linux:
   source venv/bin/activate
   
   pip install -r requirements.txt
   ```
3. Set up your API Keys:
   - Create a `.env` file in the `backend` folder.
   - Add your Groq API Key only in the backend environment file. Do not hardcode the key in Flutter/Dart source files.
     ```env
     GROQ_API_KEY=your_groq_api_key_here
     SMART_EXPENSE_API_KEY=your_groq_api_key_here
     ```
4. Start the server:
   ```bash
   python main.py
   # The backend will start on http://0.0.0.0:8000
   ```

### 2. Frontend Setup (Flutter)

The Flutter app expects the backend to be running.

1. Open `lib/services/ai_service.dart`.
2. Locate the `_baseUrl` getter. 
   - **For Android Emulator**: Use `http://10.0.2.2:8000`
   - **For iOS Simulator / Web**: Use `http://127.0.0.1:8000`
   - **For Physical Devices**: Change the IP address to your computer's local Wi-Fi IP (e.g., `http://192.168.1.5:8000`).
3. Fetch dependencies and run:
   ```bash
   flutter pub get
   flutter run
   ```

## Customization
You can completely customize the LLM logic and restrictions by modifying the prompt inside `backend/services/chatbot_service.py`.

## License
MIT License
