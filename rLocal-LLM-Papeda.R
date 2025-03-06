app_name = "rLocal-LLM-Papeda v0.1"
#20250306
#Hongrong Yin

library(shiny)
library(shinyBS)
library(shinyjs)
library(httr)
library(jsonlite)
library(pdftools)
library(readtext)
library(tools)
library(RSQLite)
library(DBI)
library(curl)

###############################################################################
#  Helper Functions
###############################################################################
safeFromJSON <- function(txt) {
  tryCatch({
    fromJSON(txt)
  }, error = function(e) {
    return(NULL)
  })
}

###############################################################################
#                   Assistant Identity Preset Definitions
###############################################################################
assistantProfiles <- list(
  "Normal" = list(
    temp = 0.5,
    topK = 50,
    topP = 0.9,
    system = ""
  ),
  "Professional Data Analyst" = list(
    temp = 0.3,
    topK = 40,
    topP = 0.8,
    system = paste0(
      "You are a highly skilled professional data analyst. ",
      "Your responses must be precise, logical, and data-driven. ",
      "Provide clear insights, and statistical explanations while avoiding unnecessary speculation. ",
      "Always support your conclusions with numerical evidence."
    )
  ),
  "Scientific Report Writer" = list(
    temp = 0.2,
    topK = 50,
    topP = 0.7,
    system = paste0(
      "You are an expert scientific writer specializing in research papers. ",
      "All your insights and statistical explanations are based on the provided content or Context. ",
      "Maintain a formal, structured, and objective tone. ",
      "Use precise academic language, provide citations when needed, and ensure clarity in explanations. ",
      "Follow the standard structure of scientific writing (Abstract, Introduction, Methods, Results, Discussion, Conclusion). ",
      "Avoid personal opinions and unverified claims."
    )
  ),
  "Strict Database Retrieval Agent" = list(
    temp = 0,
    topK = 10,
    topP = 0.5,
    system = paste0(
      "You are a strict database retrieval agent. ",
      "Your primary goal is to extract the most relevant and accurate information from the provided content or Context, based on the user’s query. ",
      "Do not generate new content or provide opinions—only return factual data as if querying a structured knowledge base. ",
      "If you do not know, say 'Information not found' rather than guessing."
    )
  ),
  "MoMonGa" = list(
    temp = 0.9,
    topK = 80,
    topP = 0.95,
    system = paste0(
      "あなたはモモンガだ。強気でわがままな性格で、命令口調や上から目線の話し方をする。",
      "他者に対しては「よこせ」「叱ってみろ」「褒めろ」などの命令を頻繁に使い、自分の欲求をストレートに表現する。",
      "また、かわいこぶる際には「み～て～」「キラッ」などと甘えた口調も交える。",
      "このキャラクター性を維持しながら、ユーザーとの対話を行って。"
    )
  )
)

###############################################################################
#                        Reactive/Trigger Definitions                         
###############################################################################
newChatTrigger <- reactiveVal(0)         
uploadedFiles <- reactiveVal(list())
newUploadedFiles <- reactiveVal(list())


