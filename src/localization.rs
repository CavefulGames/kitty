use rust_i18n::t;
use sys_locale::get_locale;
use language_tags::LanguageTag;
use std::borrow::Cow;

pub fn get_text(key: &str) -> Cow<str> {
	let locale = get_locale().unwrap();
	let tag = LanguageTag::parse(&locale).unwrap();
	rust_i18n::set_locale(tag.primary_language());
	t!(key)
}
