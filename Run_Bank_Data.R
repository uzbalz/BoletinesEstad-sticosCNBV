pacman::p_load(haven,
               ggplot2,
               dplyr,
               ggpubr,
               DT,
               rmarkdown,
               webshot,
               httpuv)

#install.packages("webshot")
#webshot::install_phantomjs()

rm(list = ls())

bank_data <- read_dta("//Statadgef/darmacro/Data/Bank Data/Data/Stata/[13]Indicadores_Bancarios_Agr.dta")

#Automatically detect the highest data value
stata_date_number <- max(bank_data$monthly_date)
year <- floor(stata_date_number / 12) + 1960 # Stata's base year is 1960
month <- stata_date_number %% 12 + 1

stata_date_string <- paste(year, "m", month, sep = "") # Create the Stata date string

# Rendering the R-Markdown
render("//Statadgef/darmacro/Data/Bank Data/Codes/PropiedadesBM_v0.8.Rmd", 
       output_format = "html_document",
       output_file = paste0("C:/Users/K17765/Documents/u_",stata_date_string)) 

# Copying to server
file.copy(paste0("C:/Users/K17765/Documents/u_",stata_date_string, ".html"), 
          paste0("//Statadgef/darmacro/Data/Bank Data/ResumenBoletínEstadístico_",stata_date_string, ".html"), overwrite = TRUE)

