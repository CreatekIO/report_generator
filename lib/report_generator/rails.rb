module ReportGenerator
  class Engine < Rails::Engine
    isolate_namespace ReportGenerator

    # See https://content.pivotal.io/blog/leave-your-migrations-in-your-rails-engines
    initializer 'report_generator.append_migrations' do |app|
      unless app.root.to_s.match(root.to_s)
        config.paths['db/migrate'].expanded.each do |expanded_path|
          app.config.paths['db/migrate'] << expanded_path
        end
      end
    end

    # Based on https://github.com/rails/webpacker/blob/v3.6.0/lib/webpacker/railtie.rb#L57-L65
    initializer 'report_generator.helper' do
      ActiveSupport.on_load :action_controller do
        ActionController::Base.helper ReportGenerator::Helper
      end

      ActiveSupport.on_load :action_view do
        include ReportGenerator::Helper
      end
    end
  end
end
