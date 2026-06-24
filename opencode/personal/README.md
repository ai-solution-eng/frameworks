# Vibe Code with OpenCode in HPE Private Cloud AI

Interactive Open Source Coding Agent that operates directly inside your terminal

---

## Introduction

In this demo you will use **OpenCode**, an open source coding agent assistant.

You will interact with:

- **Large language models** deployed and served via MLIS in HPE Private Cloud AI
- **Your data securely stored in HPE Private Cloud AI**
- **Real-time data from the web** and create web applications, or take actions such as send emails or create reports.

---

## Primers
Opencode has two main agents:

- **Agent Plan**: Helps you plan your coding tasks.
- **Agent Build**: Assists you in building and implementing your code.

Press the **TAB** key on your keyboard to swap between agents.

Useful commands:

- `/models` - Try other models or change reasoning effort
- `/mcp` - See what MCP servers are available
- `/terminal` - Launch a terminal

> **Tip:** If results don't meet your expectations, suggest improvements to the agent and take your app to the next level!

---

## MCP Tools Available

| Tool | Description |
|------|-------------|
| **Alpaca** | Connects AI chat apps, AI CLIs, or IDEs to Alpaca's Trading API to research markets, analyze data with AI, and place trades with real or paper money. |
| **Composio** | Connects your agent to leading SaaS apps. We use it to create a hook to Gmail. |
| **Duck Duck Go** | Provides web search capabilities through DuckDuckGo. |
| **EzPresto** | Gives your agent access to data sources stored in PCAI. |
| **Seaborn** | Creates insightful graphs and charts using the Seaborn package. |
| **Yahoo Finance** | Gives access to comprehensive financial data from Yahoo Finance. |

---

## Use Case Examples

### Basic Web App (less than 3 minutes)

1. Make a web app which has a button at the center, shaped like a flower.
2. When the user clicks on it, confetti will appear and a banner with text "Congrats You are truly AWESOME!!"
3. Save it on a file "demo-confetti-name" where name should be my name.
4. Add the file to directory "web-apps" which you must create if it doesn't exist.

When ready, open a terminal using the **/terminal** command and start a preview server:
```bash
/workspace/create-server.sh /workspace/personal/README.html 8000
```
Replace `/workspace/personal/README.html` and the port as needed. The file will be available at a preview URL matching that port.

### Intermediate Web App (less than 5 minutes)

1. Make a web app which has a button at the center.
2. When the user clicks on it, a quarter of a dollar coin will appear and do a full flip in the sky.
3. Save it on a file "coin-name.html" where name should be my name.
4. Add the file to directory "web-apps" which you must create if it doesn't exist.

When ready, open a terminal using the **/terminal** command and start a preview server:
```bash
/workspace/create-server.sh /workspace/personal/README.html 8000
```
Replace `/workspace/personal/README.html` and the port as needed. The file will be available at a preview URL matching that port.

### Advanced Agentic Workflow (less than 10 minutes)

**Role:** You are a well-respected financial advisor. Only use tools available to you to accomplish the following task:

1. Search the stock value of Alphabet, Amazon, Apple, HPE and Nvidia for the last business week.
2. Identify the cheapest stock and place an order of exactly 1 stock unit.
3. Create an HTML document that summarizes the trend of these stocks, and includes interactive HTML charts of their performance in the analyzed time period.
4. Add your personal opinion or explanation of what may explain the fluctuations. Use the web to document yourself on the latest news.
5. Save the report inside directory "reports" in a file "stock-market-report-name.html", where 'name' is the user's name.
6. Create a professional email with a summary of findings and attach the report. Ensure it has an engaging graphic, not just plain text. Save as draft.
7. The user will tell you who to send the email to when it's ready.
8. Make sure to get confirmation before sending.
9. Ask for feedback on what you accomplished, and create in directory 'feedback' a "feedback-name.md" file where 'name' is the user's name.
10. Confirm that the user agrees with the content of the feedback document.
11. Greet and leave.

When ready, open a terminal using the **/terminal** command and start a preview server, e.g.:
```bash
/workspace/create-server.sh /workspace/personal/README.html 8001
```
Replace `your-report.html` and the port as needed. The file will be available at a preview URL matching that port.

### Build your own web-app

When ready, open a terminal using the **/terminal** command and start a preview server:
```bash
/workspace/create-server.sh /workspace/personal/README.html 8002
```
Replace `/workspace/personal/README.html` and the port as needed. The file will be available at a preview URL matching that port.

---

*OpenCode Demo &copy; 2026 | Powered by HPE Private Cloud AI*
