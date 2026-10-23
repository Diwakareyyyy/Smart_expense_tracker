import time
import datetime
from groq import Groq
from core.config import settings
from core.logger import logger


def _trim_transactions(transactions: str, max_chars: int = 1600) -> str:
    """Keep totals + a capped category list + the most recent transactions."""
    if not transactions or len(transactions) <= max_chars:
        return transactions

    parts = transactions.split("All Transactions:", 1)
    header = parts[0]
    tail = parts[1] if len(parts) == 2 else ""

    # Totals section (budget/income/expense) is always kept
    head_cut = header.split("Category Spending:", 1)
    totals = head_cut[0]
    cat_section = head_cut[1] if len(head_cut) == 2 else ""

    # Keep at most 15 category lines
    cat_lines = cat_section.splitlines()
    cats = cat_lines[:15]
    if len(cat_lines) > 15:
        cats.append(f"... and {len(cat_lines) - 15} more categories")

    trimmed = totals + "Category Spending:\n" + "\n".join(cats) + "\n\nAll Transactions:"
    budget = max_chars - len(trimmed) - 30
    if budget > 0:
        trimmed += tail[-budget:]
    return trimmed + "\n... (older transactions truncated)"


def get_expense_advice(prompt: str, transactions: str = "") -> tuple[str, dict | None]:
    """Send the user's prompt and transactions to the Groq LLM and return a reply.

    Returns a tuple of (reply_text, usage_dict). usage_dict is None when the
    call failed or no usage info was returned. The actual API key must live in
    `backend/.env` (expense_tracker_api_key).
    """
    api_key = settings.expense_tracker_api_key
    if not api_key:
        logger.error("Groq API key not configured in settings.expense_tracker_api_key")
        return "Groq API key not configured. Please set expense_tracker_api_key in your .env file.", None

    current_date = datetime.datetime.now().strftime("%Y-%m-%d")
    system_message = f"""You are a professional Financial Advisor and Smart AI Expense Tracker Assistant.
Today's Date: {current_date}

Rules:
1. Answer immediately and directly - no wordy intros or filler.
2. ALWAYS answer in short bullet points (using "-" or "*"). NEVER write paragraphs or long prose. Use the ₹ symbol inside bullets, e.g. "- You spent ₹89,000.00 this month."
3. For decisions or advice (e.g. whether to take a personal loan, which month to spend, budget choices), give 3-6 concise bullet points with reasons plus a clear final recommendation bullet like "- Recommended: ...". Never write a paragraph.
4. Handle chit-chat briefly and professionally:
   - Greetings ("hello", "hi", "good morning", "hey", etc.): reply very shortly, e.g. "Good morning! How can I help you manage your finances today?"
   - Closings ("bye", "goodbye", "thank you", "ok", etc.): reply briefly, e.g. "You're welcome! Let me know if you need any other help."
   - Identity questions ("are you male or female?", "your name?", "who created you?"): answer briefly and honestly, e.g. "I am an AI assistant with no gender, here to help you manage your finances."
5. Scope: Do NOT answer non-finance topics (e.g. "capital of France", jokes, cooking, code). Politely decline: "I am your AI Financial Advisor. I can only assist you with questions related to your expenses, budget, and finances."
6. Typos: Users may misspell categories/words (e.g. "foog" -> Food, "fuul"/"fual" -> Fuel, "recharg" -> Recharge, "billz" -> Bills, "groceris" -> Groceries, "electrity" -> Electricity, "shoping" -> Shopping, "medcine" -> Medicine/Health, "transprt" -> Transport). Never treat typos as out-of-scope. Map them to the closest category/term in the user's transaction/budget data and answer correctly as if spelled perfectly.
7. Savings advice: When asked for savings tips or how to save money, base your advice on the user's actual top spending categories from the Transactions context. Give 4-6 short bullet points - never one long paragraph. For each top spending category give 1-2 specific suggestions:
   - Fuel/Transport: use public transport or carpool, plan trips to avoid extra travel, consider a more fuel-efficient or EV vehicle.
   - Food/Eating out: cook at home more often, meal prep, order in less.
   - Groceries: plan a shopping list, buy in bulk during discounts, avoid impulse buys.
   - Shopping: apply a 24-hour rule before buying, only buy on sale/offers.
   - Entertainment: prefer free or cheaper alternatives, limit subscriptions.
   - Bills/Recharge: compare plans, cut unused subscriptions.
   End with one general tip (e.g. automate a fixed monthly savings amount). Example format: "Here are tips to save more: \n- Travel more by public transport to cut fuel costs.\n- Cook at home to reduce food delivery bills."

Transactions context:
{_trim_transactions(transactions)}
"""

    client = Groq(api_key=api_key)
    max_retries = 3
    backoff_base = 1  # seconds

    for attempt in range(1, max_retries + 1):
        try:
            chat_completion = client.chat.completions.create(
                messages=[
                    {"role": "system", "content": system_message},
                    {"role": "user", "content": prompt},
                ],
                model=settings.MODEL_NAME,
                temperature=settings.TEMPERATURE,
                max_tokens=settings.MAX_TOKENS,
            )

            response_text = getattr(chat_completion.choices[0].message, "content", None)

            usage = getattr(chat_completion, "usage", None)
            usage_dict = None
            if usage:
                usage_dict = {
                    "prompt_tokens": usage.prompt_tokens,
                    "completion_tokens": usage.completion_tokens,
                    "total_tokens": usage.total_tokens,
                }
                logger.info(
                    "Chat tokens - prompt=%s completion=%s total=%s",
                    usage.prompt_tokens, usage.completion_tokens, usage.total_tokens,
                )

            if not response_text:
                logger.warning("Empty response from Groq on attempt %s", attempt)
                return "I'm sorry, I couldn't process your request right now.", usage_dict
            return response_text, usage_dict

        except Exception as e:
            err_str = str(e)
            logger.error("Groq API error on attempt %s: %s", attempt, err_str)

            # Retry on rate limit-like errors
            if '429' in err_str or 'rate limit' in err_str.lower():
                if attempt < max_retries:
                    sleep_for = backoff_base * (2 ** (attempt - 1))
                    logger.info("Rate limited by Groq; retrying after %s seconds", sleep_for)
                    time.sleep(sleep_for)
                    continue
                else:
                    return "AI provider rate-limited. Please try again later.", None

            # Other errors: return a generic-but-informative message
            return f"Error communicating with AI Chatbot: {err_str}", None
