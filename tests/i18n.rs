use rust_i18n::t;
use sys_locale::get_locale;
use language_tags::LanguageTag;

rust_i18n::i18n!("locales");

#[test]
fn test_i18n() {
	let locale = get_locale().unwrap();
	let tag = LanguageTag::parse(&locale).unwrap();
	println!("locale: {} tag: {}",locale,tag.primary_language());
	rust_i18n::set_locale(tag.primary_language());
    println!("{}",t!("orange"));
}
