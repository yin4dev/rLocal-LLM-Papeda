# rLocal-LLM-Papeda
Local LLM using R Shiny and ollama. The lite version of rLocal-LLM-Pomelo. This "Papeda" is very suitable for inserting into your existing Shiny App to achieve the Local LLM function.

---

Welcome to **rLocal-LLM-Papeda v0.1**! This open-source Shiny application provides an interactive interface to converse with local Large Language Models (LLMs) while integrating retrieval-augmented generation (RAG) and file upload capabilities. The app is designed to be easily portable and customizable, allowing you to switch between various assistant identities to suit your specific needs.

---

## Table of Contents
1. [Overview](#overview)
2. [Key Features](#key-features)
3. [Dependencies](#dependencies)
4. [Installation and Setup](#installation-and-setup)
   - [Required Tools](#required-tools)
5. [Usage](#usage)
   - [Running the Shiny App](#running-the-shiny-app)
   - [Conversation and File Management](#conversation-and-file-management)
   - [Assistant Profiles](#assistant-profiles)
6. [Configuration](#configuration)
7. [Special Thanks](#special-thanks)
8. [License](#license)

---

## Overview

**rLocal-LLM-Papeda** is an R/Shiny application that enables real-time interactions with local LLMs. It is built with a focus on flexibility and extensibility, combining a conversational chat interface with document upload and processing features. Whether you are using it for data analysis, scientific report writing, or simply exploring different assistant personas, this app brings a modern, user-friendly interface to local LLM integration.

---

## Key Features

- **Conversational Chat Interface**: Engage in interactive conversations where each message is timestamped and clearly distinguished by user or assistant roles.
- **Assistant Identity Presets**: Choose from a range of predefined profiles (e.g., Normal, Professional Data Analyst, Scientific Report Writer, Strict Database Retrieval Agent, and MoMonGa) that adjust parameters and system prompts automatically.
- **File Upload and Processing**: Upload multiple file types (e.g., `.txt`, `.csv`, `.pdf`, `.doc`, `.docx`) to integrate external content into the conversation.
- **Dynamic Prompt Assembly**: Automatically build and display the latest combined prompt that integrates system instructions, chat history, and file content.
- **Local LLM Integration**: Communicate with a local LLM service via a RESTful API (default endpoint: `http://localhost:11434/api/generate`).

---

## Dependencies

### R Packages

- **Core Packages**:  
  `shiny`, `shinyBS`, `shinyjs`, `httr`, `jsonlite`, `pdftools`, `readtext`, `tools`, `RSQLite`, `DBI`, `curl`

These packages handle everything from the UI framework and HTTP requests to file processing and database interactions.

### System Tools:

- **Ollama for pulling and running LLM models locally**
  
---

## Installation and Setup

### Required Tools

1. **Clone or Download the Repository**  
   Clone this repository or download the source files to your local machine.

2. **Install Ollama and Pull LLM Models**  
   - **Ollama**:  
     Install [Ollama](https://www.ollama.com/) to run local LLM models.  
     After installing Ollama, pull the required LLM models using commands such as:
     ```bash
     ollama pull llama3.2:1b
     ollama pull llama3.2:3b
     ollama pull deepseek-r1:8b
     ```
3. **Install R Packages**  
   Install the required R packages:
   ```r
   install.packages(c(
     "shiny", "shinyBS", "shinyjs", "httr", "jsonlite", "pdftools",
     "readtext", "tools", "RSQLite", "DBI", "curl", 'rollama'
   ))
   ```

4. **Review and Configure the Code**  
   Open the source code to review the assistant identity presets, LLM parameters, and file handling logic. Adjust these configurations as needed for your specific use case.
---

## Usage

### Running the Shiny App

1. **Start an R Session**  
2. **Launch the App**  
   ```r
   library(shiny)
   runApp("path_to_your_app_directory")
   ```
3. **Access the Interface**  
   A browser window should open automatically. If not, manually navigate to the URL provided in the console.

### Conversation and File Management

- **Chat Interface**:  
  The application features a scrolling chat interface where each message is displayed in a chat bubble format, with distinct styling for the user and the assistant.
  
- **File Uploads**:  
  Use the file input widget to upload documents. Uploaded files are processed (e.g., text extraction for PDFs and word documents) and incorporated into the conversation context automatically.

- **Session Reset**:  
  Click the **New Chat** button to clear the current conversation and file contexts, starting fresh.

### Assistant Profiles

- **Predefined Profiles**:  
  Choose from multiple assistant identities (Normal, Professional Data Analyst, Scientific Report Writer, Strict Database Retrieval Agent, MoMonGa) via a dropdown.  
  Each profile automatically sets specific parameters such as temperature, top-K, top-P sampling values, and a tailored system prompt.
  
- **Custom Prompting**:  
  You can manually adjust parameters like temperature and context window size, or modify the system prompt directly through the UI.

---

## Configuration

- **LLM API Endpoint**:  
  The default API endpoint is set to `http://localhost:11434/api/generate`. Change this setting in the code if your local LLM service operates at a different address.

- **Assistant Identity and Parameters**:  
  The preset assistant profiles are defined in the code, making it easy to extend or modify the available identities based on your needs.

- **Combined Prompt Display**:  
  Optionally, you can display the latest combined prompt (including chat history and file content) by enabling the corresponding checkbox in the UI.

---

## Special Thanks

A huge thank you to my loving Aimi Yago for her invaluable understanding, support, and inspiration in making this project better!  🎉

---

## License

This project is licensed under the [GNU General Public License v3.0 (GPL-3.0)](https://www.gnu.org/licenses/gpl-3.0.html).

Copyright (C) 2025 Hongrong Yin

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

---
