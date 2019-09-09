ReportGenerator::Engine.routes.draw do
  # JWTs contain periods (`.`) so we need to loosen the constraints for `:token`
  # in order for it to match
  get '/:token' => 'downloads#show', as: :report_download, constraints: { token: %r{[^/]+} }
  post '/' => 'downloads#create', as: :report_downloads
end