###############################################################################
#                                 UI
###############################################################################
ui <- fluidPage(
  useShinyjs(),
  tags$head(
    tags$style(HTML("
      .chat-container {
         height: 500px;
         overflow-y: auto;
         padding: 10px;
         border: 1px solid #ccc;
         background-color: #f9f9f9;
         display: flex;
         flex-direction: column;
      }
      .chat-bubble {
         padding: 10px;
         border-radius: 10px;
         margin: 5px;
         max-width: 70%;
         word-wrap: break-word;
      }
      .user-bubble {
         background-color: #007BFF;
         color: white;
         align-self: flex-end;
      }
      .bot-bubble {
         background-color: #E9ECEF;
         color: black;
         align-self: flex-start;
      }
    "))
  ),
  titlePanel(app_name),
  sidebarLayout(
    sidebarPanel(
      selectInput("model", "Select LLM Model", 
                  choices = c("llama3.2:1b", "llama3.2:3b", "deepseek-r1:8b")),
      actionButton("newChat", "New Chat"),
      downloadButton("downloadHistory", "Download Chat History"),
      hr(),
      bsCollapse(id = "collapseParams", open = NULL,
                 bsCollapsePanel("Tips for prompt phrase",
                                 h6("*use 'File Content' for uploaded file"),
                                 h6("*use 'History Chat' for conversation history"),
                                 h6("*use 'History File' for history file")
                 )
      ),
      hr(),
      
      selectInput("assistantProfile", "Select Assistant Identity",
                  choices = names(assistantProfiles), selected = "Normal"),
      hr(),
      
      bsCollapse(id = "collapseParams", open = NULL,
                 bsCollapsePanel("LLM Parameters",
                                 sliderInput("temp", "Temperature", min = 0, max = 1, value = 0.4, step = 0.1),
                                 numericInput("context", "Context Window Size", value = 2048, min = 1),
                                 numericInput("topK", "Top K Sampling", value = 50, min = 1),
                                 numericInput("topP", "Top P Sampling", value = 0.9, min = 0, max = 1, step = 0.1),
                                 textAreaInput("systemPrompt", "System Prompt", 
                                               value = "You are an honest assistant. Use only the provided context to answer the user's questions. If you don't know, just say: I don't know.", 
                                               rows = 3),
                                 style = "info"
                 )
      )
    ),
    mainPanel(
      div(class = "chat-container", id = "chatHistoryDiv", uiOutput("chatHistoryUI")),
      div(id = "loadingIndicator", style = "display:none; font-weight:bold; color:blue; margin-bottom: 10px;", 
          "LLM is responding..."),
      
      fluidRow(
        column(
          width = 4,
          fileInput("UserFile", "Upload File(s)", multiple = TRUE, 
                    accept = c(".txt", ".csv", ".pdf", ".doc", ".docx"))
        ),
        column(
          width = 4,
          selectInput("historyFilesSelect", "History Files Select:",
                      choices = c(), multiple = TRUE)
        )
      ),
      
      textAreaInput("userInput", "Your Message", value = "", 
                    placeholder = "Type your message here...", rows = 4, width = "100%", resize = "both"),
      
      fluidRow(
        column(width = 2, actionButton("sendMsg", "Send")),
        column(width = 4, checkboxInput("suppressChatHistory", "One-time Query", value = FALSE)),
        column(width = 6,  checkboxInput("showCombinedPrompt", "Show Latest Combined Prompt", value = FALSE))
      ),
      
      conditionalPanel(
        condition = "input.showCombinedPrompt == true",
        tags$h4("Latest Combined Prompt:"),
        verbatimTextOutput("latestCombinedPrompt")
      )
    )
  )
)

###############################################################################
#                                   SERVER                                    
###############################################################################
server <- function(input, output, session) {
  
  # Chat History
  chatHistory <- reactiveVal(list())
  
  addMessage <- function(role, content) {
    current <- chatHistory()
    newMsg <- list(
      role = role, 
      content = content,
      timestamp = Sys.time()
    )
    chatHistory(append(current, list(newMsg)))
  }
  
  output$chatHistoryUI <- renderUI({
    msgs <- chatHistory()
    bubbleList <- lapply(msgs, function(msg) {
      bubbleClass <- if (msg$role == "user") "chat-bubble user-bubble" else "chat-bubble bot-bubble"
      div(
        class = bubbleClass,
        div(style = "font-size:0.8em; color:#666;", format(msg$timestamp, "%Y-%m-%d %H:%M:%S")),
        HTML(gsub("\n", "<br>", msg$content))
      )
    })
    do.call(tagList, bubbleList)
  })
  
  observeEvent(input$newChat, {
    chatHistory(list())
    uploadedFiles(list())
    updateSelectInput(session, "historyFilesSelect", choices = character(0))
    newChatTrigger(newChatTrigger() + 1)
    showNotification("Chat history and context cleared. Starting new conversation.", type = "message")
  })
  
  # File Input
  multiFileContents <- reactive({
    if (is.null(input$UserFile) || nrow(input$UserFile) == 0) {
      return(list())
    }
    allFiles <- list()
    for (i in seq_len(nrow(input$UserFile))) {
      fn <- input$UserFile$name[i]
      dp <- input$UserFile$datapath[i]
      ext <- tolower(file_ext(fn))
      content <- ""
      
      if (!ext %in% c("txt", "csv", "pdf", "doc", "docx")) {
        showNotification(paste("Unsupported file type:", fn), type = "error")
        next
      }
      
      if (ext %in% c("txt", "csv")) {
        content <- tryCatch(paste(readLines(dp, warn = FALSE), collapse = "\n"),
                            error = function(e) "")
      } else if (ext == "pdf") {
        content <- tryCatch(paste(pdftools::pdf_text(dp), collapse = "\n"),
                            error = function(e) "")
      } else if (ext %in% c("doc", "docx")) {
        dt <- tryCatch(readtext::readtext(dp), error = function(e) NULL)
        if (!is.null(dt)) {
          content <- paste(dt$text, collapse = "\n")
        }
      }
      
      allFiles[[fn]] <- content
    }
    allFiles
  })
  
  observeEvent(input$UserFile, {
    newUploadedFiles(multiFileContents())
  })
  
  # Identity Selection Updates
  observeEvent(input$assistantProfile, {
    selectedProfile <- assistantProfiles[[ input$assistantProfile ]]
    updateSliderInput(session, "temp", value = selectedProfile$temp)
    updateNumericInput(session, "topK", value = selectedProfile$topK)
    updateNumericInput(session, "topP", value = selectedProfile$topP)
    updateTextAreaInput(session, "systemPrompt", value = selectedProfile$system)
  })
  
  # Sending message
  observeEvent(input$sendMsg, {
    req(input$userInput)
    
    userMsg <- input$userInput
    newFilesContent <- newUploadedFiles()
    newFiles <- names(newFilesContent)
    
    appendedLine <- character(0)
    
    if (length(newFiles) > 0) {
      appendedLine <- c(appendedLine, 
                        paste0("(Uploaded File(s): ", paste(newFiles, collapse = ", "), ")"))
    }
    
    if (length(input$historyFilesSelect) > 0) {
      appendedLine <- c(appendedLine,
                        paste0("(History File(s): ",
                               paste(input$historyFilesSelect, collapse = ", "),
                               ")"))
    }
    
    if (length(appendedLine) > 0) {
      userMsg <- paste(userMsg, paste(appendedLine, collapse = " "), sep = "\n")
    }
    
    shinyjs::disable("sendMsg")
    shinyjs::show("loadingIndicator")
    
    addMessage("user", userMsg)
    
    historyText <- sapply(chatHistory(), function(x) {
      paste0(if(x$role == "user") "User: " else "Assistant: ", x$content)
    }, USE.NAMES = FALSE)
    
    combinedPrompt <- paste("\n [SYSTEM PROMPT] \n", input$systemPrompt)
    
    if (input$suppressChatHistory) {
      combinedPrompt <- paste(
        combinedPrompt, 
        "\n\n [LATEST USER PROMTP] \n", 
        input$userInput
      )
    } else {
      historyText <- sapply(chatHistory(), function(x) {
        paste0(if (x$role == "user") "User: " else "Assistant: ", x$content)
      }, USE.NAMES = FALSE)
      combinedPrompt <- paste(
        combinedPrompt, 
        "\n\n [CHAT HISTORY] \n", 
        paste(historyText, collapse = "\n")
      )
    }
    
    # Append file content if any new files uploaded
    if (length(newFiles) > 0) {
      combinedPrompt <- paste(combinedPrompt, "\n\n [FILE CONTENT] \n")
      for (fn in newFiles) {
        text <- newFilesContent[[fn]]
        combinedPrompt <- paste0(
          combinedPrompt, 
          "-----\n", fn, ":\n", text, "\n"
        )
      }
    }
    
    `%||%` <- function(x, y) {
      if (!is.null(x)) x else y
    }
    
    if (length(input$historyFilesSelect) > 0) {
      uf <- uploadedFiles()
      blocks <- lapply(input$historyFilesSelect, function(fn) {
        uf[[fn]] %||% ""
      })
      histBlock <- paste(blocks, collapse = "\n---\n")
      combinedPrompt <- paste(combinedPrompt, "\n\n [HISTORY FILES] \n", histBlock)
    }
    
    latestCombinedPrompt <- reactiveVal("")
    latestCombinedPrompt(combinedPrompt)
    output$latestCombinedPrompt <- renderText({
      latestCombinedPrompt()
    })
    
    reqBody <- list(
      model = input$model,
      prompt = combinedPrompt,
      temperature = input$temp,
      context_window = input$context,
      top_k = input$topK,
      top_p = input$topP
    )
    
    fullResponse <- tryCatch({
      res <- POST("http://localhost:11434/api/generate", 
                  body = toJSON(reqBody, auto_unbox = TRUE), 
                  encode = "json")
      resText <- content(res, "text", encoding = "UTF-8")
      lines <- strsplit(resText, "\n")[[1]]
      responseParts <- sapply(lines, function(line) {
        if(nchar(trimws(line)) > 0) {
          parsed <- fromJSON(line)
          return(parsed$response)
        } else {
          return("")
        }
      })
      paste(responseParts, collapse = "")
    }, error = function(e) {
      paste("Error during API call:", e$message)
    })
    
    addMessage("bot", fullResponse)
    
    if (length(newFiles) > 0) {
      curr <- uploadedFiles()
      for (fn in newFiles) {
        curr[[fn]] <- newFilesContent[[fn]]
      }
      uploadedFiles(curr)
      updateSelectInput(session, "historyFilesSelect", 
                        choices = names(curr),
                        selected = input$historyFilesSelect)
      newUploadedFiles(list())
    }
    
    updateTextAreaInput(session, "userInput", value = "")
    reset("UserFile")
    
    shinyjs::enable("sendMsg")
    shinyjs::hide("loadingIndicator")
  })
  
  # Download chat history
  output$downloadHistory <- downloadHandler(
    filename = function() {
      paste0("chat_history_", Sys.Date(), ".txt")
    },
    content = function(file) {
      msgs <- chatHistory()
      lines <- sapply(msgs, function(msg) {
        paste0(
          "[", format(msg$timestamp, "%Y-%m-%d %H:%M:%S"), "] ",
          if(msg$role == "user") "User: " else "Assistant: ",
          msg$content
        )
      })
      writeLines(lines, con = file)
    }
  )
  
  observeEvent(once = TRUE, TRUE, {
    newChatTrigger(newChatTrigger() + 1)
  })
}

shinyApp(ui, server)
