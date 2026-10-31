require "test_helper"

# Every English text needs its Korean one, and the other way round
class I18nTest < ActiveSupport::TestCase
  def flat_keys(hash, prefix = nil)
    hash.flat_map do |key, value|
      path = [prefix, key].compact.join(".")
      value.is_a?(Hash) && !(value.keys - %w[one other zero]).empty? ? flat_keys(value, path) : [path]
    end
  end

  test "en.yml and ko.yml have the same keys" do
    en = flat_keys(YAML.load_file(Rails.root.join("config/locales/en.yml"))["en"])
    ko = flat_keys(YAML.load_file(Rails.root.join("config/locales/ko.yml"))["ko"])
    assert_empty en - ko, "missing in ko.yml"
    assert_empty ko - en, "missing in en.yml"
  end
end
