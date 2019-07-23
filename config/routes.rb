ReportGenerator::Engine.routes.draw do
  post '/' => 'downloads#create', as: :report_downloads
end
