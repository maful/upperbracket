# frozen_string_literal: true

def add_gems
  gem("strong_migrations", "~> 1.6")
  gem("dotenv-rails", "~> 2.8")
  gem("vite_rails", "~> 3.0")
  gem("aasm", "~> 5.5")
  gem("simple_form", "~> 5.2")
  gem("discard", "~> 1.3")
  gem("local_time", "~> 2.1")
  gem("sidekiq", "~> 7.1")
  gem("pagy", "~> 6.0")
  gem("draper", "~> 4.0")

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
end

def setup_pagy
  copy_file("template/config/initializers/pagy.rb", "config/initializers/pagy.rb")
end

def setup_draper
  generate("draper:install")
end

def setup_dev
  copy_file("template/bin/dev", "bin/dev")
  copy_file("template/Procfile.dev", "Procfile.dev", force: true)
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
end

def create_initial_page
  generate(:controller, "Home", "index")
  route("root to: \"home#index\"")
end

def preexisting_git_repo?
  @preexisting_git_repo ||= (File.exist?(".git") || :nope)
  @preexisting_git_repo == true
end

def source_paths
  [__dir__]
end

# Setup
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
  setup_sidekiq
  setup_pagy
  setup_draper
  create_initial_page
  setup_dev

  # Git
  git :init unless preexisting_git_repo?
  git add: "."
  git commit: "-a -m 'Initial commit'"
end

say
say "Upperbracket template successfully configured!", :green
say
