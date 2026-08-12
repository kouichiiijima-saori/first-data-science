require_relative "seeds/articles"

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

initial_admin_email = ENV["INITIAL_ADMIN_EMAIL"].to_s.strip.downcase
initial_admin_password = ENV["INITIAL_ADMIN_PASSWORD"].to_s
credentials_provided = initial_admin_email.present? || initial_admin_password.present?
credentials_complete = initial_admin_email.present? && initial_admin_password.present?

if credentials_provided && !credentials_complete
  raise "Both INITIAL_ADMIN_EMAIL and INITIAL_ADMIN_PASSWORD are required to create the initial admin."
elsif credentials_complete
  admin = Admin.find_or_initialize_by(email: initial_admin_email)

  if admin.persisted?
    puts "Initial admin seed skipped: admin already exists."
  else
    admin.password = initial_admin_password
    admin.password_confirmation = initial_admin_password
    admin.save!
    puts "Initial admin created."
  end
elsif Rails.env.production? && Admin.none?
  raise "INITIAL_ADMIN_EMAIL and INITIAL_ADMIN_PASSWORD are required when no admin exists in production."
else
  puts "Initial admin seed skipped: INITIAL_ADMIN_EMAIL and INITIAL_ADMIN_PASSWORD are not set."
end

Seeds::Articles.load
