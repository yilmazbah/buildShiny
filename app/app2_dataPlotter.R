library(shiny)
library(plotly)
library(ggplotify)

# Define UI for data upload app
ui <- fluidPage(
  
  # Page title
  titlePanel("Data Plotter"),
  
  # Sidebar layout with input and output definitions
  sidebarLayout(
    
    # Sidebar panel for inputs
    sidebarPanel(
      
      # Input: Select a file
      fileInput(inputId = "file1", 
                label = "Choose File",
                multiple = FALSE),
      
      # Horizontal line
      tags$hr(),
      
      # Input: Checkbox if file has header
      checkboxInput(inputId = "header", 
                    label = "Header", 
                    value = TRUE),
      
      # Horizontal line
      tags$hr(),
      
      # Input: Select separator
      radioButtons(inputId = "sep", 
                   label = "Separator",
                   choices = c(Comma = ",",
                               Semicolon = ";",
                               Tab = "\t"),
                   selected = "\t"),

      # Horizontal line
      tags$hr(),
      
      # Input: Plotting parameters
      # "Empty inputs" - they will be updated after the data is uploaded
      
      # Input: X axis to plot
      selectInput(inputId = "xcol", label = "X variable", choices = ""),
      
      # Input: Y axis to plot
      selectInput(inputId = "ycol", label = "Y variable", choices = "", selected = ""),
      
      # Input: Column to color dots
      selectInput(inputId = "colorby", label = "Colour", choices = "", selected = ""),
      
      # Horizontal line
      tags$hr(),
      
      # Input: Boolean to facet
      radioButtons(inputId = "facet", label = "Facet", 
                   choices = c(No = FALSE, 
                               Yes = TRUE), 
                   selected = FALSE),
      
      # Input: Column to create facets
      selectInput(inputId = "groupName", label = "Facet Group", choices = "", selected = ""),
      
      # Input: Subset data by group
      checkboxGroupInput(inputId = "groupElements", label = "Subset", choices = "", selected = ""),
      
      # Horizontal line
      tags$hr(),
      
      # Input: Plot title
      textInput(inputId = "main", label = "Plot Title", value = "My plot"),
      
      # Input: X axis name
      textInput(inputId = "xname", label = "X-axis title", value = ""),
      
      # Input: Y axis name
      textInput(inputId = "yname", label = "Y-axis title", value = ""),
      
      # Horizontal line
      tags$hr(),
      
      # Input: Dot size
      sliderInput(inputId = "dotsize", label = "Dot size",
                  value = 1, min = 0.5, max = 3, step = 0.5)
      
    ),
    
    # Main panel for displaying outputs
    mainPanel(
      
      # Plot data
      plotlyOutput('myplot')
      
    )
    
  )
)


# Define server logic to read selected file
server <- function(input, output, session) {
  
  # Reactive: Read data
  df <- reactive({
    
    # Check "if" file is there. "if not" do not run the next lines
    req(input$file1)
    
    # Read data
    dat <- read.table(input$file1$datapath,
                      header = input$header,
                      sep = input$sep)
    
    # Update: changes on the 'plot parameters'
    updateSelectInput(session, inputId = 'xcol', label = 'X Variable',
                      choices = names(dat), selected = names(dat)[1])
    updateSelectInput(session, inputId = 'ycol', label = 'Y Variable',
                      choices = names(dat), selected = names(dat)[2])
    updateSelectInput(session, inputId = 'colorby', label = 'Colour',
                      choices = names(dat), selected = names(dat)[5])
    updateSelectInput(session, inputId = 'groupName', label = 'Facet Group',
                      choices = names(dat), selected = names(dat)[5])

    return(dat)
    
  })

  # Observe: changes on the 'plot parameters'
  observe({
    
    # Observe: X axis title
    updateTextInput(session, inputId = "xname", label = "X-axis title",
                    value = input$xcol)
    
    # Observe: Y axis title
    updateTextInput(session, inputId = "yname", label = "Y-axis title",
                    value = input$ycol)

    # Observe: Subset elements in the column to facet
    if(is.numeric(df()[[input$groupName]])){
      subgroup <- character(0)
    }else{
      subgroup <- sort(unique(df()[[input$groupName]]))
    }
    updateCheckboxGroupInput(session, inputId = "groupElements",
                             label = paste("Subset by:", input$groupName),
                             choices = subgroup, selected = subgroup)
    
  })
  
  # Reactive: Subset the data if needed before plotting
  dfsub <- reactive({
    
    # subset df
    if(is.numeric(df()[[input$groupName]])){
      dfsub <- df()
    }else{
      dfsub <- subset(df(), get(input$groupName) %in% input$groupElements) # Alternatively, we can only use this line to subset data
    }
    
    return(dfsub)
    
  })
  
  # Output: Plot
  output$myplot <- renderPlotly({
    
    pbase <- ggplot(data = dfsub(),
                    aes_string(x = input$xcol,
                               y = input$ycol,
                               colour = input$colorby)) + 
      geom_point(size=input$dotsize) +
      ggtitle(input$main) +
      xlab(input$xname) + 
      ylab(input$yname)
    
    if(input$facet){
      p <- pbase + facet_grid(input$groupName)
      p <- ggplotly(p)
    }else{
      p <- ggplotly(pbase)
    }
    
    return(p)
    
  })
  
}

# Create Shiny app
shinyApp(ui, server)
