require 'i18n'

I18n.config.enforce_available_locales = true unless I18n.config.enforce_available_locales == false

Dir.glob(File.expand_path("../locale/*.yml", __FILE__)).each do |locale_file|
  I18n.load_path << locale_file
end
