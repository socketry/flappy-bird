# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

pin "morphdom" # @2.7.2
pin "@socketry/live", to: "https://ga.jspm.io/npm:@socketry/live@0.6.0/Live.js"
pin "live"
