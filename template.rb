# frozen_string_literal: true

require "fileutils"
require "shellwords"

RAILS_REQUIREMENT = "~> 7.0.0"

# Copied from https://github.com/mattbrictson/rails-template
# Add this template directory to source_paths so that Thor actions like
# copy_file and template resolve against our source files. If this file was
# invoked remotely via HTTP, that means the files are not present locally.
# In that case, use `git clone` to download them to a local temporary dir.
def add_template_repository_to_source_path
  if __FILE__ =~ %r{\Ahttps?://}
    require "tmpdir"
    source_paths.unshift(tempdir = Dir.mktmpdir("upperbracket-template-"))
    at_exit { FileUtils.remove_entry(tempdir) }
    git(clone: [
      "--quiet",
      "https://github.com/maful/upperbracket.git",
      tempdir,
    ].map(&:shellescape).join(" "))

    if (branch = __FILE__[%r{upperbracket-template/(.+)/template.rb}, 1])
      Dir.chdir(tempdir) { git(checkout: branch) }
    end
  else
    source_paths.unshift(File.dirname(__FILE__))
  end
end

def assert_minimum_rails_version
  requirement = Gem::Requirement.new(RAILS_REQUIREMENT)
  rails_version = Gem::Version.new(Rails::VERSION::STRING)
  return if requirement.satisfied_by?(rails_version)

  prompt = "This template requires Rails #{RAILS_REQUIREMENT}. "\
    "You are using #{rails_version}. Continue anyway?"
  exit(1) if no?(prompt)
end

def add_gems
  gem("strong_migrations", "~> 1.6")
  gem("dotenv-rails", "~> 2.8")
  gem("vite_rails", "~> 3.0")
  gem("aasm", "~> 5.5")
  gem("simple_form", "~> 5.2")
  gem("discard", "~> 1.3")
  gem("local_time", "~> 2.1")
  gem("sidekiq", "~> 7.1") if @install_sidekiq
  gem("sidekiq-cron", "~> 1.10") if @install_sidekiq && @install_sidekiq_cron
  gem("pagy", "~> 6.0")
  gem("draper", "~> 4.0")
  gem("inline_svg", "~> 1.9")
  gem("rodauth-rails", "~> 1.11")
  gem("argon2", "~> 2.3")
  gem("phosphor_icons", "~> 0.2") if @install_phosphor_icons

  gem_group(:development, :test) do
    gem("pry", "~> 0.14.2")
  end

  gem_group(:rubocop) do
    gem("rubocop", "~> 1.55", require: false)
    gem("rubocop-rails", "~> 2.20", require: false)
    gem("rubocop-shopify", "~> 2.14", require: false)
  end
end

def setup_rubocop
  copy_file("template/.rubocop.yml", ".rubocop.yml")
end

def setup_vite
  run("bundle exec vite install")
  run("yarn remove vite-plugin-ruby")
  run("yarn add -D vite-plugin-rails typescript")
  run("yarn add stimulus-vite-helpers")
  copy_file("template/vite.config.ts", "vite.config.ts", force: true)
  copy_file("template/tsconfig.json", "tsconfig.json", force: true)
  copy_file("template/app/javascript/controllers/index.js", "app/javascript/controllers/index.js", force: true)
  copy_file(
    "template/app/javascript/entrypoints/application.css",
    "app/javascript/entrypoints/application.css",
    force: true,
  )
  copy_file(
    "template/app/javascript/entrypoints/application.js",
    "app/javascript/entrypoints/application.js",
    force: true,
  )

  applicationcss_content = <<-HTML
    <%= vite_stylesheet_tag "application.css" %>
  HTML
  insert_into_file(
    "app/views/layouts/application.html.erb",
    "\n#{applicationcss_content}",
    after: "<%= vite_client_tag %>",
  )
end

def remove_importmap
  run("bundle remove importmap-rails")
  remove_file("config/importmap.rb")
  remove_file("app/javascript/application.js")
  remove_file("bin/importmap")
  gsub_file("app/views/layouts/application.html.erb", /<%= javascript_importmap_tags %>.*\n/, "")
  gsub_file(
    "app/views/layouts/application.html.erb",
    /<%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>.*\n/,
    "",
  )
end

def setup_strong_migrations
  generate("strong_migrations:install")
end

def setup_hotwired
  run("yarn add @hotwired/stimulus @hotwired/turbo-rails")
end

def setup_simple_form
  generate("simple_form:install")
  copy_file("template/config/initializers/simple_form.rb", "config/initializers/simple_form.rb", force: true)
end

def setup_local_time
  run("yarn add local-time")
end

def setup_sidekiq
  copy_file("template/config/sidekiq.yml", "config/sidekiq.yml")
  initializer("sidekiq.rb", <<~CODE
    # frozen_string_literal: true

    Sidekiq.configure_server do |config|
      config.redis = { url: ENV["REDIS_URL"], network_timeout: 5, pool_timeout: 5 }
    end

    Sidekiq.configure_client do |config|
      config.redis = { url: ENV["REDIS_URL"], network_timeout: 5, pool_timeout: 5 }
    end
  CODE
  )
  environment(%(config.active_job.queue_adapter = :sidekiq))
  create_file("config/schedule.yml") if @install_sidekiq_cron
end

def setup_pagy
  copy_file("template/config/initializers/pagy.rb", "config/initializers/pagy.rb")
end

def setup_draper
  generate("draper:install")
end

def setup_inline_svg
  copy_file("template/lib/inline_svg/vite_asset_finder.rb", "lib/inline_svg/vite_asset_finder.rb")
  initializer("inline_svg.rb", <<-CODE
  # frozen_string_literal: true

  require Rails.root.join("lib/inline_svg/vite_asset_finder")

  InlineSvg.configure do |config|
    config.asset_finder = InlineSvg::ViteAssetFinder
  end
  CODE
  )
end

def setup_tailwindcss
  run("yarn add -D tailwindcss postcss autoprefixer postcss-nested @tailwindcss/forms")
  copy_file("template/tailwind.config.js", "tailwind.config.js")
  copy_file("template/postcss.config.js", "postcss.config.js")

  content = <<~CODE
    @import url("https://fonts.googleapis.com/css2?family=Figtree:ital,wght@0,300;0,400;0,500;0,600;0,700;0,800;0,900;1,300;1,400;1,500;1,600;1,700;1,800;1,900&display=swap");

    @import "tailwindcss/base";
    @import "tailwindcss/components";
    @import "tailwindcss/utilities";
  CODE
  append_to_file("app/javascript/entrypoints/application.css", content, verbose: false)
end

def setup_prettier
  run("yarn add -D prettier prettier-plugin-tailwindcss")
  copy_file("template/.prettierrc.json", ".prettierrc.json")
end

def setup_rodauth
  environment('config.action_mailer.default_url_options = { host: "localhost", port: 3000 }', env: "development")
  generate("rodauth:install", "--argon2")
  insert_into_file("app/misc/rodauth_main.rb", after: /# argon2_secret .*$\n/, force: true) do
    %(    argon2_secret Rails.application.credentials.argon2_secret\n)
  end
end

def setup_dev
  copy_file("template/bin/dev", "bin/dev")
  copy_file("template/Procfile.dev", "Procfile.dev", force: true)
  if @install_sidekiq
    append_to_file("Procfile.dev", "worker: bundle exec sidekiq -C config/sidekiq.yml\n")
  end
  chmod("bin/dev", "+x")
  rails_command("turbo:install:redis")
  copy_file("template/.env.local", ".env.local", force: true)
  create_file(".env.test.local")
  copy_file("template/config/cable.yml", "config/cable.yml", force: true)
  environment do
    %(config.app_generators do |g|
  g.helper(false)
  g.decorator(false)
end)
  end
  copy_file("template/settings.json", ".vscode/settings.json")
end

def create_initial_page
  generate(:controller, "Home", "index")
  route("root to: \"home#index\"")
end

def preexisting_git_repo?
  @preexisting_git_repo ||= (File.exist?(".git") || :nope)
  @preexisting_git_repo == true
end

# Setup
assert_minimum_rails_version

say
@install_sidekiq = yes?("Install and Configure Sidekiq?")
if @install_sidekiq
  @install_sidekiq_cron = yes?("Do you need Sidekiq Cron?")
end
@install_phosphor_icons = yes?("Install Phosphor Icons?")
say

add_template_repository_to_source_path
add_gems

after_bundle do
  # Add platform x86_64-linux
  run "bundle lock --add-platform x86_64-linux"

  remove_importmap
  setup_hotwired
  setup_rubocop
  setup_strong_migrations
  setup_vite
  setup_simple_form
  setup_local_time
  setup_sidekiq if @install_sidekiq
  setup_pagy
  setup_draper
  setup_inline_svg
  setup_tailwindcss
  setup_prettier
  setup_rodauth
  create_initial_page
  setup_dev

  # Git
  git :init unless preexisting_git_repo?
  git add: "."
  git commit: "-a -m 'Initial commit'"

  say
  say "UpperBracket template successfully configured!", :green
  say
  say "To complete the installation, add argon2_secret to the credentials."
  say
  say "If you love UpperBracket, please give us star on GitHub"
  say "https://github.com/maful/upperbracket"
end
