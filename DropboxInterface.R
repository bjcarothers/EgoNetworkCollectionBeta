# Getting R to save files to Dropbox
# For details, see https://github.com/karthik/rdrop2

# First, log into your Dropbox account and create the folder you want to save to
# Set outputDir to this folder name in server.R

# Install and load rdrop2 package
install.packages('rdrop2')
library(rdrop2)

# Have R request access to Dropbox account. Your browser will prompt you to 
# provide authorization. Close browser once complete
token <- drop_auth()

# Save token to local machine. Be careful with the resulting .httr-oauth file! This
# gives access to your Dropbox account
saveRDS(token, file = "token.rds") # saves to MyDocuments as-is. Edit as appropriate

# Copy the .httr-oauth file to your Shiny app folder with your server.R and ui.R files

# For other data storage options (Amazon S3, Google Sheets, etc., see:
# https://shiny.rstudio.com/articles/persistent-data-storage.html)

