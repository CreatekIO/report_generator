class ReportGeneratorCreateTables < ActiveRecord::Migration
  def change
    create_table_if_not_exists :report_downloads do |t|
      t.string :report_type
      t.text :report_data
      t.string :file_name
      t.string :file_uid
      t.boolean :send_email, default: false
      t.text :remote_file_url
      t.datetime :generated_at

      t.timestamps null: false
    end

    create_table_if_not_exists :admin_report_downloads do |t|
      t.references :admin, index: true
      t.references :report_download, index: true

      t.timestamps null: false
    end
  end

  private

  def create_table_if_not_exists(table_name, &block)
    reversible do |dir|
      dir.up do
        if table_exists?(table_name)
          say "Table `#{table_name}` already created, skipping migration"
          return
        end
      end
    end

    create_table(table_name, &block)
  end
end
